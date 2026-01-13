import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @State private var showingLogoutAlert = false
    @State private var showingAccountSettings = false
    @StateObject private var modelManager = ModelManager()

    var body: some View {
        ZStack {
            // Background
            Theme.Gradients.background
                .ignoresSafeArea()

            // Decorative glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.Colors.primary.opacity(0.12), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 150, y: -100)
                .ignoresSafeArea()

            NavigationStack {
                GlassList {
                    // Account Section
                    GlassListSection("Account") {
                        GlassListRow {
                            HStack(spacing: Theme.Spacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(Theme.Gradients.primary)
                                        .frame(width: 50, height: 50)
                                        .shadow(
                                            color: Theme.Colors.primary.opacity(0.4), radius: 8,
                                            x: 0, y: 4)

                                    Image(systemName: "person.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Authenticated")
                                        .font(.headline)
                                        .foregroundStyle(Theme.Colors.text)

                                    Text("API Key configured")
                                        .font(.caption)
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Theme.Colors.success)
                            }
                            .padding(.vertical, Theme.Spacing.xs)
                        }

                        GlassListRow {
                            Button {
                                HapticManager.shared.tap()
                                showingAccountSettings = true
                            } label: {
                                HStack {
                                    Image(systemName: "person.text.rectangle")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.Colors.primary)
                                        .frame(width: 28)

                                    Text("Account Settings")
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.Colors.text)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }

                        GlassListRow(showDivider: false) {
                            NavigationLink {
                                AnalyticsView()
                            } label: {
                                HStack {
                                    Image(systemName: "chart.bar.xaxis")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.Colors.secondary)
                                        .frame(width: 28)

                                    Text("Analytics")
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.Colors.text)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Configuration Section
                    GlassListSection("Configuration") {
                        GlassListRow {
                            SettingsRow(
                                icon: "server.rack",
                                iconColor: Theme.Colors.primary,
                                title: "Server URL",
                                value: authManager.baseURL
                            )
                        }

                        GlassListRow {
                            SettingsRow(
                                icon: "key.fill",
                                iconColor: Theme.Colors.secondary,
                                title: "API Key",
                                value: String(authManager.apiKey.prefix(16)) + "..."
                            )
                        }

                        GlassListRow(showDivider: false) {
                            Button {
                                HapticManager.shared.tap()
                                authManager.isAuthenticated = false
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.Colors.secondary)
                                        .frame(width: 28)

                                    Text("Update Credentials")
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.Colors.text)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Appearance Section
                    GlassListSection("Appearance") {
                        GlassListRow(showDivider: false) {
                            HStack {
                                Image(systemName: "paintbrush.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.Colors.accent)
                                    .frame(width: 28)

                                Text("Theme")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.Colors.text)

                                Spacer()

                                Picker("", selection: $themeManager.currentTheme) {
                                    Text("System").tag(ThemeManager.Theme.system)
                                    Text("Light").tag(ThemeManager.Theme.light)
                                    Text("Dark").tag(ThemeManager.Theme.dark)
                                }
                                .pickerStyle(.menu)
                                .tint(Theme.Colors.secondary)
                            }
                        }
                    }

                    // About Section
                    GlassListSection("About") {
                        GlassListRow {
                            SettingsRow(
                                icon: "info.circle.fill",
                                iconColor: Theme.Colors.textSecondary,
                                title: "Version",
                                value: Bundle.main.fullVersion
                            )
                        }

                        GlassListRow(showDivider: false) {
                            Link(
                                destination: URL(
                                    string: "https://github.com/nicholasgriffintn/nanochat")!
                            ) {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.Colors.primary)
                                        .frame(width: 28)

                                    Text("Documentation")
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.Colors.text)

                                    Spacer()

                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }
                            }
                        }
                    }

                    // Actions Section
                    GlassListSection("Actions") {
                        GlassListRow(showDivider: false) {
                            Button {
                                HapticManager.shared.warning()
                                showingLogoutAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.Colors.error)
                                        .frame(width: 28)

                                    Text("Sign Out")
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.Colors.error)

                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
                .liquidGlassNavigationBar()
                .alert("Sign Out", isPresented: $showingLogoutAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Sign Out", role: .destructive) {
                        HapticManager.shared.success()
                        authManager.clearCredentials()
                        authManager.isAuthenticated = false
                    }
                } message: {
                    Text("Are you sure you want to sign out? Your local data will remain.")
                }
                .sheet(isPresented: $showingAccountSettings) {
                    AccountSettingsView(modelManager: modelManager)
                }
            }
        }
    }
}

// MARK: - Settings Row Component

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 28)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.text)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
        .environmentObject(ThemeManager())
}
