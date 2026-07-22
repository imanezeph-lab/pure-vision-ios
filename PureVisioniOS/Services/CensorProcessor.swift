import Foundation
import Vision
import CoreImage
import UIKit

class CensorProcessor {

    static let shared = CensorProcessor()

    private let context = CIContext(options: [.useSoftwareRenderer: false])

    func processImage(
        _ image: UIImage,
        detections: [DetectionResult],
        censorType: CensorType,
        intensity: Double
    ) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        var currentImage = CIImage(cgImage: cgImage)
        let imageWidth = currentImage.extent.width
        let imageHeight = currentImage.extent.height

        for detection in detections {
            let box = detection.boundingBox

            let rectX = box.origin.x * imageWidth
            let rectY = (1.0 - box.origin.y - box.height) * imageHeight
            let rectW = box.width * imageWidth
            let rectH = box.height * imageHeight

            let cropRect = CGRect(x: rectX, y: rectY, width: rectW, height: rectH)
                .intersection(currentImage.extent)

            guard cropRect.width > 0, cropRect.height > 0 else { continue }

            guard let cropped = currentImage.cropped(to: cropRect) else { continue }

            let censored = applyCensor(to: cropped, type: censorType, intensity: intensity)
                .cropped(to: CGRect(x: 0, y: 0, width: cropRect.width, height: cropRect.height))

            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: cropRect.origin.x, y: cropRect.origin.y)
            let positioned = censored.transformed(by: transform)

            currentImage = positioned.composited(over: currentImage)
        }

        guard let outputCGImage = context.createCGImage(currentImage, from: currentImage.extent) else {
            return image
        }

        return UIImage(
            cgImage: outputCGImage,
            scale: image.scale,
            orientation: image.imageOrientation
        )
    }

    private func applyCensor(to image: CIImage, type: CensorType, intensity: Double) -> CIImage {
        let extent = image.extent

        switch type {
        case .blur:
            let radius = max(5.0, 25.0 * intensity)
            return image
                .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: radius])
                .cropped(to: extent)

        case .pixelate:
            let inputScale = max(0.02, 0.08 / intensity)
            let downscaled = image
                .applyingFilter("CILanczosScaleTransform", parameters: [
                    kCIInputScaleKey: inputScale
                ])
            return downscaled
                .applyingFilter("CILanczosScaleTransform", parameters: [
                    kCIInputScaleKey: 1.0 / inputScale
                ])
                .cropped(to: extent)

        case .mosaic:
            return applyMosaicFilter(to: image, intensity: intensity)

        case .blackBar:
            let barHeight = extent.height * min(0.5, 0.25 + 0.25 * intensity)
            let barRect = CGRect(
                x: 0,
                y: (extent.height - barHeight) / 2,
                width: extent.width,
                height: barHeight
            )
            let black = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 1))
                .cropped(to: barRect)
            return black.composited(over: image)

        case .darken:
            let amount = min(1.0, 0.8 * intensity)
            return image
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputBrightnessKey: -amount
                ])
                .cropped(to: extent)
        }
    }

    private func applyMosaicFilter(to image: CIImage, intensity: Double) -> CIImage {
        let extent = image.extent
        let pixelSize = max(4, Int(16.0 / intensity))

        guard let cgImage = context.createCGImage(image, from: extent) else {
            return image
        }

        let width = Int(extent.width)
        let height = Int(extent.height)

        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data) else {
            return image
        }

        let bytesPerRow = cgImage.bytesPerRow
        let bitsPerPixel = cgImage.bitsPerPixel
        let bytesPerPixel = bitsPerPixel / 8

        var outputData = [UInt8](repeating: 0, count: width * height * 4)

        var y = 0
        while y < height {
            var x = 0
            while x < width {
                let srcOffset = y * bytesPerRow + x * bytesPerPixel
                let r = ptr[srcOffset]
                let g = bytesPerPixel > 1 ? ptr[srcOffset + 1] : r
                let b = bytesPerPixel > 2 ? ptr[srcOffset + 2] : r

                var dy = 0
                while dy < pixelSize && y + dy < height {
                    var dx = 0
                    while dx < pixelSize && x + dx < width {
                        let dstOffset = ((y + dy) * width + (x + dx)) * 4
                        outputData[dstOffset] = r
                        outputData[dstOffset + 1] = g
                        outputData[dstOffset + 2] = b
                        outputData[dstOffset + 3] = 255
                        dx += 1
                    }
                    dy += 1
                }
                x += pixelSize
            }
            y += pixelSize
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let mosaicContext = CGContext(
            data: &outputData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let mosaicCG = mosaicContext.makeImage() else {
            return image
        }

        return CIImage(cgImage: mosaicCG).cropped(to: extent)
    }
}
