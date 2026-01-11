import Foundation

enum WebSearchProvider: String, CaseIterable, Identifiable {
    case linkup = "linkup"
    case tavily = "tavily"
    case exa = "exa"
    case kagi = "kagi"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .linkup: return "Linkup"
        case .tavily: return "Tavily"
        case .exa: return "Exa"
        case .kagi: return "Kagi"
        }
    }

    var iconName: String {
        switch self {
        case .linkup: return "link"
        case .tavily: return "magnifyingglass"
        case .exa: return "dot.radiowaves.left.and.right"
        case .kagi: return "brain"
        }
    }
}
