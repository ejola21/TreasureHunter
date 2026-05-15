// AR/ARCameraView.swift — 카메라 피드 (기존 UIImagePickerController 대체)
import SwiftUI
import AVFoundation

struct ARCameraView: UIViewRepresentable {
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.startSession()
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: CameraPreviewView, coordinator: ()) {
        uiView.stopSession()
    }
}

class CameraPreviewView: UIView {
    private var captureSession: AVCaptureSession?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    func startSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.addInput(input)

        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill

        captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func stopSession() {
        captureSession?.stopRunning()
    }
}
