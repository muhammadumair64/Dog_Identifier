//
//  CameraScreen.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 18/12/2024.
//

import AVFoundation
import Foundation
import SwiftUI

struct CameraScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var cameraViewModel: CameraViewModel
    @StateObject private var cameraModel = CameraModel()
    @State private var isImageCaptured = false
    @State var isShowingTipsView = false
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented = false

    @State var isShowCamera = false
    @State var refreshCamera = false

    var body: some View {

        ZStack(alignment: .bottom) {
            // Camera preview
            ZStack {
                if refreshCamera {
                    if isShowCamera {
                        CameraPreview(cameraManager: cameraModel)
                            .ignoresSafeArea()
                          
                    }
                }

                // CameraFrame is shown above but does not block touches
                CameraFrame()
                    .allowsHitTesting(false) // ✅ disables touch interaction
            }


            CameraPreviewLayout(
                navigationManager: navigationManager,
                isImageCaptured: $isImageCaptured, cameraModel: cameraModel,
                cameraViewModel: cameraViewModel)

            Image(ImageResource.cameraOverlay)
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: 150)

            TopCameraControl(
                navigationManager: navigationManager,
                cameraViewModel: cameraViewModel,
                isImageCaptured: $isImageCaptured, cameraModel: cameraModel)
            BottomCameraControl(
                isImageCaptured: $isImageCaptured,
                selectedImage: $selectedImage, cameraModel: cameraModel,
                isShowingTipsView: $isShowingTipsView,
                isImagePickerPresented: $isImagePickerPresented)
        }
        .onAppear {

            checkCameraAvailablity()

            refreshCamera = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                refreshCamera = true
            }
            cameraViewModel.capturedImage = nil
            cameraViewModel.croppedImage = nil
        }
        .blur(radius: isShowingTipsView ? 40 : 0)
        .onDisappear {
            cameraModel.stopSession()
        }
        .onChange(of: cameraModel.showAlert) { newValue in
            AlertManager.shared.showAlert(
                title: "Camera Error",
                message: cameraModel.alertMessage,
                primaryButtonTitle: "Open Settings",
                primaryAction: {
                    cameraModel.openSettings()
                },
                showSecondaryButton: false  // Show the second button
            )
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(
                selectedImage: $selectedImage, sourceType: .photoLibrary
            ).padding(.bottom, -10)
        }
        .onChange(of: selectedImage) { newValue in
            cameraViewModel.capturedImage = selectedImage
            navigationManager.push(.scanningScreen)
        }

//        if isShowingTipsView {
//            SnapTipDialogue(isShowingTipsView: $isShowingTipsView)
//        }
    }

    func checkCameraAvailablity(){
        #if targetEnvironment(simulator)
            AlertManager.shared.showAlert(
                title: "Simulator Detected",
                message: "Please use a real device for camera functionality.",
                primaryButtonTitle: "OK",
                primaryAction: {
                    navigationManager.pop()
                },
                showSecondaryButton: false
            )
        #else
        if UIDevice.current.userInterfaceIdiom == .pad {
                AlertManager.shared.showAlert(
                    title: "iPad Camera Not Supported",
                    message: "This app is optimized for iPhone Camera. Camera functionality may not work properly on iPads. Use Gallery Images",
                    primaryButtonTitle: "OK",
                    primaryAction: {
                        navigationManager.pop()
                    },
                    showSecondaryButton: false
                )
            } else {
                isShowCamera = true
                cameraModel.checkCameraAuthorization()
            }
        #endif
    }

}

#Preview {
    CameraScreen(
        navigationManager: NavigationManager(),
        cameraViewModel: CameraViewModel())
}

struct TopCameraControl: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var cameraViewModel: CameraViewModel
    @Binding var isImageCaptured: Bool
    @ObservedObject var cameraModel: CameraModel

    var body: some View {
        VStack {
            HStack {
                Image(ImageResource.close)
                    .resizable()
                    .frame(maxWidth: 40, maxHeight: 40)
                    .onTapGesture {
                        cameraViewModel.isFlashOn = false
                        navigationManager.pop()
                        cameraModel.stopSession()
                    }

                Spacer()

                Image(
                    cameraViewModel.isFlashOn
                        ? ImageResource.flashOn : ImageResource.flash
                )
                .resizable()
                .frame(maxWidth: 40, maxHeight: 40)
                .onTapGesture {
                    cameraViewModel.isFlashOn.toggle()
                    cameraViewModel.toggleFlashlight()
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
            .zIndex(10)
            Spacer()

        }

    }
}

struct BottomCameraControl: View {

    @Binding var isImageCaptured: Bool
    @Binding var selectedImage: UIImage?
    @ObservedObject var cameraModel: CameraModel
    @Binding var isShowingTipsView: Bool

    @Binding var isImagePickerPresented: Bool

    var body: some View {
        HStack {

            Spacer()
            HStack{}.frame(width: 100, height: 100)
//            FeatureView(image: ImageResource.tips, txt: "Snap Tips")
//                .onTapGesture {
//                    isShowingTipsView = true
//                }
            Spacer()
            // Capture button
            Button(action: {
                cameraModel.capturePhoto()
                isImageCaptured = true
            }) {
                Image(ImageResource.cameraBtn)
                    .resizable()
                    .frame(width: 80, height: 80)
            }
            .padding(.bottom, 20)
            .padding(.horizontal, 40)

            Spacer()
            FeatureView(image: ImageResource.imageIc, txt: "Photos")
                .onTapGesture {
                    isImagePickerPresented = true
                }
            Spacer()

        }
        .padding(.bottom, 20)
        .zIndex(10)

    }
}

struct CameraFrame: View {
    var body: some View {
        VStack {

            Spacer()

            Image(ImageResource.cameraFrame)
                .resizable()
                .frame(maxWidth: 240, maxHeight: 240)

            Spacer()

        }
    }
}

struct CameraPreviewLayout: View {
    @ObservedObject var navigationManager: NavigationManager
    @Binding var isImageCaptured: Bool
    @ObservedObject var cameraModel: CameraModel
    @ObservedObject var cameraViewModel: CameraViewModel

    var body: some View {
        VStack {
            Spacer()

            if let capturedImage = cameraModel.capturedImage, isImageCaptured {

                // Display the captured image
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            cameraViewModel.capturedImage = capturedImage
                           navigationManager.push(.scanningScreen)
                        }
                    }

            }

            Spacer()

        }
    }
}

struct FeatureView: View {
    var image: ImageResource
    var txt: String
    var body: some View {
        VStack {
            Image(image)
                .resizable()
                .frame(maxWidth: 40, maxHeight: 40)

            Text(txt)
                .font(.custom(FontHelper.bold.rawValue, size: 15))
                .foregroundColor(Color.white)

        }.frame(width: 100, height: 100)

    }
}
