import Foundation

enum WebSearchProvider: String, CaseIterable, Identifiable {
    case linkup = "linkup"
    case tavily = "tavily"
    case exa = "exa"
    case kagi = "kagi"
    case perplexity = "perplexity"
    case valyu = "valyu"
    case brave = "brave"
    case bravePro = "brave-pro"
    case braveResearch = "brave-research"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .linkup: return "Linkup"
        case .tavily: return "Tavily"
        case .exa: return "Exa"
        case .kagi: return "Kagi"
        case .perplexity: return "Perplexity"
        case .valyu: return "Valyu"
        case .brave: return "Brave"
        case .bravePro: return "Brave Pro"
        case .braveResearch: return "Brave Research"
        }
    }

    var iconName: String {
        switch self {
        case .linkup: return "link"
        case .tavily: return "magnifyingglass"
        case .exa: return "dot.radiowaves.left.and.right"
        case .kagi: return "brain"
        case .perplexity: return "bolt.horizontal.circle"
        case .valyu: return "chart.line.uptrend.xyaxis"
        case .brave: return "shield"
        case .bravePro: return "shield.lefthalf.filled"
        case .braveResearch: return "shield.righthalf.filled"
        }
    }
}

enum WebSearchExaDepth: String, CaseIterable, Identifiable {
    case fast = "fast"
    case auto = "auto"
    case neural = "neural"
    case deep = "deep"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fast: return "Fast"
        case .auto: return "Auto"
        case .neural: return "Neural"
        case .deep: return "Deep"
        }
    }
}

enum WebSearchContextSize: String, CaseIterable, Identifiable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

enum WebSearchKagiSource: String, CaseIterable, Identifiable {
    case web = "web"
    case news = "news"
    case search = "search"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .web: return "Web"
        case .news: return "News"
        case .search: return "Search"
        }
    }
}

enum WebSearchValyuSearchType: String, CaseIterable, Identifiable {
    case all = "all"
    case web = "web"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .web: return "Web"
        }
    }
}
