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
            List {
                // Account Section
                Section("Account") {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.Colors.primary)

                        VStack(alignment: .leading, spacing: 2) {
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
                    .padding(.vertical, 4)

                    Button {
                        HapticManager.shared.tap()
                        showingAccountSettings = true
                    } label: {
                        Label("Account Settings", systemImage: "person.text.rectangle")
                            .foregroundStyle(Theme.Colors.text)
                    }

                    NavigationLink {
                        AnalyticsView()
                    } label: {
                        Label("Analytics", systemImage: "chart.bar.xaxis")
                            .foregroundStyle(Theme.Colors.text)
                    }
                }

                // Configuration Section
                Section("Configuration") {
                    SettingsRow(
                        icon: "server.rack",
                        iconColor: Theme.Colors.primary,
                        title: "Server URL",
                        value: authManager.baseURL
                    )

                    SettingsRow(
                        icon: "key.fill",
                        iconColor: Theme.Colors.secondary,
                        title: "API Key",
                        value: String(authManager.apiKey.prefix(16)) + "..."
                    )

                    NavigationLink {
                        AudioSettingsView(audioPreferences: audioPreferences)
                    } label: {
                        Label("Audio Settings", systemImage: "waveform")
                            .foregroundStyle(Theme.Colors.text)
                    }

                    Button {
                        HapticManager.shared.tap()
                        authManager.isAuthenticated = false
                    } label: {
                        Label("Update Credentials", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundStyle(Theme.Colors.text)
                    }
                }

                // Appearance Section
                Section("Appearance") {
                    HStack {
                        Label("Theme", systemImage: "paintbrush.fill")
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

                // About Section
                Section("About") {
                    SettingsRow(
                        icon: "info.circle.fill",
                        iconColor: Theme.Colors.textSecondary,
                        title: "Version",
                        value: Bundle.main.fullVersion
                    )

                    Link(destination: URL(string: "https://github.com/nanogpt-community/nanochat")!) {
                        HStack {
                            Label("Documentation", systemImage: "book.fill")
                                .foregroundStyle(Theme.Colors.text)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                }

                // Actions Section
                Section {
                    Button(role: .destructive) {
                        HapticManager.shared.warning()
                        showingLogoutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right.fill")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
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

// MARK: - Audio Settings View

struct AudioSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var audioPreferences: AudioPreferences

    var body: some View {
        NavigationStack {
            List {
                Section("Text to Speech") {
                    Picker("Model", selection: Binding(
                        get: { audioPreferences.ttsModel },
                        set: { audioPreferences.updateTtsModel($0) }
                    )) {
                        ForEach(AudioPreferences.ttsModels, id: \.id) { model in
                            Text(model.label).tag(model.id)
                        }
                    }

                    Picker("Voice", selection: Binding(
                        get: { audioPreferences.ttsVoice },
                        set: { audioPreferences.updateVoice($0) }
                    )) {
                        ForEach(audioPreferences.availableVoices, id: \.id) { voice in
                            Text(voice.label).tag(voice.id)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Speed")
                            Spacer()
                            Text(String(format: "%.2fx", audioPreferences.ttsSpeed))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $audioPreferences.ttsSpeed, in: 0.5...2.0, step: 0.05)
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
                            Text("Send immediately after transcription finishes.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Audio Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
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
            Label {
                Text(title).foregroundStyle(Theme.Colors.text)
            } icon: {
                Image(systemName: icon).foregroundStyle(iconColor)
            }

            Spacer()

            Text(value)
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
