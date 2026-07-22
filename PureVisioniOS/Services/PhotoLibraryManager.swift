import Foundation
import PhotosUI
import SwiftUI
import UIKit

class PhotoLibraryManager: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var censoredImage: UIImage?
    @Published var isProcessing = false
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

    func checkAuthorization() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if authorizationStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                DispatchQueue.main.async {
                    self?.authorizationStatus = status
                }
            }
        }
    }

    func saveToLibrary(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCreationRequest.forAsset().addResource(with: .photo, data: image.jpegData(compressionQuality: 0.95)!, options: nil)
        }) { success, error in
            if let error = error {
                print("Failed to save: \(error)")
            }
        }
    }

    func processImage(
        _ image: UIImage,
        target: DetectionTarget,
        censorType: CensorType,
        intensity: Double,
        completion: @escaping (UIImage?) -> Void
    ) {
        isProcessing = true

        FaceDetector.shared.detectInImage(image, target: target) { detections in
            let processed = CensorProcessor.shared.processImage(
                image,
                detections: detections,
                censorType: censorType,
                intensity: intensity
            )

            DispatchQueue.main.async {
                self.isProcessing = false
                self.censoredImage = processed
                completion(processed)
            }
        }
    }
}
