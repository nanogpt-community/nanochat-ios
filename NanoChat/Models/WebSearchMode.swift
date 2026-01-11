import Foundation

enum WebSearchMode: String, CaseIterable, Identifiable {
    case off = "off"
    case standard = "standard"
    case deep = "deep"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .standard: return "Standard"
        case .deep: return "Deep"
        }
    }

    var costDisplay: String {
        switch self {
        case .off: return ""
        case .standard: return "$0.006"
        case .deep: return "$0.06"
        }
    }
}
