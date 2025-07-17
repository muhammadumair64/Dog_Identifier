//
//  ScanningScreen.swift
//  Insect-detector-ios
//  Created by Mac Mini on 20/12/2024.

import SwiftUI
import Lottie
import MLKitVision
import CocoaLumberjack


struct ScanningScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var cameraViewModel: CameraViewModel
    @State private var isImageCroppingPresented: Bool = false
    @State private var progress: Double = 0.2
     @State var showProgerss  = true
    @State var isMoveNextCallSend =  false
    @StateObject private var adsManager = AdsManager.shared
    
    private let totalDuration: Double = 15.0

    
    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                GeometryReader { geometry in
                    VStack {
                        // Background Image or Cropped Image
                        if let croppedImage = cameraViewModel.croppedImage {
                            ProgressImageOverlay(progress: $progress, imageName: croppedImage)
                        } else if let capturedImage = cameraViewModel.capturedImage {
                            ProgressImageOverlay(progress: $progress, imageName: capturedImage)
                        } else {
                            Color.clear // Placeholder if image is unavailable
                                .onAppear {
                                    cameraViewModel.showAlert = true // Trigger alert
                                    cameraViewModel.cancelTask()
                                }
                        }

                        Spacer()
                    }
                }
                .ignoresSafeArea()

                // Top HStack for Back Button
                HStack {
                    Image(ImageResource.backBtn)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .onTapGesture {
                            cameraViewModel.cancelTask()
                            navigationManager.pop()
                        }

                    Spacer()
                }
                .padding([.leading, .top], 20)
            }
            

            CustomProgressBar(progress: $progress, thumbImage: "progressThumb")
                .disabled(true)
                .padding([.top, .horizontal], 30)

            HStack {
                Text("Identifying... ")
                    .font(Font.custom(FontHelper.medium.rawValue, size: 20))

                Text("\(Int(progress * 100))%")
                    .font(Font.custom(FontHelper.medium.rawValue, size: 20))
                    .foregroundColor(ColorHelper.primary.color)
            }

            
