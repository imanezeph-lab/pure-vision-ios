import Foundation

enum CensorType: String, CaseIterable, Identifiable {
    case blur = "Blur"
    case pixelate = "Pixelate"
    case mosaic = "Mosaic"
    case blackBar = "Black Bar"
    case darken = "Darken"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .blur: return "aqi.medium"
        case .pixelate: return "squareshape.split.3x3"
        case .mosaic: return "square.grid.3x3"
        case .blackBar: return "rectangle.dashed"
        case .darken: return "circle.lefthalf.filled"
        }
    }
}

enum DetectionTarget: String, CaseIterable, Identifiable {
    case faces = "Faces"
    case bodies = "Bodies"
    case both = "Faces & Bodies"

    var id: String { rawValue }
}

enum AppMode: String, CaseIterable, Identifiable {
    case camera = "Camera"
    case photos = "Photos"

    var id: String { rawValue }
}
