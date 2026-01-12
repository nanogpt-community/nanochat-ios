import SwiftUI

struct AccountSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var viewModel = AccountSettingsViewModel()
    @ObservedObject var modelManager: ModelManager

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
                VStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Theme.Colors.primary)
                    } else if let error = viewModel.error {
                        ErrorView(message: error) {
                            Task { await viewModel.loadSettings() }
                        }
                    } else {
                        GlassList {
                            generalSettingsSection
                            modelPreferencesSection
                            karakeepSection
                            
                            Spacer(minLength: Theme.Spacing.xxl)
                        }
                    }
                }
                .navigationTitle("Account Settings")
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
        .task {
            await viewModel.loadSettings()
            await modelManager.loadModels()
        }
    }

    private var generalSettingsSection: some View {
        GlassListSection("General") {
            GlassListRow {
                SettingsToggle(
                    title: "Hide Personal Information",
                    description: "Blur your name and avatar in the sidebar",
                    isOn: Binding(
                        get: { viewModel.privacyMode },
                        set: { newValue in
                            HapticManager.shared.tap()
                            Task { await viewModel.updatePrivacyMode(newValue) }
                        }
                    )
                )
            }

            GlassListRow {
                SettingsToggle(
                    title: "Context Memory",
                    description: "Compress long conversations for better context retention",
                    isOn: Binding(
                        get: { viewModel.contextMemoryEnabled },
                        set: { newValue in
                            HapticManager.shared.tap()
                            Task { await viewModel.updateContextMemoryEnabled(newValue) }
                        }
                    )
                )
            }

            GlassListRow {
                SettingsToggle(
                    title: "Persistent Memory",
                    description: "Remember facts about you across different conversations",
                    isOn: Binding(
                        get: { viewModel.persistentMemoryEnabled },
                        set: { newValue in
                            HapticManager.shared.tap()
                            Task { await viewModel.updatePersistentMemoryEnabled(newValue) }
                        }
                    )
                )
            }

            GlassListRow {
                SettingsToggle(
                    title: "YouTube Transcripts",
                    description: "Automatically fetch YouTube video transcripts ($0.01 each)",
                    isOn: Binding(
                        get: { viewModel.youtubeTranscriptsEnabled },
                        set: { newValue in
                            HapticManager.shared.tap()
                            Task { await viewModel.updateYoutubeTranscriptsEnabled(newValue) }
                        }
                    )
                )
            }

            GlassListRow {
                SettingsToggle(
                    title: "Web Scraping",
                    description: "Automatically scrape web page content when URLs are detected",
                    isOn: Binding(
                        get: { viewModel.webScrapingEnabled },
                        set: { newValue in
                            HapticManager.shared.tap()
                            Task { await viewModel.updateWebScrapingEnabled(newValue) }
                        }
                    )
                )
            }

            GlassListRow {
                SettingsToggle(
                    title: "Nano-GPT MCP",
                    description: "Supports Vision, YouTube Transcripts, Web Scraping, Nano-GPT Balance, Image Generation, and Model Lists",
                    isOn: Binding(
                        get: { viewModel.mcpEnabled },
                        set: { newValue in
                            HapticManager.shared.tap()
                            Task { await viewModel.updateMcpEnabled(newValue) }
                        }
                    )
                )
            }

            GlassListRow(showDivider: false) {
                SettingsToggle(
                    title: "Follow-up Questions",
                    description: "Show suggested follow-up questions after each response",
                    isOn: Binding(
                        get: { viewModel.followUpQuestionsEnabled },
                        set: { newValue in
                            HapticManager.shared.tap()
                            Task { await viewModel.updateFollowUpQuestionsEnabled(newValue) }
                        }
                    )
                )
            }
        }
    }

    private var modelPreferencesSection: some View {
        GlassListSection("Model Preferences") {
            // Manage Available Models
            GlassListRow {
                NavigationLink {
                    AvailableModelsView(modelManager: modelManager)
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.rectangle.portrait.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(width: 28)
                        
                        Text("Available Models")
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

            // Title Generation Model
            GlassListRow {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Chat Title Generation Model")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.text)

                    Picker("", selection: Binding(
                        get: {
                            // If the current model ID isn't in the loaded models, return empty string
                            if viewModel.titleModelId.isEmpty ||
                               !modelManager.allModels.contains(where: { $0.modelId == viewModel.titleModelId }) {
                                return ""
                            }
                            return viewModel.titleModelId
                        },
                        set: { (newValue: String) in
                            HapticManager.shared.tap()
                            Task { await viewModel.updateTitleModelId(newValue) }
                        }
                    )) {
                        Text("Default (GLM-4.5-Air)").tag("")
                        ForEach(modelManager.allModels.filter { $0.enabled }, id: \.id) { model in
                            Text(model.name ?? model.modelId).tag(model.modelId)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.Colors.secondary)
                    .labelsHidden()

                    Text("Select the model used to generate chat titles")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.vertical, Theme.Spacing.xs)
            }

            // Follow-up Questions Model
            GlassListRow(showDivider: false) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Follow-up Questions Model")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.text)

                    Picker("", selection: Binding(
                        get: {
                            // If the current model ID isn't in the loaded models, return empty string
                            if viewModel.followUpModelId.isEmpty ||
                               !modelManager.allModels.contains(where: { $0.modelId == viewModel.followUpModelId }) {
                                return ""
                            }
                            return viewModel.followUpModelId
                        },
                        set: { (newValue: String) in
                            HapticManager.shared.tap()
                            Task { await viewModel.updateFollowUpModelId(newValue) }
                        }
                    )) {
                        Text("Default (GLM-4.5-Air)").tag("")
                        ForEach(modelManager.allModels.filter { $0.enabled }, id: \.id) { model in
                            Text(model.name ?? model.modelId).tag(model.modelId)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.Colors.secondary)
                    .labelsHidden()

                    Text("Select the model used to generate follow-up questions")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
    }

    private var karakeepSection: some View {
        GlassListSection("Karakeep Integration") {
            GlassListRow {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Karakeep URL")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.text)

                    TextField("https://karakeep.example.com", text: $viewModel.karakeepUrl)
                        .textFieldStyle(.liquidGlass)

                    Text("The URL of your Karakeep instance")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.vertical, Theme.Spacing.xs)
            }

            GlassListRow {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("API Key")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.text)

                    TextField("Enter your Karakeep API key", text: $viewModel.karakeepApiKey)
                        .textFieldStyle(.liquidGlass)

                    Text("Your Karakeep API authentication key")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.vertical, Theme.Spacing.xs)
            }

            GlassListRow(showDivider: false) {
                Button {
                    HapticManager.shared.tap()
                    Task {
                        await viewModel.updateKarakeepSettings(
                            url: viewModel.karakeepUrl,
                            apiKey: viewModel.karakeepApiKey
                        )
                    }
                } label: {
                    HStack {
                        if viewModel.isUpdating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Settings")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidGlassButtonStyle())
                .disabled(viewModel.isUpdating)
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
    }
}

// MARK: - Settings Toggle Component

struct SettingsToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.text)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(Theme.Colors.primary)
                .labelsHidden()
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.error)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                HapticManager.shared.tap()
                retry()
            }
            .buttonStyle(LiquidGlassButtonStyle(style: .destructive))
        }
        .padding()
        .glassCard()
    }
}

#Preview {
    AccountSettingsView(modelManager: ModelManager())
}
