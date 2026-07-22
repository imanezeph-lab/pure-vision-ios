import SwiftUI
import AVFoundation

struct CameraView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var outputDelegate = CameraOutputDelegate()
    @StateObject private var faceDetector = FaceDetector.shared

    @State private var cameraManager: CameraManager?
    @State private var detections: [DetectionResult] = []
    @State private var frameCount: Int = 0
    @State private var lastFPSTime = Date()
    @State private var currentFPS: Double = 0
    @State private var showPermissionAlert = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if let manager = cameraManager, manager.authorizationStatus == .authorized {
                    CameraPreviewView(cameraManager: manager)
                        .ignoresSafeArea()

                    OverlayView(
                        detections: detections,
                        containerSize: geometry.size,
                        censorType: appState.censorType,
                        showConfidence: appState.showConfidence
                    )
                    .ignoresSafeArea()

                    VStack {
                        Spacer()

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(appState.isEnabled ? Color.green : Color.red)
                                        .frame(width: 8, height: 8)
                                    Text(appState.isEnabled ? "Active" : "Paused")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }

                                Text("\(detections.count) detected")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))

                                Text(String(format: "%.0f FPS", currentFPS))
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(appState.censorType.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(appState.detectionTarget.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 90)

                        HStack(spacing: 32) {
                            Button(action: { cameraManager?.switchCamera() }) {
                                Image(systemName: "camera.rotate.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(.ultraThinMaterial))
                            }

                            Button(action: { appState.isEnabled.toggle() }) {
                                Image(systemName: appState.isEnabled ? "pause.fill" : "play.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 64, height: 64)
                                    .background(
                                        Circle()
                                            .fill(appState.isEnabled ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                                    )
                            }

                            Button(action: { capturePhoto() }) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(.ultraThinMaterial))
                            }
                        }
                        .padding(.bottom, 20)
                    }
                } else if let manager = cameraManager, manager.authorizationStatus == .notDetermined {
                    ProgressView("Requesting camera access...")
                        .foregroundColor(.white)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.5))
                        Text("Camera Access Required")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Please enable camera access in Settings to use Pure Vision.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)

                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(40)
                }
            }
        }
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            cameraManager?.stopSession()
        }
        .alert("Camera Access", isPresented: $showPermissionAlert) {
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Pure Vision needs camera access to detect and censor faces in real time.")
        }
    }

    private func setupCamera() {
        let delegate = outputDelegate
        let manager = CameraManager(delegate: delegate)
        self.cameraManager = manager

        manager.checkAuthorization()

        if manager.authorizationStatus == .authorized {
            manager.setupCamera()
            manager.startSession()
        }

        setupFrameProcessing()
    }

    private func setupFrameProcessing() {
        Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { _ in
            guard appState.isEnabled, let pixelBuffer = outputDelegate.latestPixelBuffer else { return }

            FaceDetector.shared.detect(in: pixelBuffer, target: appState.detectionTarget) { results in
                self.detections = results
                updateFPS()
            }
        }
    }

    private func capturePhoto() {}

    private func updateFPS() {
        frameCount += 1
        let now = Date()
        let elapsed = now.timeIntervalSince(lastFPSTime)
        if elapsed >= 1.0 {
            currentFPS = Double(frameCount) / elapsed
            frameCount = 0
            lastFPSTime = now
        }
    }
}
