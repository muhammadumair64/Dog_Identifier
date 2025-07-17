//
//  PixabayNetworkManager.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 01/01/2025.
//
import Foundation
import SwiftUI
import AVFoundation

final class PixabayNetworkManager {
    static let shared = PixabayNetworkManager()
    
    private let baseURL = "https://pixabay.com/api/"
    private let apiKey = "38250306-56379239428a9d3fcf6b4aec8" // Replace with your API key
    private let cache = NSCache<NSString, UIImage>()
    private init() {}

    // MARK: - Fetch Images from Pixabay
    func searchImages(query: String, category: String?, completed: @escaping (Result<[PixabayImage], APIError>) -> Void) {
        var endpoint = "\(baseURL)?key=\(apiKey)&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&per_page=10"
        
        if let category = category, !category.isEmpty {
            endpoint += "&category=\(category)"
        }
        
        guard let url = URL(string: endpoint) else {
            completed(.failure(.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
            if let _ = error {
                completed(.failure(.unableToComplete))
                return
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completed(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completed(.failure(.invalidData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let decodedResponse = try decoder.decode(PixabayResponse.self, from: data)
                completed(.success(decodedResponse.hits))
            } catch {
                completed(.failure(.invalidData))
            }
        }
        task.resume()
    }

    func downloadImage(fromURLString urlString: String, completed: @escaping (UIImage?) -> Void) {
        let cacheKey = urlString as String
        
        if let cachedImage = cache.object(forKey: cacheKey as NSString) {
            completed(cachedImage)
            return
        }
        
        guard let url = URL(string: urlString) else {
            completed(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { [weak self] data, response, error in
            guard let self = self, let data = data, let image = UIImage(data: data) else {
                completed(nil)
                return
            }
            
            self.cache.setObject(image, forKey: cacheKey as NSString)
            completed(image)
        }
        task.resume()
    }
}

struct PixabayResponse: Codable {
    let hits: [PixabayImage]
}

struct PixabayImage: Codable {
    let id: Int
    let pageURL: String
    let type: String
    let tags: String
    let previewURL: String
    let largeImageURL: String
}

enum APIError: String, Error {
    case invalidURL = "The URL is invalid."
    case unableToComplete = "Unable to complete your request. Please check your internet connection."
    case invalidResponse = "Invalid response from the server."
    case invalidData = "The data received from the server was invalid."
}
