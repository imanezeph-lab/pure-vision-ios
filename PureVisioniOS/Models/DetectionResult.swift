import Foundation
import Vision
import CoreGraphics

struct DetectionResult: Identifiable {
    let id = UUID()
    let boundingBox: CGRect
    let confidence: Float
    let label: DetectionLabel
}

enum DetectionLabel: String {
    case face = "Face"
    case body = "Body"
    case text = "Text"
}
