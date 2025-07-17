import SwiftUI
import Mantis

struct ImageCropper: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented : Bool
    var onCropped: (UIImage) -> Void  // Closure to return the cropped image

    func makeUIViewController(context: Context) -> Mantis.CropViewController {
        let config = Mantis.Config()
        // Customize config as needed (e.g., aspectRatio, cropShape)
        let cropViewController = Mantis.cropViewController(image: image!, config: config)
        cropViewController.delegate = context.coordinator
        return cropViewController
    }

    func updateUIViewController(_ uiViewController: Mantis.CropViewController, context: Context) {
        // Update the view controller if needed (e.g., image changes)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, Mantis.CropViewControllerDelegate {
        var parent: ImageCropper

        init(_ parent: ImageCropper) {
            self.parent = parent
        }

        func cropViewControllerDidCrop(_ cropViewController: Mantis.CropViewController, cropped: UIImage, transformation: Mantis.Transformation, cropInfo: Mantis.CropInfo) {
            // Pass the cropped image back via the closure
            parent.onCropped(cropped)
            parent.isPresented = false
        }

        func cropViewControllerDidCancel(_ cropViewController: Mantis.CropViewController, original: UIImage) {
            // Handle cancellation if needed
            parent.isPresented = false
        }
    }
}
