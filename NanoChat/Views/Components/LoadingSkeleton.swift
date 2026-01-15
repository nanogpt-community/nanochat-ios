import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    var duration: Double = 1.5
    var bounce: Bool = false

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Theme.Gradients.shimmer
                        .offset(x: phase * geometry.size.width)
                        .scaleEffect(x: 1.5) // Ensure gradient covers full width during movement
                }
            )
            .clipShape(ContainerRelativeShape())
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: bounce)
                ) {
                    phase = 2 // Move way past the end to ensure smooth loop
                }
            }
    }
}

extension View {
    func shimmering(duration: Double = 1.5, bounce: Bool = false) -> some View {
        modifier(ShimmerModifier(duration: duration, bounce: bounce))
    }
}

struct ConversationRowSkeleton: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Avatar
            Circle()
                .fill(Theme.Colors.glassBackground)
                .frame(width: 44, height: 44)
                .shimmering()

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Title line
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.Colors.glassBackground)
                        .frame(height: 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, 60) // Simulate variable length
                        .shimmering()
                    
                    Spacer()
                }

                // Subtitle/Date line
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.Colors.glassBackground)
                    .frame(width: 100, height: 12)
                    .shimmering()
            }
        }
        .padding(Theme.Spacing.md)
        .glassCard()
    }
}

struct ConversationListSkeleton: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ForEach(0..<6, id: \.self) { _ in
                ConversationRowSkeleton()
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.xs)
            }
        }
    }
}

struct MessageSkeleton: View {
    let isUser: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Avatar
            Circle()
                .fill(Theme.Colors.glassBackground)
                .frame(width: 32, height: 32)
                .shimmering()
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Header
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.Colors.glassBackground)
                    .frame(width: 60, height: 14)
                    .shimmering()
                
                // Content bubble
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.glassBackground)
                    .frame(height: Double.random(in: 40...80)) // Randomize height slightly
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .shimmering()
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
}

struct ChatSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                ForEach(0..<4, id: \.self) { index in
                    MessageSkeleton(isUser: index % 2 == 0)
                }
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
    }
}

struct GlassListSkeleton: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    // Section Header
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.Colors.glassBackground)
                        .frame(width: 80, height: 12)
                        .padding(.leading, Theme.Spacing.sm)
                        .shimmering()
                    
                    // Section Content
                    VStack(spacing: 1) {
                        ForEach(0..<2, id: \.self) { index in
                            HStack {
                                Circle()
                                    .fill(Theme.Colors.glassBackground)
                                    .frame(width: 28, height: 28)
                                    .shimmering()
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.Colors.glassBackground)
                                    .frame(width: 150, height: 16)
                                    .shimmering()
                                
                                Spacer()
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.Colors.glassBackground)
                                    .frame(width: 20, height: 12)
                                    .shimmering()
                            }
                            .padding(Theme.Spacing.lg)
                            
                            if index == 0 {
                                Divider()
                                    .overlay(Theme.Colors.glassBorder)
                            }
                        }
                    }
                    .background(Theme.Colors.glassPane)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg, style: .continuous)
                            .strokeBorder(Theme.Gradients.glass, lineWidth: 1)
                    )
                }
            }
        }
        .padding(Theme.Spacing.lg)
    }
}

#Preview {
    ZStack {
        Theme.Gradients.background.ignoresSafeArea()
        // ConversationListSkeleton()
        // ChatSkeleton()
        GlassListSkeleton()
    }
}
