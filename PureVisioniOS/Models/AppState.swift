import Foundation
import SwiftUI

class AppState: ObservableObject {
    @AppStorage("censorType") var censorType: CensorType = .blur
    @AppStorage("detectionTarget") var detectionTarget: DetectionTarget = .faces
    @AppStorage("censorIntensity") var censorIntensity: Double = 1.0
    @AppStorage("isEnabled") var isEnabled: Bool = true
    @AppStorage("showConfidence") var showConfidence: Bool = false
    @AppStorage("saveCensored") var saveCensored: Bool = true

    @Published var currentMode: AppMode = .camera
    @Published var isProcessing: Bool = false
    @Published var detectionCount: Int = 0
    @Published var lastFPS: Double = 0

    static let shared = AppState()
}
