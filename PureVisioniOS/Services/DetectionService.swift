import Foundation
import Vision
import CoreImage
import UIKit
import AVFoundation

class FaceDetector: ObservableObject {

    static let shared = FaceDetector()

    @Published var latestDetections: [DetectionResult] = []

    private var faceRequest: VNDetectFaceLandmarksRequest?
    private var bodyRequest: VNDetectHumanRectanglesRequest?
    private var textRequest: VNDetectTextRectanglesRequest?
    private var handler: VNImageRequestHandler?

    private let processingQueue = DispatchQueue(label: "com.purevision.detector", qos: .userInitiated, attributes: .concurrent)
    private var isProcessing = false

    init() {
        setupRequests()
    }

    private func setupRequests() {
        faceRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            self?.handleFaceRequest(request: request, error: error)
        }
        faceRequest?.revision = VNDetectFaceLandmarksRequestRevision3

        bodyRequest = VNDetectHumanRectanglesRequest { [weak self] request, error in
            self?.handleBodyRequest(request: request, error: error)
        }

        textRequest = VNDetectTextRectanglesRequest { [weak self] request, error in
            self?.handleTextRequest(request: request, error: error)
        }
        textRequest?.reportCharacterBoxes = false
    }

    func detect(in pixelBuffer: CVPixelBuffer, target: DetectionTarget, completion: @escaping ([DetectionResult]) -> Void) {
        guard !isProcessing else { return }
        isProcessing = true

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        processingQueue.async { [weak self] in
            guard let self else { return }
            var allDetections: [DetectionResult] = []
            let group = DispatchGroup()

            if target == .faces || target == .both {
                group.enter()
                let request = VNDetectFaceLandmarksRequest { request, _ in
                    if let results = request.results as? [VNFaceObservation] {
                        let detections = results.map { obs -> DetectionResult in
                            DetectionResult(
                                boundingBox: obs.boundingBox,
                                confidence: obs.confidence,
                                label: .face
                            )
                        }
                        allDetections.append(contentsOf: detections)
                    }
                    group.leave()
                }
                request.revision = VNDetectFaceLandmarksRequestRevision3
                try? handler.perform([request])
            }

            if target == .bodies || target == .both {
                group.enter()
                let request = VNDetectHumanRectanglesRequest { request, _ in
                    if let results = request.results as? [VNHumanObservation] {
                        let detections = results.map { obs -> DetectionResult in
                            DetectionResult(
                                boundingBox: obs.boundingBox,
                                confidence: obs.confidence,
                                label: .body
                            )
                        }
                        allDetections.append(contentsOf: detections)
                    }
                    group.leave()
                }
                try? handler.perform([request])
            }

            group.notify(queue: .main) {
                self.isProcessing = false
                self.latestDetections = allDetections
                completion(allDetections)
            }
        }
    }

    func detectInImage(_ image: UIImage, target: DetectionTarget, completion: @escaping ([DetectionResult]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        var allDetections: [DetectionResult] = []
        let group = DispatchGroup()

        if target == .faces || target == .both {
            group.enter()
            let request = VNDetectFaceLandmarksRequest { request, _ in
                if let results = request.results as? [VNFaceObservation] {
                    let detections = results.map { obs -> DetectionResult in
                        DetectionResult(
                            boundingBox: obs.boundingBox,
                            confidence: obs.confidence,
                            label: .face
                        )
                    }
                    allDetections.append(contentsOf: detections)
                }
                group.leave()
            }
            request.revision = VNDetectFaceLandmarksRequestRevision3
            try? handler.perform([request])
        }

        if target == .bodies || target == .both {
            group.enter()
            let request = VNDetectHumanRectanglesRequest { request, _ in
                if let results = request.results as? [VNHumanObservation] {
                    let detections = results.map { obs -> DetectionResult in
                        DetectionResult(
                            boundingBox: obs.boundingBox,
                            confidence: obs.confidence,
                            label: .body
                        )
                    }
                    allDetections.append(contentsOf: detections)
                }
                group.leave()
            }
            try? handler.perform([request])
        }

        group.notify(queue: .main) {
            completion(allDetections)
        }
    }

    private func handleFaceRequest(request: VNRequest, error: Error?) {}

    private func handleBodyRequest(request: VNRequest, error: Error?) {}

    private func handleTextRequest(request: VNRequest, error: Error?) {}
}
