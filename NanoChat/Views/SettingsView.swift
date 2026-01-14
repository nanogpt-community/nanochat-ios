import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @State private var showingLogoutAlert = false
    @State private var showingAccountSettings = false
    @StateObject private var modelManager = ModelManager()
    @StateObject private var audioPreferences = AudioPreferences.shared

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

                        GlassListRow {
                            NavigationLink {
                                AudioSettingsView(audioPreferences: audioPreferences)
                            } label: {
                                HStack {
                                    Image(systemName: "waveform")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.Colors.accent)
                                        .frame(width: 28)

                                    Text("Audio Settings")
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

// MARK: - Audio Settings View

struct AudioSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var audioPreferences: AudioPreferences

    var body: some View {
        ZStack {
            Theme.Gradients.background
                .ignoresSafeArea()

            NavigationStack {
                GlassList {
                    ttsSection
                    sttSection
                    behaviorSection

                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .navigationTitle("Audio Settings")
                .navigationBarTitleDisplayMode(.large)
                .liquidGlassNavigationBar()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            HapticManager.shared.tap()
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var ttsSection: some View {
        GlassListSection("Text to Speech") {
            GlassListRow {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Model")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.text)

                    Picker("Model", selection: Binding(
                        get: { audioPreferences.ttsModel },
                        set: { audioPreferences.updateTtsModel($0) }
                    )) {
                        ForEach(AudioPreferences.ttsModels, id: \.id) { model in
                            Text(model.label).tag(model.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            GlassListRow {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Voice")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.text)

                    Picker("Voice", selection: Binding(
                        get: { audioPreferences.ttsVoice },
                        set: { audioPreferences.updateVoice($0) }
                    )) {
                        ForEach(audioPreferences.availableVoices, id: \.id) { voice in
                            Text(voice.label).tag(voice.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            GlassListRow(showDivider: false) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Text("Speed")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.text)

                        Spacer()

                        Text(String(format: "%.2fx", audioPreferences.ttsSpeed))
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Slider(value: $audioPreferences.ttsSpeed, in: 0.5...2.0, step: 0.05)
                        .tint(Theme.Colors.secondary)
                }
            }
        }
    }

    private var sttSection: some View {
        GlassListSection("Speech to Text") {
            GlassListRow {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Model")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.text)

                    Picker("Model", selection: $audioPreferences.sttModel) {
                        ForEach(AudioPreferences.sttModels, id: \.id) { model in
                            Text(model.label).tag(model.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            GlassListRow(showDivider: false) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Language")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.text)

                    Picker("Language", selection: $audioPreferences.sttLanguage) {
                        ForEach(AudioPreferences.sttLanguages, id: \.id) { language in
                            Text(language.label).tag(language.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }

    private var behaviorSection: some View {
        GlassListSection("Voice Input") {
            GlassListRow(showDivider: false) {
                Toggle(isOn: $audioPreferences.autoSendTranscription) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Auto-send transcription")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.text)

                        Text("Send immediately after transcription finishes.")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .tint(Theme.Colors.secondary)
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
