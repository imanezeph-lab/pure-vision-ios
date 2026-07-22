import Foundation
import Vision
import CoreImage
import UIKit
import Accelerate

class CensorProcessor {

    static let shared = CensorProcessor()

    private let context = CIContext(options: [.useSoftwareRenderer: false])

    func processFrame(
        pixelBuffer: CVPixelBuffer,
        detections: [DetectionResult],
        censorType: CensorType,
        intensity: Double
    ) -> CVPixelBuffer? {
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        for detection in detections {
            let rect = detection.boundingBox
            guard let cropped = ciImage.cropped(to: rect) else { continue }

            let censored = applyCensor(
                to: cropped,
                type: censorType,
                intensity: intensity
            )

            ciImage = censored.composited(over: ciImage)
        }

        var outputBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(
            nil,
            CVPixelBufferPool(nil),
            &outputBuffer
        )

        if outputBuffer == nil {
            outputBuffer = pixelBuffer
        }

        if let output = outputBuffer {
            context.render(ciImage, to: output)
        }

        return outputBuffer
    }

    func processImage(
        _ image: UIImage,
        detections: [DetectionResult],
        censorType: CensorType,
        intensity: Double
    ) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        var ciImage = CIImage(cgImage: cgImage)
        let scaleX = ciImage.extent.width / cgImage.width
        let scaleY = ciImage.extent.height / cgImage.height

        for detection in detections {
            let box = detection.boundingBox
            let scaledRect = CGRect(
                x: box.origin.x * ciImage.extent.width,
                y: box.origin.y * ciImage.extent.height,
                width: box.width * ciImage.extent.width,
                height: box.height * ciImage.extent.height
            )

            guard let cropped = ciImage.cropped(to: scaledRect) else { continue }

            let censored = applyCensor(
                to: cropped,
                type: censorType,
                intensity: intensity
            )

            ciImage = censored.applyingFilter("CILanczosScaleTransform", parameters: [
                kCIInputScaleKey: 1.0
            ]).composited(over: ciImage)

            ciImage = ciImage.cropped(to: ciImage.extent)

            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: -scaledRect.origin.x, y: -scaledRect.origin.y)
            let censoredMoved = censored.transformed(by: transform)

            let resultImage = censoredMoved.composited(over: ciImage)
            ciImage = resultImage
        }

        guard let outputCGImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }

        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func applyCensor(to image: CIImage, type: CensorType, intensity: Double) -> CIImage {
        switch type {
        case .blur:
            let radius = 20.0 * intensity
            return image.applyingGaussianBlur2D(sigma: radius)
                .cropped(to: image.extent)

        case .pixelate:
            let scale = max(0.02, 0.1 / intensity)
            let scaled = image
                .applyingFilter("CILanczosScaleTransform", parameters: [
                    kCIInputScaleKey: scale
                ])
            return scaled
                .applyingFilter("CILanczosScaleTransform", parameters: [
                    kCIInputScaleKey: 1.0 / scale
                ])
                .cropped(to: image.extent)

        case .mosaic:
            let blockSize = max(4, Int(12.0 * intensity))
            return applyMosaic(to: image, blockSize: blockSize)

        case .blackBar:
            let barHeight = image.extent.height * 0.3
            let barRect = CGRect(
                x: 0,
                y: (image.extent.height - barHeight) / 2,
                width: image.extent.width,
                height: barHeight
            )
            let black = CIImage(color: CIColor(red: 0, green: 0, blue: 0))
                .cropped(to: barRect)
            return black.composited(over: image)

        case .darken:
            return image
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputBrightnessKey: -0.8 * intensity
                ])
                .cropped(to: image.extent)
        }
    }

    private func applyMosaic(to image: CIImage, blockSize: Int) -> CIImage {
        let extent = image.extent
        guard let cgImage = CIContext().createCGImage(image, from: extent) else {
            return image
        }

        let width = Int(extent.width)
        let height = Int(extent.height)

        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else {
            return image
        }

        let bytesPerRow = cgImage.bytesPerRow
        let bitsPerPixel = cgImage.bitsPerPixel
        let bytesPerPixel = bitsPerPixel / 8

        var mosaicData = [UInt8](repeating: 0, count: width * height * 4)

        for y in stride(from: 0, to: height, by: blockSize) {
            for x in stride(from: 0, to: width, by: blockSize) {
                let srcOffset = y * bytesPerRow + x * bytesPerPixel
                let r = ptr[srcOffset]
                let g = ptr[srcOffset + 1]
                let b = ptr[srcOffset + 2]

                for dy in 0..<blockSize where y + dy < height {
                    for dx in 0..<blockSize where x + dx < width {
                        let dstOffset = ((y + dy) * width + (x + dx)) * 4
                        mosaicData[dstOffset] = r
                        mosaicData[dstOffset + 1] = g
                        mosaicData[dstOffset + 2] = b
                        mosaicData[dstOffset + 3] = 255
                    }
                }
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let mosaicContext = CGContext(
            data: &mosaicData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let mosaicCG = mosaicContext.makeImage() else {
            return image
        }

        return CIImage(cgImage: mosaicCG)
    }
}
