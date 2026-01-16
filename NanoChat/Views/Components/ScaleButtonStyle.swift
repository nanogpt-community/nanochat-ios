import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95
    var animation: Animation = .spring(response: 0.3, dampingFraction: 0.6)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(animation, value: configuration.isPressed)
    }
}
