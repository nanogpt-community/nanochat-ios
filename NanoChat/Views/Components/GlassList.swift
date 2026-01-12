import SwiftUI

struct GlassList<Content: View>: View {
    @ViewBuilder let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                content
            }
            .padding(Theme.Spacing.lg)
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}

struct GlassListSection<Content: View>: View {
    let title: String?
    @ViewBuilder let content: Content
    
    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if let title = title {
                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.leading, Theme.Spacing.sm)
            }
            
            VStack(spacing: 1) {
                content
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

struct GlassListRow<Content: View>: View {
    @ViewBuilder let content: Content
    let showDivider: Bool
    
    init(showDivider: Bool = true, @ViewBuilder content: () -> Content) {
        self.showDivider = showDivider
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                content
                Spacer()
            }
            .padding(Theme.Spacing.lg)
            .background(Color.white.opacity(0.001)) // For tap target
            
            if showDivider {
                Divider()
                    .overlay(Theme.Colors.glassBorder)
            }
        }
    }
}

#Preview {
    ZStack {
        Theme.Gradients.background.ignoresSafeArea()
        GlassList {
            GlassListSection("Section 1") {
                GlassListRow {
                    Label("Item 1", systemImage: "star")
                }
                GlassListRow(showDivider: false) {
                    Label("Item 2", systemImage: "heart")
                }
            }
            
            GlassListSection("Section 2") {
                GlassListRow(showDivider: false) {
                    Toggle("Toggle Me", isOn: .constant(true))
                }
            }
        }
    }
}
