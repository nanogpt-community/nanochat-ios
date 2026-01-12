import SwiftUI

struct ModelCapabilityBadge: View {
    let capability: CapabilityType
    let isEnabled: Bool

    var body: some View {
        if isEnabled {
            HStack(spacing: 2) {
                Image(systemName: capability.iconName)
                    .font(.system(size: 8))
                Text(capability.shortName)
                    .font(.system(size: 8, weight: .medium))
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(capability.color.opacity(0.2))
            .foregroundStyle(capability.color)
            .clipShape(Capsule())
        }
    }
}

enum CapabilityType {
    case vision
    case reasoning
    case images
    case video

    var iconName: String {
        switch self {
        case .vision: return "eye"
        case .reasoning: return "brain.head.profile"
        case .images: return "photo"
        case .video: return "video"
        }
    }

    var shortName: String {
        switch self {
        case .vision: return "Vision"
        case .reasoning: return "Think"
        case .images: return "Image"
        case .video: return "Video"
        }
    }

    var color: Color {
        switch self {
        case .vision: return Theme.Colors.accent
        case .reasoning: return Theme.Colors.secondary
        case .images: return Theme.Colors.success
        case .video: return Theme.Colors.warning
        }
    }
}

struct ModelCapabilityBadges: View {
    let capabilities: ModelCapabilities?
    var subscriptionIncluded: Bool? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let capabilities {
                if capabilities.vision == true {
                    capabilityIcon(CapabilityType.vision)
                }
                if capabilities.reasoning == true {
                    capabilityIcon(CapabilityType.reasoning)
                }
                if capabilities.images == true {
                    capabilityIcon(CapabilityType.images)
                }
                if capabilities.video == true {
                    capabilityIcon(CapabilityType.video)
                }
            }

            if let subscriptionIncluded, subscriptionIncluded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.Colors.success)
                    .fixedSize()
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func capabilityIcon(_ type: CapabilityType) -> some View {
        Image(systemName: type.iconName)
            .foregroundStyle(type.color)
            .fixedSize()
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.md) {
        ModelCapabilityBadges(capabilities: ModelCapabilities(
            vision: true,
            reasoning: true,
            images: false,
            video: false
        ))

        ModelCapabilityBadges(capabilities: ModelCapabilities(
            vision: true,
            reasoning: true,
            images: true,
            video: true
        ))

        ModelCapabilityBadges(capabilities: nil)
    }
    .padding()
    .background(Theme.Gradients.background)
}
