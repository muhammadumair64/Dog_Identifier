import SwiftUI
import AVFoundation
import CocoaLumberjack

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var capturedImage: UIImage? = nil
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    var session = AVCaptureSession()
    private var output = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue = DispatchQueue(label: "CameraSessionQueue")
    private var cameraPosition: AVCaptureDevice.Position = .back
    
    func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configure()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configure()
                    } else {
                        self?.showPermissionAlert(withSettingsOption: true)
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert(withSettingsOption: true)
        @unknown default:
            alertMessage = "Unknown camera authorization status."
            showAlert = true
        }
    }
    
    private func showPermissionAlert(withSettingsOption: Bool = false) {
        if withSettingsOption {
            alertMessage = """
            Camera access is required to use this feature. Please enable it in your device's settings.
            """
        } else {
            alertMessage = "Camera access is required to use this feature."
        }
        showAlert = true
    }
    
    func openSettings() {
        AdsCounter.isShowOpenAd = false

        #if os(iOS)
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }
        #elseif os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }

    
    func configure() {
        sessionQueue.async {
            self.setupSession()
            
            DispatchQueue.main.async {
                if !self.session.isRunning {
                    self.session.startRunning()
                    DDLogVerbose("Camera session started.")
                } else {
                    DDLogVerbose("Camera session already running.")
                }
            }
        }
    }

    
    func stopSession() {
        sessionQueue.async {
            self.session.stopRunning()
            DDLogVerbose("Camera session stopped.")
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()

        // Try to get dual camera, fallback to wide angle camera
        let camera: AVCaptureDevice? = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: cameraPosition)
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition)

        guard let safeCamera = camera,
              let cameraInput = try? AVCaptureDeviceInput(device: safeCamera),
              session.canAddInput(cameraInput) else {
            DispatchQueue.main.async {
                self.alertMessage = "Failed to access the camera."
                self.showAlert = true
            }
            session.commitConfiguration()
            return
        }

        // Remove existing inputs before adding new one
        for input in session.inputs {
            session.removeInput(input)
        }
        session.addInput(cameraInput)

        // Configure focus
        configureCameraFocus(camera: safeCamera)

        // Remove existing outputs before adding new one
        for output in session.outputs {
            session.removeOutput(output)
        }

        // Add output
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.isHighResolutionCaptureEnabled = false
        } else {
            DispatchQueue.main.async {
                self.alertMessage = "Failed to configure camera output."
                self.showAlert = true
            }
            session.commitConfiguration()
            return
        }

        session.commitConfiguration()
        DDLogDebug("Camera session configured successfully.")
    }


    private func configureCameraFocus(camera: AVCaptureDevice) {
        do {
            try camera.lockForConfiguration()
            
            // Set continuous autofocus mode if supported
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            } else if camera.isFocusModeSupported(.autoFocus) {
                camera.focusMode = .autoFocus
            }

            // Restrict auto-focus range to close objects
            if camera.isAutoFocusRangeRestrictionSupported {
                camera.autoFocusRangeRestriction = .near
            }
            
            // Set focus point of interest to the center of the frame
            if camera.isFocusPointOfInterestSupported {
                camera.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5) // Center of the preview
            }
            
            camera.unlockForConfiguration()
            DDLogInfo("Camera focus settings configured successfully.")
        } catch {
            DDLogError("Failed to configure camera focus settings: \(error.localizedDescription)")
        }
    }


    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = false
        output.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            DispatchQueue.main.async {
                self.alertMessage = "Failed to capture photo."
                self.showAlert = true
            }
            DDLogError("Failed to process captured photo.")
            return
        }
        
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}

// MARK: - Camera Preview View

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }

    @ObservedObject var cameraManager: CameraModel

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = cameraManager.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill

        // Add Pinch Gesture
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(pinch)

        // Add Tap Gesture
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)

        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        // no-op
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: CameraPreview
        private var lastZoomFactor: CGFloat = 1.0

        init(_ parent: CameraPreview) {
            self.parent = parent
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) else { return }

            if gesture.state == .changed || gesture.state == .ended {
                let newZoomFactor = lastZoomFactor * gesture.scale
                parent.cameraManager.setZoom(factor: newZoomFactor)
            }

            if gesture.state == .ended {
                lastZoomFactor = device.videoZoomFactor
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            if let view = gesture.view {
                parent.cameraManager.focus(at: location, in: view.bounds.size)
            }
        }
    }
}


extension CameraModel {
    
    func setZoom(factor: CGFloat) {
        sessionQueue.async {
            guard let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: self.cameraPosition) else { return }
            do {
                try device.lockForConfiguration()
                let zoomFactor = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
                device.videoZoomFactor = zoomFactor
                device.unlockForConfiguration()
                DDLogInfo("Zoom factor set to \(zoomFactor)")
            } catch {
                DDLogError("Failed to set zoom: \(error.localizedDescription)")
            }
        }
    }
    
    func focus(at point: CGPoint, in viewSize: CGSize) {
        sessionQueue.async {
            guard let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: self.cameraPosition),
                  device.isFocusPointOfInterestSupported,
                  device.isFocusModeSupported(.autoFocus) else { return }

            let focusPoint = CGPoint(x: point.x / viewSize.width, y: point.y / viewSize.height)

            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus

                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = focusPoint
                    device.exposureMode = .autoExpose
                }

                device.unlockForConfiguration()
                DDLogInfo("Focus set at point \(focusPoint)")

                // Return to continuous focus after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.returnToContinuousFocus()
                }

                // 🔁 Switch to macro lens if needed after 1.5s
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.switchToBetterLensForCloseFocusIfNeeded()
                }

            } catch {
                DDLogError("Failed to set focus: \(error.localizedDescription)")
            }
        }
    }
    func switchToBetterLensForCloseFocusIfNeeded() {
        // Example logic — replace with actual checks based on distance, focus failures, etc.
        DDLogInfo("Checking if a better lens is available for close-up focus...")

        // Example: Switch to ultraWide lens if available
        guard let ultraWide = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back),
              let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }

        if currentInput.device.deviceType != .builtInUltraWideCamera {
            session.beginConfiguration()
            session.removeInput(currentInput)

            if let newInput = try? AVCaptureDeviceInput(device: ultraWide),
               session.canAddInput(newInput) {
                session.addInput(newInput)
                cameraPosition = .back
                DDLogInfo("Switched to ultra wide camera for close focus.")
            }

            session.commitConfiguration()
        }
    }


    private func returnToContinuousFocus() {
        sessionQueue.async {
            guard let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: self.cameraPosition),
                  device.isFocusModeSupported(.continuousAutoFocus) else { return }

            do {
                try device.lockForConfiguration()
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
                DDLogInfo("Returned to continuous auto focus.")
            } catch {
                DDLogError("Failed to return to continuous focus: \(error.localizedDescription)")
            }
        }
    }

}

