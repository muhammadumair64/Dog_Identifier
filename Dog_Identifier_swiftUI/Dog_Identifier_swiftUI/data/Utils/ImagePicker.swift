import SwiftUI
import UIKit
import PhotosUI
import CocoaLumberjack

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    let sourceType: UIImagePickerController.SourceType

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        switch sourceType {
        case .camera:
            DDLogDebug("ImagePicker: Using UIImagePickerController for camera")
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = .camera
            return picker

        case .photoLibrary, .savedPhotosAlbum:
            DDLogDebug("ImagePicker: Using PHPickerViewController for photo library")
            var config = PHPickerConfiguration()
            config.selectionLimit = 1
            config.filter = .images
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker

        @unknown default:
            fatalError("Unsupported source type")
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        // For UIImagePickerController (camera)
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            DDLogInfo("UIImagePicker: didFinishPickingMediaWithInfo")
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            } else {
                DDLogWarn("UIImagePicker: No image found")
            }
            picker.dismiss(animated: true) {
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            DDLogInfo("UIImagePicker: Cancelled")
            picker.dismiss(animated: true) {
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }

        // For PHPickerViewController (library)
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            DDLogInfo("PHPicker: didFinishPicking")
            guard let itemProvider = results.first?.itemProvider else {
                DDLogWarn("PHPicker: No image provider")
                parent.presentationMode.wrappedValue.dismiss()
                return
            }

            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    DispatchQueue.main.async {
                        if let image = object as? UIImage {
                            self.parent.selectedImage = image
                        } else {
                            DDLogError("PHPicker: Failed to load image \(error?.localizedDescription ?? "")")
                        }
                        self.parent.presentationMode.wrappedValue.dismiss()
                    }
                }
            } else {
                DDLogWarn("PHPicker: Cannot load UIImage")
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
