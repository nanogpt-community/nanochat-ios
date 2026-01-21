import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showSettings = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var formOffset: CGFloat = 30
    @State private var formOpacity: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.Gradients.background
                    .ignoresSafeArea()

                // Decorative glow circles
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.Colors.primary.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(x: -100, y: -200)
                    .blur(radius: 60)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.Colors.secondary.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: 150, y: 300)
                    .blur(radius: 40)

                VStack(spacing: Theme.Spacing.xxl) {
                    Spacer()

                    // Logo and Title
                    VStack(spacing: Theme.Spacing.lg) {
                        ZStack {
                            // Glow behind icon
                            Circle()
                                .fill(Theme.Colors.secondary.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .blur(radius: 30)

                            Circle()
                                .fill(Theme.Gradients.primary)
                                .frame(width: 90, height: 90)
                                .overlay(
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.white)
                                )
                                .shadow(
                                    color: Theme.Colors.primary.opacity(0.5), radius: 20, x: 0,
                                    y: 10)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                        VStack(spacing: Theme.Spacing.sm) {
                            Text("NanoChat")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.Colors.text)

                            Text("iOS client for NanoChat web app")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .opacity(logoOpacity)
                    }

                    Spacer()

                    // Authentication Form
                    VStack(spacing: Theme.Spacing.xl) {
                        // Server URL Field
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("NanoChat Server URL")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.Colors.textSecondary)

                            TextField(
                                "https://t3.0xgingi.xyz", text: $authManager.baseURL
                            )
                            .textFieldStyle(.plain)
                            .padding(Theme.Spacing.md)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                    .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                            )
                            .autocapitalization(.none)
                            .keyboardType(.URL)
                            .foregroundStyle(Theme.Colors.text)

                            Text(
                                "Enter the URL where your NanoChat instance is hosted, not the NanoGPT API URL"
                            )
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                        }

                        // API Key Field
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("API Key")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.Colors.textSecondary)

                            SecureField("Enter your API key", text: $authManager.apiKey)
                                .textFieldStyle(.plain)
                                .padding(Theme.Spacing.md)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                        .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                                )
                                .foregroundStyle(Theme.Colors.text)

                            Text(
                                "Generate a NanoChat API key from your NanoChat web app settings (not from nano-gpt.com)"
                            )
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                        }

                        // Error Message
                        if let errorMessage = authManager.errorMessage {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Theme.Colors.error)
                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.Colors.error)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.error.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                    .stroke(Theme.Colors.error.opacity(0.3), lineWidth: 1)
                            )
                        }

                        // Connect Button
                        Button(action: {
                            HapticManager.shared.tap()
                            Task {
                                await authManager.validateAndSaveCredentials()
                                if authManager.isAuthenticated {
                                    HapticManager.shared.success()
                                } else {
                                    HapticManager.shared.error()
                                }
                            }
                        }) {
                            HStack(spacing: Theme.Spacing.sm) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Connect")
                                        .font(.headline)
                                    Image(systemName: "arrow.right")
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(
                                Group {
                                    if authManager.apiKey.isEmpty || authManager.isLoading {
                                        Theme.Colors.glassBackground
                                    } else {
                                        Theme.Colors.accent
                                    }
                                }
                            )
                            .foregroundStyle(
                                authManager.apiKey.isEmpty || authManager.isLoading
                                    ? Theme.Colors.textTertiary : .white
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                            .shadow(
                                color: (authManager.apiKey.isEmpty || authManager.isLoading)
                                    ? .clear : Theme.Colors.accent.opacity(0.4),
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(authManager.apiKey.isEmpty || authManager.isLoading)
                    }
                    .padding(Theme.Spacing.xl)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xl))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                            .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                    )
                    .shadow(color: Theme.Colors.glassShadow, radius: 20, x: 0, y: 10)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .offset(y: formOffset)
                    .opacity(formOpacity)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                ServerSettingsView()
                    .presentationBackground(.ultraThinMaterial)
            }
            .onAppear {
                withAnimation(Theme.Animation.smooth.delay(0.1)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                withAnimation(Theme.Animation.smooth.delay(0.3)) {
                    formOffset = 0
                    formOpacity = 1.0
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}
