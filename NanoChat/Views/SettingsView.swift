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
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with close button
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .frame(width: 30, height: 30)
                                .background(Theme.Colors.glassSurface)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, Theme.scaled(20))
                    .padding(.top, Theme.scaled(16))

                    // Profile Section
                    VStack(spacing: Theme.scaled(12)) {
                        // Avatar
                        Circle()
                            .fill(Theme.Colors.accent)
                            .frame(width: Theme.scaled(80), height: Theme.scaled(80))
                            .overlay(
                                Text("NC")
                                    .font(Theme.font(size: 28, weight: .semibold))
                                    .foregroundStyle(.white)
                            )

                        // Name
                        Text("NanoChat User")
                            .font(Theme.font(size: 20, weight: .semibold))
                            .foregroundStyle(Theme.Colors.text)

                        // Edit Profile Button
                        Button {
                            showingAccountSettings = true
                        } label: {
                            Text("Edit profile")
                                .font(Theme.font(size: 14))
                                .foregroundStyle(Theme.Colors.text)
                                .padding(.horizontal, Theme.scaled(16))
                                .padding(.vertical, Theme.scaled(8))
                                .background(Theme.Colors.glassSurface)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, Theme.scaled(24))

                    // Settings Sections
                    VStack(spacing: 8) {
                        // Account Section
                        SettingsSection(title: "Account") {
                            SettingsMenuItem(
                                icon: "envelope", title: "Server URL", subtitle: authManager.baseURL
                            )
                            SettingsMenuItem(
                                icon: "plus.circle", title: "API Key",
                                subtitle: String(authManager.apiKey.prefix(12)) + "...")
                            SettingsMenuButton(
                                icon: "arrow.triangle.2.circlepath", title: "Update Credentials"
                            ) {
                                authManager.isAuthenticated = false
                            }
                        }

                        // Configuration Section
                        SettingsSection(title: "Configuration") {
                            SettingsMenuNavLink(icon: "waveform", title: "Audio Settings") {
                                AudioSettingsView(audioPreferences: audioPreferences)
                            }
                            SettingsMenuNavLink(icon: "chart.bar.xaxis", title: "Analytics") {
                                AnalyticsView()
                            }
                        }

                        // Appearance Section
                        SettingsSection(title: "Appearance") {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Theme.Colors.text)
                                    .frame(width: 28)

                                Text("Theme")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Theme.Colors.text)

                                Spacer()

                                Picker("", selection: $themeManager.currentTheme) {
                                    Text("System").tag(ThemeManager.Theme.system)
                                    Text("Light").tag(ThemeManager.Theme.light)
                                    Text("Dark").tag(ThemeManager.Theme.dark)
                                }
                                .pickerStyle(.menu)
                                .tint(Theme.Colors.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }

                        // About Section
                        SettingsSection(title: "About") {
                            SettingsMenuItem(
                                icon: "info.circle", title: "Version",
                                subtitle: Bundle.main.fullVersion)

                            Link(
                                destination: URL(
                                    string: "https://github.com/nanogpt-community/nanochat")!
                            ) {
                                HStack {
                                    Image(systemName: "book")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Theme.Colors.text)
                                        .frame(width: 28)

                                    Text("Documentation")
                                        .font(.system(size: 16))
                                        .foregroundStyle(Theme.Colors.text)

                                    Spacer()

                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                        }

                        // Sign Out
                        Button {
                            showingLogoutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.red)
                                    .frame(width: 28)

                                Text("Sign Out")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.red)

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.glassSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Theme.Colors.backgroundStart)
            .id(themeManager.currentTheme)
            .navigationBarHidden(true)
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

// MARK: - Settings Section Component

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(Theme.font(size: 13, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary)
                .padding(.horizontal, Theme.scaled(16))
                .padding(.bottom, Theme.scaled(8))

            VStack(spacing: 0) {
                content
            }
            .background(Theme.Colors.glassSurface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.scaled(12)))
        }
        .padding(.horizontal, Theme.scaled(16))
    }
}

// MARK: - Settings Menu Item

struct SettingsMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(Theme.font(size: 18))
                .foregroundStyle(Theme.Colors.text)
                .frame(width: Theme.scaled(28))

            Text(title)
                .font(Theme.font(size: 16))
                .foregroundStyle(Theme.Colors.text)

            Spacer()

            Text(subtitle)
                .font(Theme.font(size: 14))
                .foregroundStyle(Theme.Colors.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, Theme.scaled(16))
        .padding(.vertical, Theme.scaled(14))
    }
}

// MARK: - Settings Menu Button

struct SettingsMenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(Theme.font(size: 18))
                    .foregroundStyle(Theme.Colors.text)
                    .frame(width: Theme.scaled(28))

                Text(title)
                    .font(Theme.font(size: 16))
                    .foregroundStyle(Theme.Colors.text)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Theme.font(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(.horizontal, Theme.scaled(16))
            .padding(.vertical, Theme.scaled(14))
        }
    }
}

// MARK: - Settings Menu Navigation Link

struct SettingsMenuNavLink<Destination: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(Theme.font(size: 18))
                    .foregroundStyle(Theme.Colors.text)
                    .frame(width: Theme.scaled(28))

                Text(title)
                    .font(Theme.font(size: 16))
                    .foregroundStyle(Theme.Colors.text)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Theme.font(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(.horizontal, Theme.scaled(16))
            .padding(.vertical, Theme.scaled(14))
        }
    }
}

// MARK: - Audio Settings View

struct AudioSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var audioPreferences: AudioPreferences

    var body: some View {
        NavigationStack {
            List {
                Section("Text to Speech") {
                    Picker(
                        "Model",
                        selection: Binding(
                            get: { audioPreferences.ttsModel },
                            set: { audioPreferences.updateTtsModel($0) }
                        )
                    ) {
                        ForEach(AudioPreferences.ttsModels, id: \.id) { model in
                            Text(model.label).tag(model.id)
                        }
                    }

                    Picker(
                        "Voice",
                        selection: Binding(
                            get: { audioPreferences.ttsVoice },
                            set: { audioPreferences.updateVoice($0) }
                        )
                    ) {
                        ForEach(audioPreferences.availableVoices, id: \.id) { voice in
                            Text(voice.label).tag(voice.id)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Speed")
                                .foregroundStyle(Theme.Colors.text)
                            Spacer()
                            Text(String(format: "%.2fx", audioPreferences.ttsSpeed))
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        Slider(value: $audioPreferences.ttsSpeed, in: 0.5...2.0, step: 0.05)
                            .tint(Theme.Colors.accent)
                    }
                }

                Section("Speech to Text") {
                    Picker("Model", selection: $audioPreferences.sttModel) {
                        ForEach(AudioPreferences.sttModels, id: \.id) { model in
                            Text(model.label).tag(model.id)
                        }
                    }

                    Picker("Language", selection: $audioPreferences.sttLanguage) {
                        ForEach(AudioPreferences.sttLanguages, id: \.id) { language in
                            Text(language.label).tag(language.id)
                        }
                    }
                }

                Section("Voice Input") {
                    Toggle(isOn: $audioPreferences.autoSendTranscription) {
                        VStack(alignment: .leading) {
                            Text("Auto-send transcription")
                                .foregroundStyle(Theme.Colors.text)
                            Text("Send immediately after transcription finishes.")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    .tint(Theme.Colors.accent)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.backgroundStart)
            .navigationTitle("Audio Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.accent)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
        .environmentObject(ThemeManager())
}