//            VStack{
//                
//               // NativeAdView(adType: .withMedia)
//            }
//             .background(ColorHelper.primary.color.opacity(0.1))
//             .cornerRadius(20)
//            
//            LottieView(animation: .named("dog"))
//                .playing()
//                .looping()
//                .frame(height: 150)
//                .padding(.top, 50)
            
            AdSectionView(
                adUnitID: AdUnit.nativeMedia.unitId, // <-- your ad unit ID
                layout: .medium,
                  rootViewController: UIApplication.shared.rootVC
              )
              .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            startProgressAnimation()
            cropImageLogic()
        
          //  drawFrameLogic()
        }
        .sheet(isPresented: $isImageCroppingPresented) {
            ImageCropper(image:  $cameraViewModel.capturedImage , isPresented: $isImageCroppingPresented) { croppedImage in
                cropperPostExecution(croppedImage: croppedImage)
                   }
                   .edgesIgnoringSafeArea(.all)
               }
        .onChange(of: cameraViewModel.showAlert){ newValue in
            if newValue {
                self.showProgerss = false
                AlertManager.shared.showAlert(
                                   title: "Scanning Error",
                                   message: "Unable to scan Dog in photo please try again.",
                                   primaryButtonTitle: "Retry",
                                   primaryAction: {
                                       navigationManager.pop()
                                       cameraViewModel.cancelTask()
                                       self.cameraViewModel.showAlert =  false
                                   },
                                   showSecondaryButton: false // Show the second button
                               )
            }

        }
        .overlay(
           //  Show the loading dialog when ads are loading
            adsManager.isLoading ? LoadingDialogView() : nil
        )
    }
    
    func cropperPostExecution(croppedImage: UIImage){
        cameraViewModel.croppedImage = croppedImage
        progress = 0
        startProgressAnimation()
        let objectDetectionHelper = ObjectCropHelper()
        objectDetectionHelper.labelImageForCropper(croppedImage) { isDog, error in
            if(isDog){
                DDLogDebug("DOG FIND")
                cameraViewModel.capturedImage = nil
                cameraViewModel.generateResponse(with: croppedImage)
            }else{
                DDLogDebug("DOG NOT FIND")
                cameraViewModel.cancelTask()
                self.cameraViewModel.showAlert =  true
            }
        }
    }
    
    
    // Function to start the progress animation
    private func startProgressAnimation() {
          Timer.scheduledTimer(withTimeInterval: totalDuration / 100, repeats: true) { timer in
              withAnimation(.linear(duration: totalDuration / 100)) {
                  if showProgerss {
                      if !cameraViewModel.responseReceived {
                          progress += 0.01 // Progress up to 80% while waiting for response
                          if progress >= 0.8 {
                              progress = 0.8
                          }
                      }
                      else {
                          progress += 0.01 // After response is received, progress to 100%
                          if progress >= 1.0 {
                              progress = 1.0
                              timer.invalidate()
                              if(cameraViewModel.task != nil){
                                  if(!isMoveNextCallSend){
                                      isMoveNextCallSend = true
                                      DDLogDebug("Before sending inter req")
                                               navigationManager.pop()
                                               navigationManager.push(.scanResultsScreen)
//                                      adsManager.interAdCallForScreen {
//                                          navigationManager.pop()
//                                          navigationManager.push(.scanResultsScreen)
//                                      }
                                  }
                        
                              }
                              print("LAST_LINE_POP")
                          }
                      }
                  }
              }
          }
      }

    // Function to handle image cropping
    private func cropImageLogic() {
        guard let inputImage = cameraViewModel.capturedImage else {
            print("No captured image available")
            return
        }

        let objectDetectionHelper = ObjectCropHelper()
        
        objectDetectionHelper.detectAndClassifyObjects(in: inputImage) { classifiedImages, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Object detection or classification error: \(error.localizedDescription)")
                    cameraViewModel.cancelTask()
                    self.cameraViewModel.showAlert = true
                    return
                }

                guard let classifiedImages = classifiedImages, !classifiedImages.isEmpty else {
                    print("No objects detected or classified")
                    cameraViewModel.cancelTask()
                    //self.cameraViewModel.alertItem = AlertContext.unableToScan
                    isImageCroppingPresented = true
                    return
                }

                // Process the results
                let insectImages = classifiedImages.filter { $0.value == "Dog" }

                if let firstInsectImage = insectImages.first?.key {
                    // Set the first detected insect image for further processing
                    self.cameraViewModel.croppedImage = firstInsectImage
                    self.cameraViewModel.capturedImage = nil
                    self.cameraViewModel.generateResponse(with: firstInsectImage)
                } else {
                    // Handle case when no insects are detected
                    print("No insects detected in the image")
                    cameraViewModel.cancelTask()
//                    self.cameraViewModel.alertItem = AlertContext.unableToScan
                    isImageCroppingPresented = true
                }
            }
        }
    }

    
    private func drawFrameLogic() {
        guard let inputImage = cameraViewModel.capturedImage else {
            print("No captured image available")
            return
        }

        // Create an instance of the object detection helper
        let objectDetectionHelper = ObjectDetectionHelper()
        
        // Call the method to detect and label the image, then draw bounding box for detected insect
        objectDetectionHelper.detectAndDrawFrames(in: inputImage) { framedImage, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Object detection error: \(error.localizedDescription)")
                    // Handle the error, e.g., show an alert
                    cameraViewModel.showAlert = true
                } else if let framedImage = framedImage {
                    // Display the image with frames drawn around the detected insect
                    self.cameraViewModel.croppedImage = framedImage
                    cameraViewModel.capturedImage = nil
                } else {
                    print("No insect detected")
                    // You can handle the case when no insect is detected, for example:
                    // self.showAlert = true
                }
            }
        }
    }
    
    // ProgressImageOverlay (unchanged for default background use)
    struct ProgressImageOverlay: View {
        @Binding var progress: Double
        let imageName: UIImage

        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Image(uiImage: imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width)
                        .clipped()

                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: geometry.size.width * CGFloat(1 - progress))
                        .offset(x: geometry.size.width * CGFloat(progress))
                }.frame(height: UIScreen.main.bounds.height * 0.4)
            }
        }
    }
    
}





#Preview {
    ScanningScreen(navigationManager: NavigationManager(), cameraViewModel: CameraViewModel())
}
