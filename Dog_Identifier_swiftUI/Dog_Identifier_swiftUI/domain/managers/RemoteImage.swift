//
//  RemoteImage.swift
//  IosFirstApp
//
//  Created by Umair Rajput   on 15/09/2024.
//

import SwiftUI

final class ImageLoader: ObservableObject {
    @Published var image: Image? = nil
    
    func load(fromURLString urlString: String) {
        PixabayNetworkManager.shared.downloadImage(fromURLString: urlString) { uiImage in
            guard let uiImage = uiImage else { return }
            DispatchQueue.main.async {
                self.image = Image(uiImage: uiImage)
            }
        }
    }
}


struct RemoteImage: View {
    var image: Image?
    
    var body: some View {
        image?.resizable() ?? Image("").resizable()
    }
}

struct MyRemoteImage: View {
    @StateObject private var imageLoader = ImageLoader()
    let urlString: String
    
    var body: some View {
        RemoteImage(image: imageLoader.image)
            .onAppear {
                imageLoader.load(fromURLString: urlString)
            }
    }
}


