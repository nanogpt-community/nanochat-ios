import SwiftUI

struct GlassSheet<Content: View>: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            Theme.Gradients.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(title)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.text)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Theme.Colors.glassBackground)
                
                Divider()
                    .overlay(Theme.Colors.glassBorder)
                
                // Content
                content
            }
        }
    }
}

#Preview {
    GlassSheet(title: "Settings") {
        Text("Content")
            .padding()
            .foregroundStyle(.white)
    }
}
