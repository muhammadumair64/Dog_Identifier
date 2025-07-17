import Foundation

enum NetworkError: Error, CustomStringConvertible {
    case badURL
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
    case timeoutError
    case unknown(Error)

    var description: String {
        switch self {
        case .badURL:
            return "The URL is invalid."
        case .decodingError(let error):
            return "Failed to decode the response: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "Server error (status code: \(statusCode)). \(message ?? "")"
        case .timeoutError:
            return "The request timed out."
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }
}

class NetworkingManager {
    static let shared = NetworkingManager()

    private init() {}

    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        parameters: [String: Any]? = nil,
        queryParameters: [String: String]? = nil,
        headers: [String: String]? = nil,
        timeoutInterval: TimeInterval = 60,
        decoder: JSONDecoder = JSONDecoder(),
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        guard let url = buildURL(endpoint: endpoint, queryParameters: queryParameters) else {
            completion(.failure(.badURL))
            return
        }

        var urlRequest: URLRequest
        do {
            urlRequest = try buildURLRequest(
                url: url,
                method: method,
                parameters: parameters,
                headers: headers,
                timeoutInterval: timeoutInterval
            )
            
            // Log request body and headers
            if let body = urlRequest.httpBody, let jsonString = String(data: body, encoding: .utf8) {
               // print("Request Body: \(jsonString)")
            }
            print("Request Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
        } catch {
            completion(.failure(.unknown(error)))
            return
        }

        let session = URLSession.shared
        session.dataTask(with: urlRequest) { data, response, error in
            // Log the response status code and body
            if let httpResponse = response as? HTTPURLResponse {
                print("Response Status Code: \(httpResponse.statusCode)")
            }
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
               // print("Response Body: \(responseString)")
            }

            if let error = error {
                if (error as NSError).code == NSURLErrorTimedOut {
                    completion(.failure(.timeoutError))
                } else {
                    completion(.failure(.unknown(error)))
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.unknown(NSError(domain: "Invalid response", code: 0, userInfo: nil))))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data ?? Data(), encoding: .utf8)
                completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            guard let data = data else {
                completion(.failure(.unknown(NSError(domain: "No data", code: 0, userInfo: nil))))
                return
            }

            do {
                let decodedResponse = try decoder.decode(T.self, from: data)
               // print("Decoded response: \(decodedResponse)") // For debugging
                completion(.success(decodedResponse))
            } catch {
                // Log the raw data for debugging
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("Raw response data: \(rawResponse)")
                }
                print("Decoding error: \(error.localizedDescription)")
                completion(.failure(.decodingError(error)))
            }

        }.resume()
    }

    // MARK: - Helper Methods

    private func buildURL(endpoint: String, queryParameters: [String: String]?) -> URL? {
        print("MY URL = \(ApiConfig.baseURL + endpoint)")
        guard var components = URLComponents(string: ApiConfig.baseURL + endpoint) else {
            return nil
        }

        if let queryParameters = queryParameters {
            components.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        return components.url
    }

    private func buildURLRequest(
        url: URL,
        method: String,
        parameters: [String: Any]?,
        headers: [String: String]?,
        timeoutInterval: TimeInterval
    ) throws -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.timeoutInterval = timeoutInterval

        // Add headers
        headers?.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Add body for POST/PUT
        if let parameters = parameters, method == "POST" || method == "PUT" {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return urlRequest
    }
}
