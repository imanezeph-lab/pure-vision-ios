import Foundation
import Vision
import CoreImage
import UIKit

class FaceDetector: ObservableObject {

    static let shared = FaceDetector()

    @Published var latestDetections: [DetectionResult] = []

    private let processingQueue = DispatchQueue(label: "com.purevision.detector", qos: .userInitiated)

    func detect(
        in pixelBuffer: CVPixelBuffer,
        target: DetectionTarget,
        completion: @escaping ([DetectionResult]) -> Void
    ) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        processingQueue.async {
            var allDetections: [DetectionResult] = []

            if target == .faces || target == .both {
                let faceRequest = VNDetectFaceLandmarksRequest { request, _ in
                    if let results = request.results as? [VNFaceObservation] {
                        let detections = results.map { obs in
                            DetectionResult(
                                boundingBox: obs.boundingBox,
                                confidence: obs.confidence,
                                label: .face
                            )
                        }
                        allDetections.append(contentsOf: detections)
                    }
                }
                faceRequest.revision = VNDetectFaceLandmarksRequestRevision3
                try? handler.perform([faceRequest])
            }

            if target == .bodies || target == .both {
                let bodyRequest = VNDetectHumanRectanglesRequest { request, _ in
                    if let results = request.results as? [VNHumanObservation] {
                        let detections = results.map { obs in
                            DetectionResult(
                                boundingBox: obs.boundingBox,
                                confidence: obs.confidence,
                                label: .body
                            )
                        }
                        allDetections.append(contentsOf: detections)
                    }
                }
                try? handler.perform([bodyRequest])
            }

            DispatchQueue.main.async {
                self.latestDetections = allDetections
                completion(allDetections)
            }
        }
    }

    func detectInImage(
        _ image: UIImage,
        target: DetectionTarget,
        completion: @escaping ([DetectionResult]) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        var allDetections: [DetectionResult] = []

        if target == .faces || target == .both {
            let faceRequest = VNDetectFaceLandmarksRequest { request, _ in
                if let results = request.results as? [VNFaceObservation] {
                    let detections = results.map { obs in
                        DetectionResult(
                            boundingBox: obs.boundingBox,
                            confidence: obs.confidence,
                            label: .face
                        )
                    }
                    allDetections.append(contentsOf: detections)
                }
            }
            faceRequest.revision = VNDetectFaceLandmarksRequestRevision3
            try? handler.perform([faceRequest])
        }

        if target == .bodies || target == .both {
            let bodyRequest = VNDetectHumanRectanglesRequest { request, _ in
                if let results = request.results as? [VNHumanObservation] {
                    let detections = results.map { obs in
                        DetectionResult(
                            boundingBox: obs.boundingBox,
                            confidence: obs.confidence,
                            label: .body
                        )
                    }
                    allDetections.append(contentsOf: detections)
                }
            }
            try? handler.perform([bodyRequest])
        }

        DispatchQueue.main.async {
            completion(allDetections)
        }
    }
}
