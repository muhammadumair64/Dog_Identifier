import UIKit
import MLKitObjectDetection
import MLKitVision

class ObjectDetectionHelper {

    /// Detect objects in an image and draw edge frames on them.
    /// - Parameters:
    ///   - image: The input UIImage.
    ///   - completion: Completion handler with the framed image or an error.
    func detectAndDrawFrames(in image: UIImage, completion: @escaping (UIImage?, Error?) -> Void) {
        guard image.cgImage != nil else {
            completion(nil, NSError(domain: "ObjectDetection", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid image"]))
            return
        }
        
        // Convert UIImage to VisionImage
        let visionImage = VisionImage(image: image)
        visionImage.orientation = image.imageOrientation
        
        // Configure Object Detection Options
        let options = ObjectDetectorOptions()
        options.detectorMode = .singleImage
        options.shouldEnableMultipleObjects = true
        options.shouldEnableClassification = true
        
        // Initialize Object Detector
        let objectDetector = ObjectDetector.objectDetector(options: options)
        
        // Process the image
        objectDetector.process(visionImage) { detectedObjects, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            // Collect all detected labels and find the first bounding box
            var detectedLabels: [String] = []
            var boundingBox: CGRect? = nil
            if let objects = detectedObjects, !objects.isEmpty {
                // Loop through detected objects to find insect
                for object in objects {
                    let labels = object.labels.map { $0.text.lowercased() }
                    if labels.contains("insect") {
                        boundingBox = object.frame
                        detectedLabels = labels
                        break
                    }
                }
            }
            
            // If no insect is found, append "unknown"
            if detectedLabels.isEmpty {
                detectedLabels.append("unknown")
            }
            
            print("Detected Labels: \(detectedLabels)")
            
            // Draw edge frames on detected objects, if insect detected
            if let boundingBox = boundingBox {
                let framedImage = self.drawEdgeFrames(on: image, for: boundingBox)
                completion(framedImage, nil)
            } else {
                // No insect detected, return the original image
                completion(image, nil)
            }
        }
    }

    /// Draw only edge frames (corners) on detected objects in the image.
    /// - Parameters:
    ///   - image: The input UIImage.
    ///   - boundingBox: The bounding box for the detected insect.
    /// - Returns: A new UIImage with edge frames drawn.
    private func drawEdgeFrames(on image: UIImage, for boundingBox: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            // Draw the original image
            image.draw(at: .zero)
            
            // Get the context to draw frames
            let cgContext = context.cgContext
            cgContext.setStrokeColor(UIColor.red.cgColor) // Red color for edges
            cgContext.setLineWidth(4) // Frame line thickness
            
            // Scale bounding box to match the image size
            let scaledBox = CGRect(
                x: boundingBox.origin.x * image.scale,
                y: boundingBox.origin.y * image.scale,
                width: boundingBox.width * image.scale,
                height: boundingBox.height * image.scale
            )
            
            // Draw only the corners of the bounding box
            let cornerLength: CGFloat = min(scaledBox.width, scaledBox.height) * 0.2
            
            // Top-left corner
            cgContext.move(to: scaledBox.origin)
            cgContext.addLine(to: CGPoint(x: scaledBox.origin.x + cornerLength, y: scaledBox.origin.y))
            cgContext.move(to: scaledBox.origin)
            cgContext.addLine(to: CGPoint(x: scaledBox.origin.x, y: scaledBox.origin.y + cornerLength))
            
            // Top-right corner
            cgContext.move(to: CGPoint(x: scaledBox.maxX, y: scaledBox.origin.y))
            cgContext.addLine(to: CGPoint(x: scaledBox.maxX - cornerLength, y: scaledBox.origin.y))
            cgContext.move(to: CGPoint(x: scaledBox.maxX, y: scaledBox.origin.y))
            cgContext.addLine(to: CGPoint(x: scaledBox.maxX, y: scaledBox.origin.y + cornerLength))
            
            // Bottom-left corner
            cgContext.move(to: CGPoint(x: scaledBox.origin.x, y: scaledBox.maxY))
            cgContext.addLine(to: CGPoint(x: scaledBox.origin.x + cornerLength, y: scaledBox.maxY))
            cgContext.move(to: CGPoint(x: scaledBox.origin.x, y: scaledBox.maxY))
            cgContext.addLine(to: CGPoint(x: scaledBox.origin.x, y: scaledBox.maxY - cornerLength))
            
            // Bottom-right corner
            cgContext.move(to: CGPoint(x: scaledBox.maxX, y: scaledBox.maxY))
            cgContext.addLine(to: CGPoint(x: scaledBox.maxX - cornerLength, y: scaledBox.maxY))
            cgContext.move(to: CGPoint(x: scaledBox.maxX, y: scaledBox.maxY))
            cgContext.addLine(to: CGPoint(x: scaledBox.maxX, y: scaledBox.maxY - cornerLength))
            
            cgContext.strokePath() // Render the frame paths
        }
    }
}
