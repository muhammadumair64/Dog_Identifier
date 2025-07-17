import SwiftUI
import UIKit

struct DialogPicker: View {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Background dimming effect
            if isPresented {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        isPresented = false  // Dismiss when tapping outside
                    }
            }

            ZStack {
                VStack {

                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .cornerRadius(16)
                .padding(.top, 35)

                VStack {
                    // Question Icon
                    Image(ImageResource.question)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(ColorHelper.primary.color)

                    // Title
                    Text("Select how do you want to proceed")
                        .font(
                            Font.custom(FontHelper.regular.rawValue, size: 16)
                        )
                        .padding(.top, 8)
                        .multilineTextAlignment(.center)

                    // Horizontal Button Stack
                    HStack(spacing: 16) {
                        // Manual Crop Button
                        Button(action: {
                            #if targetEnvironment(simulator)
                                AlertManager.shared.showAlert(
                                    title: "Simulator Detected",
                                    message:
                                        "Please use a real device for camera functionality.",
                                    primaryButtonTitle: "OK",
                                    primaryAction: {
                                        isPresented = false
                                    },
                                    showSecondaryButton: false
                                )
                            #else
                                self.openImagePicker(sourceType: .camera)
                            #endif
                        }) {
                            HStack {
                                Text("Camera")
                                    .font(
                                        Font.custom(
                                            FontHelper.bold.rawValue, size: 18)
                                    )
                                    .foregroundColor(ColorHelper.primary.color)

                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        ColorHelper.primary.color, lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }

                        // Auto Crop Button
                        Button(action: {
#if targetEnvironment(simulator)
    AlertManager.shared.showAlert(
        title: "Simulator Detected",
        message:
            "Scanning is only available for Real Device",
        primaryButtonTitle: "OK",
        primaryAction: {
            isPresented = false
        },
        showSecondaryButton: false
    )
#else
                            self.openImagePicker(sourceType: .photoLibrary)
#endif
                            
                            
                      
                        }) {
                            HStack {
                                Text("Gallery")
                                    .font(
                                        Font.custom(
                                            FontHelper.bold.rawValue, size: 18)
                                    )
                                    .foregroundColor(Color.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(ColorHelper.primary.color)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    Spacer()
                }

            }
            .frame(maxWidth: 300, maxHeight: 200)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .opacity(isPresented ? 1 : 0)
            .scaleEffect(isPresented ? 1 : 0.9)
            .animation(.easeInOut, value: isPresented)
        }
        .edgesIgnoringSafeArea(.all)
    }

    private func openImagePicker(sourceType: UIImagePickerController.SourceType)
    {
        isPresented = false  // Close dialog before opening image picker
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIApplication.shared.windows.first?.rootViewController?.present(
                UIHostingController(
                    rootView: ImagePickerWrapper(
                        selectedImage: $selectedImage, sourceType: sourceType)),
                animated: true,
                completion: nil
            )
        }
    }
}

// Wrapper to integrate ImagePicker into the Dialog
struct ImagePickerWrapper: View {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType
   // @State private var source: ImagePickerSource = .photoLibrary
    var body: some View {
        ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
            .edgesIgnoringSafeArea(.all)
    }
}

// Preview
struct DialogPicker_Previews: PreviewProvider {
    @State static var selectedImage: UIImage? = nil
    @State static var isPresented: Bool = true

    static var previews: some View {
        DialogPicker(selectedImage: $selectedImage, isPresented: $isPresented)
    }
}

