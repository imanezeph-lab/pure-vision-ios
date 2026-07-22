import SwiftUI

struct OverlayView: View {
    let detections: [DetectionResult]
    let containerSize: CGSize
    let censorType: CensorType
    let showConfidence: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(detections) { detection in
                    let rect = normalizeRect(detection.boundingBox, in: geometry.size)

                    Group {
                        switch censorType {
                        case .blur:
                            censorBlur(rect: rect)
                        case .pixelate:
                            censorPixelate(rect: rect)
                        case .mosaic:
                            censorMosaic(rect: rect)
                        case .blackBar:
                            censorBlackBar(rect: rect)
                        case .darken:
                            censorDarken(rect: rect)
                        }
                    }
                    .overlay(
                        showConfidence ? confidenceLabel(detection, in: rect) : nil
                    )
                }
            }
        }
    }

    private func normalizeRect(_ boundingBox: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: boundingBox.origin.x * size.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * size.height,
            width: boundingBox.width * size.width,
            height: boundingBox.height * size.height
        )
    }

    private func censorBlur(rect: CGRect) -> some View {
        VisualEffectBlur(style: .systemUltraThinMaterial)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func censorPixelate(rect: CGRect) -> some View {
        let cols = 4
        let rows = 4

        return ZStack {
            ForEach(0..<(cols * rows), id: \.self) { i in
                let col = i % cols
                let row = i / cols
                let cellW = rect.width / CGFloat(cols)
                let cellH = rect.height / CGFloat(rows)
                let gray = Double.random(in: 0.2...0.8)

                Rectangle()
                    .fill(Color(white: gray))
                    .frame(width: cellW, height: cellH)
                    .position(
                        x: rect.minX + cellW * (CGFloat(col) + 0.5),
                        y: rect.minY + cellH * (CGFloat(row) + 0.5)
                    )
            }
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
        .clipped()
    }

    private func censorMosaic(rect: CGRect) -> some View {
        let blockSize: CGFloat = 12
        let cols = max(1, Int(rect.width / blockSize))
        let rows = max(1, Int(rect.height / blockSize))
        let count = min(cols * rows, 150)

        return ZStack {
            ForEach(0..<count, id: \.self) { i in
                let col = i % cols
                let row = i / cols
                let gray = Double.random(in: 0.15...0.85)

                Rectangle()
                    .fill(Color(white: gray))
                    .frame(width: blockSize, height: blockSize)
                    .position(
                        x: rect.minX + blockSize * (CGFloat(col) + 0.5),
                        y: rect.minY + blockSize * (CGFloat(row) + 0.5)
                    )
            }
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
        .clipped()
    }

    private func censorBlackBar(rect: CGRect) -> some View {
        Rectangle()
            .fill(Color.black)
            .frame(width: rect.width, height: rect.height * 0.4)
            .position(x: rect.midX, y: rect.midY)
    }

    private func censorDarken(rect: CGRect) -> some View {
        Rectangle()
            .fill(Color.black.opacity(0.85))
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func confidenceLabel(_ detection: DetectionResult, in rect: CGRect) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(detection.label.rawValue)
                .font(.caption2)
                .fontWeight(.bold)
            Text(String(format: "%.0f%%", detection.confidence * 100))
                .font(.caption2)
        }
        .foregroundColor(.white)
        .padding(4)
        .background(Color.black.opacity(0.7))
        .cornerRadius(4)
        .position(x: rect.minX + 30, y: rect.minY - 10)
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
