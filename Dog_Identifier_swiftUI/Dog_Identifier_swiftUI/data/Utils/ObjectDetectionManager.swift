
import UIKit
import MLKitObjectDetection
import MLKitVision
import MLKitImageLabeling


class ObjectCropHelper {
    /// Detect objects in an image, crop the detected area, and classify the cropped image.
    /// - Parameters:
    ///   - image: The input UIImage.
    ///   - completion: Completion handler with a dictionary of cropped images and their labels or an error.
    func detectAndClassifyObjects(in image: UIImage, completion: @escaping ([UIImage: String]?, Error?) -> Void) {
        guard image.cgImage != nil else {
            completion(nil, NSError(domain: "ObjectDetection", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid image"]))
            return
        }
        
        // Convert UIImage to VisionImage
        let visionImage = VisionImage(image: image)
        visionImage.orientation = image.imageOrientation
        
        // Configure Object Detection Options
        let options = ObjectDetectorOptions()
        options.detectorMode = .singleImage // For static images
        options.shouldEnableMultipleObjects = true
        options.shouldEnableClassification = true
        
        // Initialize Object Detector
        let objectDetector = ObjectDetector.objectDetector(options: options)
        
        // Process the image for object detection
        objectDetector.process(visionImage) { detectedObjects, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let detectedObjects = detectedObjects, !detectedObjects.isEmpty else {
                completion([:], nil) // No objects detected
                return
            }
            
            var croppedImages: [UIImage: String] = [:]
            let dispatchGroup = DispatchGroup() // To handle multiple async tasks
            
            for detectedObject in detectedObjects {
                let boundingBox = detectedObject.frame
                
                // Crop the image using the bounding box
                if let croppedImage = self.cropImage(on: image, for: boundingBox) {
                    dispatchGroup.enter() // Track the task
                    self.labelImage(croppedImage) { label, error in
                        if let label = label {
                            croppedImages[croppedImage] = label
                        }
                        dispatchGroup.leave() // Task completed
                    }
                }
            }
            
            // Wait for all labeling tasks to complete
            dispatchGroup.notify(queue: .main) {
                completion(croppedImages, nil)
            }
        }
    }
    
    /// Label a UIImage to detect if it matches a specific category
    /// - Parameters:
    ///   - image: The input UIImage.
    ///   - completion: Completion handler with a label or an error.
     func labelImage(_ image: UIImage, completion: @escaping (String?, Error?) -> Void) {
        // Convert UIImage to VisionImage
        let visionImage = VisionImage(image: image)
        visionImage.orientation = image.imageOrientation
        
        // Configure Image Labeling Options
        let options = ImageLabelerOptions()
        options.confidenceThreshold = 0.7 // Adjust confidence threshold as needed
        
        // Initialize Image Labeler
        let labeler = ImageLabeler.imageLabeler(options: options)
        
        // Process the image for labeling
        labeler.process(visionImage) { labels, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let labels = labels, !labels.isEmpty else {
                completion("Unknown", nil) // No label detected
                return
            }
            
            // Check for a label indicating an dog
            for label in labels {
                if label.text.lowercased().contains("dog") { // Adjust logic for dog-related labels
                    completion("Dog", nil)
                    return
                }
            }
            
            // If no dog label is found, return the most confident label
            let topLabel = labels.first?.text ?? "Unknown"
            completion(topLabel, nil)
        }
    }
    


    func labelImageForCropper(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        // Convert UIImage to VisionImage
        let visionImage = VisionImage(image: image)
        visionImage.orientation = image.imageOrientation
        
        // Configure Image Labeling Options
        let options = ImageLabelerOptions()
        options.confidenceThreshold = 0.7 // Adjust confidence threshold as needed 0.7
        
        // Initialize Image Labeler
        let labeler = ImageLabeler.imageLabeler(options: options)
        
        // Process the image for labeling
        labeler.process(visionImage) { labels, error in
            if let error = error {
                completion(false, error) // Return false on error
                return
            }
            
            guard let labels = labels, !labels.isEmpty else {
                completion(false, nil) // Return false if no labels are found
                return
            }
            
            // Check for a label indicating an dog
            for label in labels {
                if label.text.lowercased().contains("dog") {
                    completion(true, nil)
                    return
                }
            }
            
    
            completion(false, nil)
        }
    }

    
    /// Crop a UIImage to a specified CGRect.
    private func cropImage(on image: UIImage, for rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let adjustedRect = CGRect(
            x: rect.origin.x * image.scale,
            y: rect.origin.y * image.scale,
            width: rect.size.width * image.scale,
            height: rect.size.height * image.scale
        )
        
        guard let croppedCGImage = cgImage.cropping(to: adjustedRect) else { return nil }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    
    func drawBoundingBox(on image: UIImage, for boundingBox: CGRect, isNormalized: Bool) -> UIImage? {
        // Debugging: Print the bounding box and image size
        print("Bounding Box: \(boundingBox)")
        print("Image size: \(image.size)")
        
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let highlightedImage = renderer.image { context in
            // Draw the original image
            image.draw(at: .zero)
            
            // Adjust bounding box for normalized or pixel-based coordinates
            let adjustedBox: CGRect
            if isNormalized {
                
                let imageWidth = image.size.width
                let imageHeight = image.size.height
                
                // Calculate the zoom area based on the bounding box
                let left = max(0, boundingBox.origin.x)
                let top = max(0, boundingBox.origin.y)
                let right = min(imageWidth, boundingBox.origin.x + boundingBox.size.width)
                let bottom = min(imageHeight, boundingBox.origin.y + boundingBox.size.height)
                
                // Adjust the bounding box coordinates based on the image scale
                adjustedBox = CGRect(
                    x: left * image.scale,
                    y: top * image.scale,
                    width: (right - left) * image.scale,
                    height: (bottom - top) * image.scale
                )
                
                
            } else {
                // If the bounding box is already in pixel coordinates, use it as is
                adjustedBox = boundingBox
            }
            
            // Debugging: Print the adjusted box
            print("Adjusted Bounding Box: \(adjustedBox)")
            
            
            // Set the dashed line pattern for the bounding box (for later use)
            let dashPattern: [CGFloat] = [6.0, 4.0] // 6 units on, 4 units off
            context.cgContext.setLineDash(phase: 0, lengths: dashPattern)
            
            // Set the border color and width
            UIColor.red.setStroke()
            context.cgContext.setLineWidth(6.0) // Border width
            context.cgContext.stroke(adjustedBox)
        }
        
        return highlightedImage
    }
}
