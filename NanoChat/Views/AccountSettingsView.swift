import SwiftUI

struct AccountSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var viewModel = AccountSettingsViewModel()
    @ObservedObject var modelManager: ModelManager

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task { await viewModel.loadSettings() }
                        }
                    }
                } else {
                    List {
                        generalSettingsSection
                        modelPreferencesSection
                        karakeepSection
                    }
                    .scrollContentBackground(.hidden)
                    .background(Theme.Colors.backgroundStart)
                }
            }
            .background(Theme.Colors.backgroundStart)
            .navigationTitle("Account Settings")
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
        .task {
            await viewModel.loadSettings()
            await modelManager.loadModels()
        }
    }

    private var generalSettingsSection: some View {
        Section("General") {
            Toggle(isOn: Binding(
                get: { viewModel.privacyMode },
                set: { newValue in
                    Task { await viewModel.updatePrivacyMode(newValue) }
                }
            )) {
                VStack(alignment: .leading) {
                    Text("Hide Personal Information")
                        .foregroundStyle(Theme.Colors.text)
                    Text("Blur your name and avatar in the sidebar")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .tint(Theme.Colors.accent)
            .listRowBackground(Theme.Colors.sectionBackground)

            Toggle(isOn: Binding(
                get: { viewModel.contextMemoryEnabled },
                set: { newValue in
                    Task { await viewModel.updateContextMemoryEnabled(newValue) }
                }
            )) {
                VStack(alignment: .leading) {
                    Text("Context Memory")
                        .foregroundStyle(Theme.Colors.text)
                    Text("Compress long conversations for better context retention")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .tint(Theme.Colors.accent)
            .listRowBackground(Theme.Colors.sectionBackground)

            Toggle(isOn: Binding(
                get: { viewModel.persistentMemoryEnabled },
                set: { newValue in
                    Task { await viewModel.updatePersistentMemoryEnabled(newValue) }
                }
            )) {
                VStack(alignment: .leading) {
                    Text("Persistent Memory")
                        .foregroundStyle(Theme.Colors.text)
                    Text("Remember facts about you across different conversations")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .tint(Theme.Colors.accent)
            .listRowBackground(Theme.Colors.sectionBackground)

            Toggle(isOn: Binding(
                get: { viewModel.youtubeTranscriptsEnabled },
                set: { newValue in
                    Task { await viewModel.updateYoutubeTranscriptsEnabled(newValue) }
                }
            )) {
                VStack(alignment: .leading) {
                    Text("YouTube Transcripts")
                        .foregroundStyle(Theme.Colors.text)
                    Text("Automatically fetch YouTube video transcripts ($0.01 each)")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .tint(Theme.Colors.accent)
            .listRowBackground(Theme.Colors.sectionBackground)

            Toggle(isOn: Binding(
                get: { viewModel.webScrapingEnabled },
                set: { newValue in
                    Task { await viewModel.updateWebScrapingEnabled(newValue) }
                }
            )) {
                VStack(alignment: .leading) {
                    Text("Web Scraping")
                        .foregroundStyle(Theme.Colors.text)
                    Text("Automatically scrape web page content when URLs are detected")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .tint(Theme.Colors.accent)
            .listRowBackground(Theme.Colors.sectionBackground)

            Toggle(isOn: Binding(
                get: { viewModel.mcpEnabled },
                set: { newValue in
                    Task { await viewModel.updateMcpEnabled(newValue) }
                }
            )) {
                VStack(alignment: .leading) {
                    Text("Nano-GPT MCP")
                        .foregroundStyle(Theme.Colors.text)
                    Text("Supports Vision, YouTube Transcripts, Web Scraping, Nano-GPT Balance, Image Generation, and Model Lists")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .tint(Theme.Colors.accent)
            .listRowBackground(Theme.Colors.sectionBackground)

            Toggle(isOn: Binding(
                get: { viewModel.followUpQuestionsEnabled },
                set: { newValue in
                    Task { await viewModel.updateFollowUpQuestionsEnabled(newValue) }
                }
            )) {
                VStack(alignment: .leading) {
                    Text("Follow-up Questions")
                        .foregroundStyle(Theme.Colors.text)
                    Text("Show suggested follow-up questions after each response")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .tint(Theme.Colors.accent)
            .listRowBackground(Theme.Colors.sectionBackground)
        }
    }

    private var modelPreferencesSection: some View {
        Section("Model Preferences") {
            // Manage Available Models
            NavigationLink {
                AvailableModelsView(modelManager: modelManager)
            } label: {
                Label("Available Models", systemImage: "list.bullet.rectangle.portrait")
                    .foregroundStyle(Theme.Colors.text)
            }
            .listRowBackground(Theme.Colors.sectionBackground)

            // Title Generation Model
            Picker("Chat Title Generation", selection: Binding(
                get: {
                    if viewModel.titleModelId.isEmpty ||
                       !modelManager.allModels.contains(where: { $0.modelId == viewModel.titleModelId }) {
                        return ""
                    }
                    return viewModel.titleModelId
                },
                set: { (newValue: String) in
                    Task { await viewModel.updateTitleModelId(newValue) }
                }
            )) {
                Text("Default (GLM-4.5-Air)").tag("")
                ForEach(modelManager.allModels.filter { $0.enabled }, id: \.id) { model in
                    Text(model.name ?? model.modelId).tag(model.modelId)
                }
            }
            .foregroundStyle(Theme.Colors.text)
            .listRowBackground(Theme.Colors.sectionBackground)

            // Follow-up Questions Model
            Picker("Follow-up Questions", selection: Binding(
                get: {
                    if viewModel.followUpModelId.isEmpty ||
                       !modelManager.allModels.contains(where: { $0.modelId == viewModel.followUpModelId }) {
                        return ""
                    }
                    return viewModel.followUpModelId
                },
                set: { (newValue: String) in
                    Task { await viewModel.updateFollowUpModelId(newValue) }
                }
            )) {
                Text("Default (GLM-4.5-Air)").tag("")
                ForEach(modelManager.allModels.filter { $0.enabled }, id: \.id) { model in
                    Text(model.name ?? model.modelId).tag(model.modelId)
                }
            }
            .foregroundStyle(Theme.Colors.text)
            .listRowBackground(Theme.Colors.sectionBackground)
        }
    }

    private var karakeepSection: some View {
        Section("Karakeep Integration") {
            VStack(alignment: .leading) {
                Text("Karakeep URL")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                TextField("https://karakeep.example.com", text: $viewModel.karakeepUrl)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .foregroundStyle(Theme.Colors.text)
            }
            .listRowBackground(Theme.Colors.sectionBackground)

            VStack(alignment: .leading) {
                Text("API Key")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                SecureField("Enter your Karakeep API key", text: $viewModel.karakeepApiKey)
                    .textFieldStyle(.roundedBorder)
                    .foregroundStyle(Theme.Colors.text)
            }
            .listRowBackground(Theme.Colors.sectionBackground)

            Button {
                Task {
                    await viewModel.updateKarakeepSettings(
                        url: viewModel.karakeepUrl,
                        apiKey: viewModel.karakeepApiKey
                    )
                }
            } label: {
                if viewModel.isUpdating {
                    ProgressView()
                        .tint(Theme.Colors.text)
                } else {
                    Text("Save Settings")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.accent)
            .disabled(viewModel.isUpdating)
            .listRowBackground(Theme.Colors.sectionBackground)
        }
    }
}

#Preview {
    AccountSettingsView(modelManager: ModelManager())
}
