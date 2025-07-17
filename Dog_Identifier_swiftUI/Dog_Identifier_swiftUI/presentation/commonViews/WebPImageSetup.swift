import SwiftUI
import SDWebImageSwiftUI
import SDWebImageWebPCoder
import CocoaLumberjack

final class WebPImageSetup {
    static func configure() {
        DDLogVerbose("Registering WebP Coder")
        
        let webPCoder = SDImageWebPCoder.shared
        SDImageCodersManager.shared.addCoder(webPCoder)

        if let cache = SDWebImageManager.shared.imageCache as? SDImageCache {
            cache.config.maxDiskAge = 7 * 24 * 60 * 60
            DDLogInfo("SDWebImage cache configured for 1 week.")
        } else {
            DDLogWarn("Failed to cast imageCache to SDImageCache")
        }
    }
}

struct WebPImageView: View {
    let imageName: String
    var placeholder: Image? = nil
    var contentMode: ContentMode = .fit
    
    var body: some View {
        if let path = Bundle.main.path(forResource: imageName, ofType: "webp") {
            let fileURL = URL(fileURLWithPath: path)
            
            WebImage(url: fileURL)
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .clipped()
        } else {
            (placeholder ?? Image(systemName: "photo"))
                .resizable()
                .aspectRatio(contentMode: contentMode)
        }
    }
}
