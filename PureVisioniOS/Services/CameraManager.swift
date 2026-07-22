import Foundation
import AVFoundation
import SwiftUI
import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var isRunning = false
    @Published var currentFrame: CVPixelBuffer?
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var cameraPosition: AVCaptureDevice.Position = .back

    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "com.purevision.camera", qos: .userInitiated)
    private var videoConnection: AVCaptureConnection?
    private let outputDelegate: CameraOutputDelegate

    init(delegate: CameraOutputDelegate) {
        self.outputDelegate = delegate
        super.init()
        checkAuthorization()
    }

    func checkAuthorization() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authorizationStatus {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationStatus = granted ? .authorized : .denied
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .high

        if let device = cameraDevice(position: cameraPosition),
           let input = try? AVCaptureDeviceInput(device: device) {
            if session.canAddInput(input) {
                session.addInput(input)
            }
        }

        videoOutput.setSampleBufferDelegate(outputDelegate, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        videoConnection = videoOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait

        session.commitConfiguration()
    }

    func startSession() {
        guard authorizationStatus == .authorized else {
            checkAuthorization()
            return
        }

        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
                DispatchQueue.main.async {
                    self?.isRunning = true
                }
            }
        }
    }

    func stopSession() {
        if session.isRunning {
            session.stopRunning()
            isRunning = false
        }
    }

    func switchCamera() {
        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }

        let newPosition: AVCaptureDevice.Position = cameraPosition == .back ? .front : .back

        session.beginConfiguration()
        session.removeInput(currentInput)

        if let device = cameraDevice(position: newPosition),
           let newInput = try? AVCaptureDeviceInput(device: device) {
            if session.canAddInput(newInput) {
                session.addInput(newInput)
            }
        }

        videoConnection?.videoOrientation = .portrait
        session.commitConfiguration()

        cameraPosition = newPosition
    }

    private func cameraDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
}

class CameraOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    @Published var latestPixelBuffer: CVPixelBuffer?

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        DispatchQueue.main.async {
            self.latestPixelBuffer = pixelBuffer
        }
    }
}
