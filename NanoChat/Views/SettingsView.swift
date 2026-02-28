import SwiftUI
import UIKit

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
                            SettingsMenuNavLink(icon: "key", title: "NanoGPT API Key") {
                                ProviderKeysView()
                            }
                            SettingsMenuNavLink(icon: "terminal", title: "Developer API Keys") {
                                DeveloperAPIKeysView()
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
                            SettingsMenuNavLink(icon: "text.badge.plus", title: "Prompt Templates")
                            {
                                PromptTemplatesManagementView()
                            }
                            SettingsMenuNavLink(icon: "clock.badge", title: "Scheduled Tasks") {
                                ScheduledTasksManagementView()
                            }
                            SettingsMenuNavLink(icon: "paintbrush.pointed", title: "Customization")
                            {
                                CustomizationToolsView()
                            }
                            SettingsMenuNavLink(icon: "photo.stack", title: "Gallery") {
                                StoredFilesGalleryView()
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

// MARK: - Provider API Keys

struct ProviderKeysView: View {
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var currentKey: String?
    @State private var keyInput = ""
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("NanoGPT Key") {
                if isLoading {
                    ProgressView()
                } else {
                    if let currentKey, !currentKey.isEmpty {
                        LabeledContent("Current", value: currentKey)
                            .foregroundStyle(Theme.Colors.text)
                    } else {
                        Text("No key configured")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    SecureField("Enter NanoGPT API key", text: $keyInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button {
                        Task { await saveKey() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save Key")
                        }
                    }
                    .disabled(
                        keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving
                    )

                    if currentKey != nil {
                        Button(role: .destructive) {
                            Task { await deleteKey() }
                        } label: {
                            Text("Delete Key")
                        }
                        .disabled(isSaving)
                    }
                }
            }
            .listRowBackground(Theme.Colors.sectionBackground)

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
                .listRowBackground(Theme.Colors.sectionBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.backgroundStart)
        .navigationTitle("NanoGPT API Key")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadKey()
        }
    }

    private func loadKey() async {
        isLoading = true
        defer { isLoading = false }

        do {
            currentKey = try await NanoChatAPI.shared.getProviderKey(provider: "nanogpt")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveKey() async {
        let trimmed = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            try await NanoChatAPI.shared.setProviderKey(provider: "nanogpt", key: trimmed)
            keyInput = ""
            errorMessage = nil
            await loadKey()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteKey() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await NanoChatAPI.shared.deleteProviderKey(provider: "nanogpt")
            currentKey = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Developer API Keys

struct DeveloperAPIKeysView: View {
    @State private var keys: [DeveloperAPIKey] = []
    @State private var isLoading = false
    @State private var isCreating = false
    @State private var newKeyName = ""
    @State private var newlyCreatedKey: String?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Create Key") {
                TextField("Key name", text: $newKeyName)
                    .textInputAutocapitalization(.words)

                Button {
                    Task { await createKey() }
                } label: {
                    if isCreating {
                        ProgressView()
                    } else {
                        Text("Generate Key")
                    }
                }
                .disabled(
                    newKeyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating
                )

                if let newlyCreatedKey {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Copy this key now. It will not be shown again.")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Text(newlyCreatedKey)
                            .font(.footnote.monospaced())
                            .textSelection(.enabled)
                        Button("Copy Key") {
                            UIPasteboard.general.string = newlyCreatedKey
                        }
                    }
                }
            }
            .listRowBackground(Theme.Colors.sectionBackground)

            Section("Keys") {
                if isLoading {
                    ProgressView()
                } else if keys.isEmpty {
                    Text("No API keys yet.")
                        .foregroundStyle(Theme.Colors.textSecondary)
                } else {
                    ForEach(keys) { key in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(key.name)
                                .font(.headline)
                                .foregroundStyle(Theme.Colors.text)
                            Text("Created: \(formatDate(key.createdAt))")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            if let lastUsedAt = key.lastUsedAt {
                                Text("Last used: \(formatDate(lastUsedAt))")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await deleteKey(id: key.id) }
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                }
            }
            .listRowBackground(Theme.Colors.sectionBackground)

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
                .listRowBackground(Theme.Colors.sectionBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.backgroundStart)
        .navigationTitle("Developer API Keys")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadKeys()
        }
    }

    private func loadKeys() async {
        isLoading = true
        defer { isLoading = false }
        do {
            keys = try await NanoChatAPI.shared.getDeveloperAPIKeys()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createKey() async {
        let trimmed = newKeyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isCreating = true
        defer { isCreating = false }

        do {
            let created = try await NanoChatAPI.shared.createDeveloperAPIKey(name: trimmed)
            newlyCreatedKey = created.key
            newKeyName = ""
            await loadKeys()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteKey(id: String) async {
        do {
            try await NanoChatAPI.shared.deleteDeveloperAPIKey(id: id)
            await loadKeys()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func formatDate(_ value: String?) -> String {
        guard let value else { return "Never" }
        let input = ISO8601DateFormatter()
        input.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = input.date(from: value) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return value
    }
}

// MARK: - Gallery

private enum GalleryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case images = "Images"
    case documents = "Documents"
    case projectFiles = "Project Files"
    case other = "Other"

    var id: String { rawValue }
}

struct StoredFilesGalleryView: View {
    @State private var files: [GalleryFile] = []
    @State private var isLoading = false
    @State private var isClearing = false
    @State private var filter: GalleryFilter = .all
    @State private var errorMessage: String?

    private var filteredFiles: [GalleryFile] {
        switch filter {
        case .all:
            return files
        case .images:
            return files.filter { $0.mimeType.hasPrefix("image/") }
        case .documents:
            return files.filter {
                $0.mimeType.contains("pdf")
                    || $0.mimeType.contains("markdown")
                    || $0.mimeType.contains("text")
                    || $0.mimeType.contains("epub")
            }
        case .projectFiles:
            return files.filter { $0.source == "project_file" }
        case .other:
            return files.filter { $0.source == "unlinked" }
        }
    }

    var body: some View {
        List {
            Section("Filters") {
                Picker("Filter", selection: $filter) {
                    ForEach(GalleryFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                Button(role: .destructive) {
                    Task { await clearUploads() }
                } label: {
                    if isClearing {
                        ProgressView()
                    } else {
                        Text("Clear All Uploads")
                    }
                }
                .disabled(isClearing)
            }
            .listRowBackground(Theme.Colors.sectionBackground)

            Section("Files") {
                if isLoading {
                    ProgressView()
                } else if filteredFiles.isEmpty {
                    Text("No files found.")
                        .foregroundStyle(Theme.Colors.textSecondary)
                } else {
                    ForEach(filteredFiles) { file in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(file.filename)
                                .font(.headline)
                                .foregroundStyle(Theme.Colors.text)
                            Text("\(file.mimeType) • \(formatBytes(file.size))")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            Text(file.createdAt)
                                .font(.caption2)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                openFile(file)
                            } label: {
                                Label("Open", systemImage: "arrow.up.right.square")
                            }
                            .tint(.blue)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await deleteFile(file.id) }
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                }
            }
            .listRowBackground(Theme.Colors.sectionBackground)

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
                .listRowBackground(Theme.Colors.sectionBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.backgroundStart)
        .navigationTitle("Gallery")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadFiles()
        }
    }

    private func loadFiles() async {
        isLoading = true
        defer { isLoading = false }

        do {
            files = try await NanoChatAPI.shared.getGalleryFiles()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteFile(_ id: String) async {
        do {
            try await NanoChatAPI.shared.deleteStorageFile(id: id)
            files.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearUploads() async {
        isClearing = true
        defer { isClearing = false }

        do {
            _ = try await NanoChatAPI.shared.clearAllUploads()
            files = []
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func openFile(_ file: GalleryFile) {
        let fileURL: URL?
        if file.url.lowercased().hasPrefix("http") {
            fileURL = URL(string: file.url)
        } else {
            fileURL = URL(string: APIConfiguration.shared.baseURL + file.url)
        }

        guard let fileURL else { return }
        UIApplication.shared.open(fileURL)
    }

    private func formatBytes(_ size: Int) -> String {
        guard size > 0 else { return "0 B" }
        let units = ["B", "KB", "MB", "GB"]
        var value = Double(size)
        var unitIndex = 0
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        return "\(String(format: value >= 10 ? "%.0f" : "%.1f", value)) \(units[unitIndex])"
    }
}

// MARK: - Prompt Templates Management

private enum PromptTemplateManagementEditorMode: Identifiable {
    case create
    case edit(PromptTemplate)

    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let template):
            return template.id
        }
    }
}

private struct PromptTemplateEditorInput {
    let name: String
    let content: String
    let description: String?
    let variables: [PromptVariable]
    let defaultModelId: String?
    let defaultWebSearchMode: String?
    let defaultWebSearchProvider: String?
    let appendMode: PromptAppendMode
}

struct PromptTemplatesManagementView: View {
    @State private var templates: [PromptTemplate] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var editorMode: PromptTemplateManagementEditorMode?
    @State private var templatePendingDelete: PromptTemplate?
    @StateObject private var modelManager = ModelManager()

    var body: some View {
        List {
            Section {
                if isLoading {
                    ProgressView()
                } else if templates.isEmpty {
                    Text("No prompt templates yet.")
                        .foregroundStyle(Theme.Colors.textSecondary)
                } else {
                    ForEach(templates) { template in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(template.name)
                                    .font(.headline)
                                    .foregroundStyle(Theme.Colors.text)
                                Spacer()
                                Text((template.appendMode ?? .replace).rawValue.capitalized)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }

                            if let description = template.description, !description.isEmpty {
                                Text(description)
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }

                            Text(template.content)
                                .font(.caption2)
                                .foregroundStyle(Theme.Colors.textTertiary)
                                .lineLimit(3)

                            if let variables = template.variables, !variables.isEmpty {
                                Text(
                                    "\(variables.count) variable\(variables.count == 1 ? "" : "s")"
                                )
                                .font(.caption2)
                                .foregroundStyle(Theme.Colors.accent)
                            }
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .leading) {
                            Button {
                                editorMode = .edit(template)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                templatePendingDelete = template
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                }
            }
            .listRowBackground(Theme.Colors.sectionBackground)

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
                .listRowBackground(Theme.Colors.sectionBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.backgroundStart)
        .navigationTitle("Prompt Templates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editorMode = .create
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await modelManager.loadModels()
            await loadTemplates()
        }
        .refreshable {
            await loadTemplates()
        }
        .sheet(item: $editorMode) { mode in
            PromptTemplateEditorView(
                mode: mode,
                availableModels: modelManager.allModels.filter { $0.enabled },
                onSave: { input in
                    Task {
                        await saveTemplate(mode: mode, input: input)
                    }
                }
            )
        }
        .alert(
            "Delete Prompt Template",
            isPresented: Binding(
                get: { templatePendingDelete != nil },
                set: {
                    if !$0 { templatePendingDelete = nil }
                }
            ),
            actions: {
                Button("Cancel", role: .cancel) {
                    templatePendingDelete = nil
                }
                Button("Delete", role: .destructive) {
                    guard let template = templatePendingDelete else { return }
                    Task { await deleteTemplate(template) }
                }
            },
            message: {
                Text("This prompt template will be permanently deleted.")
            }
        )
    }

    private func loadTemplates() async {
        isLoading = true
        defer { isLoading = false }

        do {
            templates = try await NanoChatAPI.shared.getPrompts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveTemplate(
        mode: PromptTemplateManagementEditorMode, input: PromptTemplateEditorInput
    )
        async
    {
        do {
            switch mode {
            case .create:
                let request = CreatePromptTemplateRequest(
                    name: input.name,
                    content: input.content,
                    description: input.description,
                    variables: input.variables.isEmpty ? nil : input.variables,
                    defaultModelId: input.defaultModelId,
                    defaultWebSearchMode: input.defaultWebSearchMode,
                    defaultWebSearchProvider: input.defaultWebSearchProvider,
                    appendMode: input.appendMode
                )
                _ = try await NanoChatAPI.shared.createPrompt(request)
            case .edit(let template):
                let request = UpdatePromptTemplateRequest(
                    name: input.name,
                    content: input.content,
                    description: input.description,
                    variables: input.variables,
                    defaultModelId: input.defaultModelId,
                    defaultWebSearchMode: input.defaultWebSearchMode,
                    defaultWebSearchProvider: input.defaultWebSearchProvider,
                    appendMode: input.appendMode
                )
                try await NanoChatAPI.shared.updatePrompt(id: template.id, request: request)
            }

            await loadTemplates()
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    private func deleteTemplate(_ template: PromptTemplate) async {
        do {
            try await NanoChatAPI.shared.deletePrompt(id: template.id)
            templates.removeAll { $0.id == template.id }
            templatePendingDelete = nil
            errorMessage = nil
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}

private struct PromptTemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let mode: PromptTemplateManagementEditorMode
    let availableModels: [UserModel]
    let onSave: (PromptTemplateEditorInput) -> Void

    @State private var name: String
    @State private var content: String
    @State private var description: String
    @State private var appendMode: PromptAppendMode
    @State private var defaultModelId: String
    @State private var defaultWebSearchMode: String
    @State private var defaultWebSearchProvider: String
    @State private var variables: [PromptVariable]

    init(
        mode: PromptTemplateManagementEditorMode,
        availableModels: [UserModel],
        onSave: @escaping (PromptTemplateEditorInput) -> Void
    ) {
        self.mode = mode
        self.availableModels = availableModels
        self.onSave = onSave

        switch mode {
        case .create:
            _name = State(initialValue: "")
            _content = State(initialValue: "")
            _description = State(initialValue: "")
            _appendMode = State(initialValue: .replace)
            _defaultModelId = State(initialValue: "")
            _defaultWebSearchMode = State(initialValue: "")
            _defaultWebSearchProvider = State(initialValue: "")
            _variables = State(initialValue: [])
        case .edit(let template):
            _name = State(initialValue: template.name)
            _content = State(initialValue: template.content)
            _description = State(initialValue: template.description ?? "")
            _appendMode = State(initialValue: template.appendMode ?? .replace)
            _defaultModelId = State(initialValue: template.defaultModelId ?? "")
            _defaultWebSearchMode = State(initialValue: template.defaultWebSearchMode ?? "")
            _defaultWebSearchProvider = State(initialValue: template.defaultWebSearchProvider ?? "")
            _variables = State(initialValue: template.variables ?? [])
        }
    }

    private var hasValidInput: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    TextField("Name", text: $name)
                        .foregroundStyle(Theme.Colors.text)

                    TextField("Description (optional)", text: $description)
                        .foregroundStyle(Theme.Colors.text)

                    TextEditor(text: $content)
                        .frame(minHeight: 180)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .foregroundStyle(Theme.Colors.text)
                        .onChange(of: content) { _, _ in
                            syncVariablesFromContent()
                        }
                }
                .listRowBackground(Theme.Colors.sectionBackground)

                if !variables.isEmpty {
                    Section("Variables") {
                        ForEach(Array(variables.enumerated()), id: \.element.name) {
                            index,
                            variable in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(variable.name)
                                    .font(.headline)
                                    .foregroundStyle(Theme.Colors.text)

                                TextField(
                                    "Default value",
                                    text: Binding(
                                        get: { variable.defaultValue ?? "" },
                                        set: { newValue in
                                            updateVariable(
                                                at: index,
                                                defaultValue: newValue,
                                                description: variable.description
                                            )
                                        }
                                    )
                                )

                                TextField(
                                    "Description",
                                    text: Binding(
                                        get: { variable.description ?? "" },
                                        set: { newValue in
                                            updateVariable(
                                                at: index,
                                                defaultValue: variable.defaultValue,
                                                description: newValue
                                            )
                                        }
                                    )
                                )
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listRowBackground(Theme.Colors.sectionBackground)
                }

                Section("Defaults") {
                    Picker("Insert Mode", selection: $appendMode) {
                        ForEach(PromptAppendMode.allCases) { mode in
                            Text(mode.rawValue.capitalized).tag(mode)
                        }
                    }

                    Picker("Default Model", selection: $defaultModelId) {
                        Text("None").tag("")
                        ForEach(availableModels, id: \.id) { model in
                            Text(model.name ?? model.modelId).tag(model.modelId)
                        }
                    }

                    Picker("Web Search", selection: $defaultWebSearchMode) {
                        Text("None").tag("")
                        Text("Off").tag("off")
                        Text("Standard").tag("standard")
                        Text("Deep").tag("deep")
                    }

                    if defaultWebSearchMode != "" && defaultWebSearchMode != "off" {
                        Picker("Search Provider", selection: $defaultWebSearchProvider) {
                            Text("None").tag("")
                            ForEach(WebSearchProvider.allCases) { provider in
                                Text(provider.displayName).tag(provider.rawValue)
                            }
                        }
                    }
                }
                .listRowBackground(Theme.Colors.sectionBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.backgroundStart)
            .navigationTitle(mode.id == "create" ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let input = PromptTemplateEditorInput(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                            description: description.trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty
                                ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                            variables: variables,
                            defaultModelId: defaultModelId.isEmpty ? nil : defaultModelId,
                            defaultWebSearchMode: defaultWebSearchMode.isEmpty
                                ? nil : defaultWebSearchMode,
                            defaultWebSearchProvider:
                                defaultWebSearchMode.isEmpty || defaultWebSearchMode == "off"
                                || defaultWebSearchProvider.isEmpty
                                ? nil : defaultWebSearchProvider,
                            appendMode: appendMode
                        )
                        onSave(input)
                        dismiss()
                    }
                    .disabled(!hasValidInput)
                }
            }
        }
    }

    private func updateVariable(at index: Int, defaultValue: String?, description: String?) {
        guard variables.indices.contains(index) else { return }
        let current = variables[index]
        variables[index] = PromptVariable(
            name: current.name,
            defaultValue: defaultValue?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                == true
                ? nil : defaultValue?.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                == true
                ? nil : description?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func syncVariablesFromContent() {
        let detected = detectVariables(in: content)
        guard !detected.isEmpty || !variables.isEmpty else { return }

        let existingByName = Dictionary(uniqueKeysWithValues: variables.map { ($0.name, $0) })
        variables = detected.map { detectedVariable in
            if let existing = existingByName[detectedVariable.name] {
                return PromptVariable(
                    name: existing.name,
                    defaultValue: existing.defaultValue ?? detectedVariable.defaultValue,
                    description: existing.description
                )
            }
            return detectedVariable
        }
    }

    private func detectVariables(in text: String) -> [PromptVariable] {
        let pattern = #"\{\{\s*([a-zA-Z0-9_]+)(?::([^}]*))?\s*\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        var seen = Set<String>()
        var detected: [PromptVariable] = []

        for match in matches {
            guard match.numberOfRanges >= 2 else { continue }

            let nameRange = match.range(at: 1)
            guard nameRange.location != NSNotFound else { continue }
            let name = nsText.substring(with: nameRange).trimmingCharacters(
                in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            guard !seen.contains(name) else { continue }
            seen.insert(name)

            var defaultValue: String?
            let defaultRange = match.range(at: 2)
            if defaultRange.location != NSNotFound {
                let rawDefault = nsText.substring(with: defaultRange).trimmingCharacters(
                    in: .whitespacesAndNewlines)
                defaultValue = rawDefault.isEmpty ? nil : rawDefault
            }

            detected.append(
                PromptVariable(name: name, defaultValue: defaultValue, description: nil)
            )
        }

        return detected
    }
}

// MARK: - Scheduled Tasks Management

private enum ScheduledTaskManagementEditorMode: Identifiable {
    case create
    case edit(ScheduledTask)

    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let task):
            return task.id
        }
    }
}

private enum ScheduledTaskScheduleType: String, CaseIterable, Identifiable {
    case cron
    case interval
    case once

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cron:
            return "Cron"
        case .interval:
            return "Interval"
        case .once:
            return "One-time"
        }
    }
}

private enum ScheduledTaskIntervalUnit: String, CaseIterable, Identifiable {
    case minutes
    case hours
    case days

    var id: String { rawValue }

    var secondsMultiplier: Int {
        switch self {
        case .minutes:
            return 60
        case .hours:
            return 3600
        case .days:
            return 86400
        }
    }
}

private struct ScheduledTaskEditorInput {
    let name: String
    let description: String?
    let enabled: Bool
    let message: String
    let modelId: String
    let assistantId: String?
    let projectId: String?
    let webSearchMode: WebSearchMode
    let webSearchProvider: WebSearchProvider
    let webSearchContextSize: WebSearchContextSize
    let webSearchExaDepth: WebSearchExaDepth
    let webSearchKagiSource: WebSearchKagiSource
    let webSearchValyuSearchType: WebSearchValyuSearchType
    let reasoningEffort: String?
    let scheduleType: ScheduledTaskScheduleType
    let cronExpression: String
    let intervalValue: Int
    let intervalUnit: ScheduledTaskIntervalUnit
    let runAt: Date
}

struct ScheduledTasksManagementView: View {
    @StateObject private var modelManager = ModelManager()
    @State private var tasks: [ScheduledTask] = []
    @State private var assistants: [AssistantResponse] = []
    @State private var projects: [ProjectResponse] = []
    @State private var timezone = TimeZone.current.identifier
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var editorMode: ScheduledTaskManagementEditorMode?
    @State private var taskPendingDelete: ScheduledTask?

    var body: some View {
        List {
            Section("Timezone") {
                Text(timezone)
                    .foregroundStyle(Theme.Colors.text)
            }
            .listRowBackground(Theme.Colors.sectionBackground)

            Section {
                if isLoading {
                    ProgressView()
                } else if tasks.isEmpty {
                    Text("No scheduled tasks yet.")
                        .foregroundStyle(Theme.Colors.textSecondary)
                } else {
                    ForEach(tasks) { task in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(task.name)
                                    .font(.headline)
                                    .foregroundStyle(Theme.Colors.text)
                                Spacer()
                                Text(task.enabled ? "Enabled" : "Disabled")
                                    .font(.caption2)
                                    .foregroundStyle(
                                        task.enabled ? .green : Theme.Colors.textTertiary)
                            }

                            if let description = task.description, !description.isEmpty {
                                Text(description)
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }

                            Text(scheduleSummary(task))
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)

                            HStack(spacing: 10) {
                                Button(task.enabled ? "Disable" : "Enable") {
                                    Task { await toggleTaskEnabled(task) }
                                }
                                .buttonStyle(.bordered)

                                Button("Run Now") {
                                    Task { await runTaskNow(task) }
                                }
                                .buttonStyle(.bordered)
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .leading) {
                            Button {
                                editorMode = .edit(task)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                taskPendingDelete = task
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                }
            }
            .listRowBackground(Theme.Colors.sectionBackground)

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
                .listRowBackground(Theme.Colors.sectionBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.backgroundStart)
        .navigationTitle("Scheduled Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editorMode = .create
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await loadAll()
        }
        .refreshable {
            await loadAll()
        }
        .sheet(item: $editorMode) { mode in
            ScheduledTaskEditorView(
                mode: mode,
                enabledModels: modelManager.allModels.filter { $0.enabled },
                assistants: assistants,
                projects: projects,
                timezone: timezone,
                onSave: { input in
                    Task {
                        await saveTask(mode: mode, input: input)
                    }
                }
            )
        }
        .alert(
            "Delete Scheduled Task",
            isPresented: Binding(
                get: { taskPendingDelete != nil },
                set: { if !$0 { taskPendingDelete = nil } }
            ),
            actions: {
                Button("Cancel", role: .cancel) {
                    taskPendingDelete = nil
                }
                Button("Delete", role: .destructive) {
                    guard let task = taskPendingDelete else { return }
                    Task { await deleteTask(task) }
                }
            },
            message: {
                Text("This scheduled task will be permanently deleted.")
            }
        )
    }

    private func loadAll() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let modelLoad: Void = modelManager.loadModels()
            async let loadedTasks = NanoChatAPI.shared.getScheduledTasks()
            async let loadedAssistants = NanoChatAPI.shared.getAssistants()
            async let loadedProjects = NanoChatAPI.shared.getProjects()
            async let settings = NanoChatAPI.shared.getUserSettings()

            tasks = try await loadedTasks
            assistants = try await loadedAssistants
            projects = try await loadedProjects
            let loadedSettings = try await settings
            timezone = loadedSettings.timezone
            await modelLoad
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveTask(mode: ScheduledTaskManagementEditorMode, input: ScheduledTaskEditorInput)
        async
    {
        do {
            let schedule = buildSchedule(from: input)
            let payload = ScheduledTaskPayload(
                message: input.message,
                modelId: input.modelId,
                assistantId: input.assistantId,
                projectId: input.projectId,
                conversationId: nil,
                webSearchEnabled: input.webSearchMode != .off,
                webSearchMode: input.webSearchMode == .off ? nil : input.webSearchMode.rawValue,
                webSearchProvider: input.webSearchMode == .off
                    ? nil : input.webSearchProvider.rawValue,
                webSearchExaDepth: input.webSearchMode == .off || input.webSearchProvider != .exa
                    ? nil : input.webSearchExaDepth.rawValue,
                webSearchContextSize: input.webSearchMode == .off
                    ? nil : input.webSearchContextSize.rawValue,
                webSearchKagiSource: input.webSearchMode == .off || input.webSearchProvider != .kagi
                    ? nil : input.webSearchKagiSource.rawValue,
                webSearchValyuSearchType: input.webSearchMode == .off
                    || input.webSearchProvider != .valyu
                    ? nil : input.webSearchValyuSearchType.rawValue,
                reasoningEffort: input.reasoningEffort,
                providerId: nil,
                temporary: nil
            )

            switch mode {
            case .create:
                let request = CreateScheduledTaskRequest(
                    name: input.name,
                    description: input.description,
                    enabled: input.enabled,
                    schedule: schedule,
                    payload: payload
                )
                _ = try await NanoChatAPI.shared.createScheduledTask(request: request)
            case .edit(let task):
                let request = UpdateScheduledTaskRequest(
                    name: input.name,
                    description: input.description,
                    enabled: input.enabled,
                    schedule: schedule,
                    payload: payload
                )
                _ = try await NanoChatAPI.shared.updateScheduledTask(id: task.id, request: request)
            }

            await loadAll()
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    private func buildSchedule(from input: ScheduledTaskEditorInput) -> ScheduledTaskSchedule {
        switch input.scheduleType {
        case .cron:
            return ScheduledTaskSchedule(
                type: "cron",
                cron: input.cronExpression.trimmingCharacters(in: .whitespacesAndNewlines),
                intervalSeconds: nil,
                runAt: nil
            )
        case .interval:
            return ScheduledTaskSchedule(
                type: "interval",
                cron: nil,
                intervalSeconds: max(1, input.intervalValue) * input.intervalUnit.secondsMultiplier,
                runAt: nil
            )
        case .once:
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return ScheduledTaskSchedule(
                type: "once",
                cron: nil,
                intervalSeconds: nil,
                runAt: formatter.string(from: input.runAt)
            )
        }
    }

    private func toggleTaskEnabled(_ task: ScheduledTask) async {
        do {
            let request = UpdateScheduledTaskRequest(
                name: nil,
                description: nil,
                enabled: !task.enabled,
                schedule: nil,
                payload: nil
            )
            _ = try await NanoChatAPI.shared.updateScheduledTask(id: task.id, request: request)
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func runTaskNow(_ task: ScheduledTask) async {
        do {
            _ = try await NanoChatAPI.shared.runScheduledTaskNow(id: task.id)
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteTask(_ task: ScheduledTask) async {
        do {
            try await NanoChatAPI.shared.deleteScheduledTask(id: task.id)
            tasks.removeAll { $0.id == task.id }
            taskPendingDelete = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scheduleSummary(_ task: ScheduledTask) -> String {
        switch task.scheduleType {
        case "cron":
            return "Cron: \(task.cronExpression ?? "—")"
        case "interval":
            let seconds = task.intervalSeconds ?? 0
            if seconds % 86400 == 0 {
                return "Every \(max(1, seconds / 86400)) day(s)"
            }
            if seconds % 3600 == 0 {
                return "Every \(max(1, seconds / 3600)) hour(s)"
            }
            return "Every \(max(1, seconds / 60)) minute(s)"
        case "once":
            return "Once: \(formatDate(task.runAt))"
        default:
            return "Custom schedule"
        }
    }

    private func formatDate(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "—" }
        let formatters: [ISO8601DateFormatter] = {
            let withFraction = ISO8601DateFormatter()
            withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let basic = ISO8601DateFormatter()
            basic.formatOptions = [.withInternetDateTime]
            return [withFraction, basic]
        }()

        for formatter in formatters {
            if let date = formatter.date(from: value) {
                return date.formatted(date: .abbreviated, time: .shortened)
            }
        }

        return value
    }
}

private struct ScheduledTaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let mode: ScheduledTaskManagementEditorMode
    let enabledModels: [UserModel]
    let assistants: [AssistantResponse]
    let projects: [ProjectResponse]
    let timezone: String
    let onSave: (ScheduledTaskEditorInput) -> Void

    @State private var name: String
    @State private var description: String
    @State private var message: String
    @State private var modelId: String
    @State private var assistantId: String
    @State private var projectId: String
    @State private var webSearchMode: WebSearchMode
    @State private var webSearchProvider: WebSearchProvider
    @State private var webSearchContextSize: WebSearchContextSize
    @State private var webSearchExaDepth: WebSearchExaDepth
    @State private var webSearchKagiSource: WebSearchKagiSource
    @State private var webSearchValyuSearchType: WebSearchValyuSearchType
    @State private var reasoningEffortRaw: String
    @State private var enabled: Bool
    @State private var scheduleType: ScheduledTaskScheduleType
    @State private var cronExpression: String
    @State private var intervalValue: Int
    @State private var intervalUnit: ScheduledTaskIntervalUnit
    @State private var runAt: Date

    init(
        mode: ScheduledTaskManagementEditorMode,
        enabledModels: [UserModel],
        assistants: [AssistantResponse],
        projects: [ProjectResponse],
        timezone: String,
        onSave: @escaping (ScheduledTaskEditorInput) -> Void
    ) {
        self.mode = mode
        self.enabledModels = enabledModels
        self.assistants = assistants
        self.projects = projects
        self.timezone = timezone
        self.onSave = onSave

        switch mode {
        case .create:
            _name = State(initialValue: "")
            _description = State(initialValue: "")
            _message = State(initialValue: "")
            _modelId = State(initialValue: enabledModels.first?.modelId ?? "")
            _assistantId = State(initialValue: "")
            _projectId = State(initialValue: "")
            _webSearchMode = State(initialValue: .off)
            _webSearchProvider = State(initialValue: .linkup)
            _webSearchContextSize = State(initialValue: .medium)
            _webSearchExaDepth = State(initialValue: .auto)
            _webSearchKagiSource = State(initialValue: .web)
            _webSearchValyuSearchType = State(initialValue: .all)
            _reasoningEffortRaw = State(initialValue: "")
            _enabled = State(initialValue: true)
            _scheduleType = State(initialValue: .cron)
            _cronExpression = State(initialValue: "0 9 * * *")
            _intervalValue = State(initialValue: 60)
            _intervalUnit = State(initialValue: .minutes)
            _runAt = State(initialValue: Date().addingTimeInterval(3600))
        case .edit(let task):
            _name = State(initialValue: task.name)
            _description = State(initialValue: task.description ?? "")
            _message = State(initialValue: task.payload.message ?? "")
            _modelId = State(initialValue: task.payload.modelId)
            _assistantId = State(initialValue: task.payload.assistantId ?? "")
            _projectId = State(initialValue: task.payload.projectId ?? "")
            _webSearchMode = State(
                initialValue: WebSearchMode(rawValue: task.payload.webSearchMode ?? "off") ?? .off
            )
            _webSearchProvider = State(
                initialValue: WebSearchProvider(
                    rawValue: task.payload.webSearchProvider ?? "linkup")
                    ?? .linkup
            )
            _webSearchContextSize = State(
                initialValue: WebSearchContextSize(
                    rawValue: task.payload.webSearchContextSize ?? "medium")
                    ?? .medium
            )
            _webSearchExaDepth = State(
                initialValue: WebSearchExaDepth(rawValue: task.payload.webSearchExaDepth ?? "auto")
                    ?? .auto
            )
            _webSearchKagiSource = State(
                initialValue: WebSearchKagiSource(
                    rawValue: task.payload.webSearchKagiSource ?? "web")
                    ?? .web
            )
            _webSearchValyuSearchType = State(
                initialValue: WebSearchValyuSearchType(
                    rawValue: task.payload.webSearchValyuSearchType ?? "all"
                ) ?? .all
            )
            _reasoningEffortRaw = State(initialValue: task.payload.reasoningEffort ?? "")
            _enabled = State(initialValue: task.enabled)
            _scheduleType = State(
                initialValue: ScheduledTaskScheduleType(rawValue: task.scheduleType) ?? .cron
            )
            _cronExpression = State(initialValue: task.cronExpression ?? "0 9 * * *")

            let seconds = max(60, task.intervalSeconds ?? 60)
            if seconds % 86400 == 0 {
                _intervalUnit = State(initialValue: .days)
                _intervalValue = State(initialValue: max(1, seconds / 86400))
            } else if seconds % 3600 == 0 {
                _intervalUnit = State(initialValue: .hours)
                _intervalValue = State(initialValue: max(1, seconds / 3600))
            } else {
                _intervalUnit = State(initialValue: .minutes)
                _intervalValue = State(initialValue: max(1, seconds / 60))
            }

            _runAt = State(
                initialValue: Self.parseISODate(task.runAt) ?? Date().addingTimeInterval(3600))
        }
    }

    private var hasValidInput: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !modelId.isEmpty
            && (scheduleType != .cron
                || !cronExpression.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Name", text: $name)
                    TextField("Description (optional)", text: $description)
                    TextEditor(text: $message)
                        .frame(minHeight: 130)
                }
                .listRowBackground(Theme.Colors.sectionBackground)

                Section("Generation") {
                    Picker("Model", selection: $modelId) {
                        ForEach(enabledModels, id: \.id) { model in
                            Text(model.name ?? model.modelId).tag(model.modelId)
                        }
                    }

                    Picker("Assistant", selection: $assistantId) {
                        Text("None").tag("")
                        ForEach(assistants, id: \.id) { assistant in
                            Text(assistant.name).tag(assistant.id)
                        }
                    }

                    Picker("Project", selection: $projectId) {
                        Text("None").tag("")
                        ForEach(projects, id: \.id) { project in
                            Text(project.name).tag(project.id)
                        }
                    }

                    Picker("Web Search", selection: $webSearchMode) {
                        ForEach(WebSearchMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }

                    if webSearchMode != .off {
                        Picker("Search Provider", selection: $webSearchProvider) {
                            ForEach(WebSearchProvider.allCases) { provider in
                                Text(provider.displayName).tag(provider)
                            }
                        }

                        Picker("Context Size", selection: $webSearchContextSize) {
                            ForEach(WebSearchContextSize.allCases) { size in
                                Text(size.displayName).tag(size)
                            }
                        }

                        if webSearchProvider == .exa {
                            Picker("Exa Depth", selection: $webSearchExaDepth) {
                                ForEach(WebSearchExaDepth.allCases) { depth in
                                    Text(depth.displayName).tag(depth)
                                }
                            }
                        }

                        if webSearchProvider == .kagi {
                            Picker("Kagi Source", selection: $webSearchKagiSource) {
                                ForEach(WebSearchKagiSource.allCases) { source in
                                    Text(source.displayName).tag(source)
                                }
                            }
                        }

                        if webSearchProvider == .valyu {
                            Picker("Valyu Search Type", selection: $webSearchValyuSearchType) {
                                ForEach(WebSearchValyuSearchType.allCases) { searchType in
                                    Text(searchType.displayName).tag(searchType)
                                }
                            }
                        }
                    }

                    Picker("Reasoning", selection: $reasoningEffortRaw) {
                        Text("Default").tag("")
                        ForEach(ReasoningEffort.allCases) { effort in
                            Text(effort.displayName).tag(effort.rawValue)
                        }
                    }
                }
                .listRowBackground(Theme.Colors.sectionBackground)

                Section("Schedule") {
                    Text("Times run in \(timezone)")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Picker("Type", selection: $scheduleType) {
                        ForEach(ScheduledTaskScheduleType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }

                    if scheduleType == .cron {
                        TextField("Cron Expression", text: $cronExpression)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else if scheduleType == .interval {
                        Stepper(
                            value: $intervalValue,
                            in: 1...100000
                        ) {
                            Text("Every \(intervalValue)")
                        }
                        Picker("Unit", selection: $intervalUnit) {
                            ForEach(ScheduledTaskIntervalUnit.allCases) { unit in
                                Text(unit.rawValue.capitalized).tag(unit)
                            }
                        }
                    } else {
                        DatePicker(
                            "Run At",
                            selection: $runAt,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }

                    Toggle("Enabled", isOn: $enabled)
                        .tint(Theme.Colors.accent)
                }
                .listRowBackground(Theme.Colors.sectionBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.backgroundStart)
            .navigationTitle(mode.id == "create" ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let input = ScheduledTaskEditorInput(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            description: description.trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty
                                ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                            enabled: enabled,
                            message: message.trimmingCharacters(in: .whitespacesAndNewlines),
                            modelId: modelId,
                            assistantId: assistantId.isEmpty ? nil : assistantId,
                            projectId: projectId.isEmpty ? nil : projectId,
                            webSearchMode: webSearchMode,
                            webSearchProvider: webSearchProvider,
                            webSearchContextSize: webSearchContextSize,
                            webSearchExaDepth: webSearchExaDepth,
                            webSearchKagiSource: webSearchKagiSource,
                            webSearchValyuSearchType: webSearchValyuSearchType,
                            reasoningEffort: reasoningEffortRaw.isEmpty ? nil : reasoningEffortRaw,
                            scheduleType: scheduleType,
                            cronExpression: cronExpression,
                            intervalValue: intervalValue,
                            intervalUnit: intervalUnit,
                            runAt: runAt
                        )
                        onSave(input)
                        dismiss()
                    }
                    .disabled(!hasValidInput)
                }
            }
        }
    }

    private static func parseISODate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: value) { return date }
        let basic = ISO8601DateFormatter()
        basic.formatOptions = [.withInternetDateTime]
        return basic.date(from: value)
    }
}

// MARK: - Customization Tools

private enum UserRuleManagementEditorMode: Identifiable {
    case create
    case edit(UserRule)

    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let rule):
            return rule.id
        }
    }
}

private struct UserRuleEditorInput {
    let name: String
    let attach: UserRuleAttachMode
    let rule: String
}

struct CustomizationToolsView: View {
    @State private var rules: [UserRule] = []
    @State private var isLoadingRules = false
    @State private var errorMessage: String?
    @State private var editorMode: UserRuleManagementEditorMode?
    @State private var rulePendingDelete: UserRule?
    @StateObject private var modelManager = ModelManager()

    @State private var searchForwardModelId = ""
    @State private var searchForwardMode: WebSearchMode = .off
    @State private var searchForwardProvider: WebSearchProvider = .linkup

    private var searchForwardURL: String {
        let baseURL = APIConfiguration.shared.baseURL.trimmingCharacters(
            in: CharacterSet(charactersIn: "/"))
        var components: [String] = []
        if !searchForwardModelId.isEmpty {
            components.append(
                "model=\(searchForwardModelId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchForwardModelId)"
            )
        }
        components.append("search=\(searchForwardMode.rawValue)")
        if searchForwardMode != .off {
            components.append("search_provider=\(searchForwardProvider.rawValue)")
        }
        components.append("q=%s")
        return "\(baseURL)/chat?\(components.joined(separator: "&"))"
    }

    var body: some View {
        List {
            Section("Search Forwarding URL") {
                Picker("Model", selection: $searchForwardModelId) {
                    ForEach(modelManager.allModels.filter { $0.enabled }, id: \.id) { model in
                        Text(model.name ?? model.modelId).tag(model.modelId)
                    }
                }

                Picker("Search Mode", selection: $searchForwardMode) {
                    ForEach(WebSearchMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                Picker("Search Provider", selection: $searchForwardProvider) {
                    ForEach(WebSearchProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .disabled(searchForwardMode == .off)

                Text(searchForwardURL)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
                    .foregroundStyle(Theme.Colors.text)

                Button("Copy URL") {
                    UIPasteboard.general.string = searchForwardURL
                    HapticManager.shared.success()
                }
            }
            .listRowBackground(Theme.Colors.sectionBackground)

            Section {
                if isLoadingRules {
                    ProgressView()
                } else if rules.isEmpty {
                    Text("No user rules yet.")
                        .foregroundStyle(Theme.Colors.textSecondary)
                } else {
                    ForEach(rules) { rule in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(rule.name)
                                    .font(.headline)
                                    .foregroundStyle(Theme.Colors.text)
                                Spacer()
                                Text(rule.attach.rawValue.capitalized)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                            Text(rule.rule)
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .lineLimit(3)
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .leading) {
                            Button {
                                editorMode = .edit(rule)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                rulePendingDelete = rule
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Rules")
                    Spacer()
                    Button {
                        editorMode = .create
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                }
            }
            .listRowBackground(Theme.Colors.sectionBackground)

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
                .listRowBackground(Theme.Colors.sectionBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.backgroundStart)
        .navigationTitle("Customization")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await modelManager.loadModels()
            await loadRules()
            loadSearchForwardDefaults()
        }
        .onChange(of: searchForwardModelId) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: "searchForwardModelId")
        }
        .onChange(of: searchForwardMode) { _, newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: "searchForwardMode")
        }
        .onChange(of: searchForwardProvider) { _, newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: "searchForwardProvider")
        }
        .sheet(item: $editorMode) { mode in
            UserRuleEditorView(mode: mode) { input in
                Task {
                    await saveRule(mode: mode, input: input)
                }
            }
        }
        .alert(
            "Delete Rule",
            isPresented: Binding(
                get: { rulePendingDelete != nil },
                set: { if !$0 { rulePendingDelete = nil } }
            ),
            actions: {
                Button("Cancel", role: .cancel) {
                    rulePendingDelete = nil
                }
                Button("Delete", role: .destructive) {
                    guard let rule = rulePendingDelete else { return }
                    Task { await deleteRule(rule) }
                }
            },
            message: {
                Text("This rule will be permanently deleted.")
            }
        )
    }

    private func loadSearchForwardDefaults() {
        let enabledModels = modelManager.allModels.filter { $0.enabled }
        let savedModelId = UserDefaults.standard.string(forKey: "searchForwardModelId")
        searchForwardModelId =
            enabledModels.first(where: { $0.modelId == savedModelId })?.modelId
            ?? enabledModels.first?.modelId ?? ""

        if let savedMode = UserDefaults.standard.string(forKey: "searchForwardMode"),
            let mode = WebSearchMode(rawValue: savedMode)
        {
            searchForwardMode = mode
        }

        if let savedProvider = UserDefaults.standard.string(forKey: "searchForwardProvider"),
            let provider = WebSearchProvider(rawValue: savedProvider)
        {
            searchForwardProvider = provider
        }
    }

    private func loadRules() async {
        isLoadingRules = true
        defer { isLoadingRules = false }

        do {
            rules = try await NanoChatAPI.shared.getUserRules()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveRule(mode: UserRuleManagementEditorMode, input: UserRuleEditorInput) async {
        do {
            switch mode {
            case .create:
                _ = try await NanoChatAPI.shared.createUserRule(
                    name: input.name,
                    attach: input.attach,
                    rule: input.rule
                )
            case .edit(let existing):
                if existing.name != input.name {
                    _ = try await NanoChatAPI.shared.renameUserRule(
                        id: existing.id, name: input.name)
                }
                _ = try await NanoChatAPI.shared.updateUserRule(
                    id: existing.id,
                    attach: input.attach,
                    rule: input.rule
                )
            }

            await loadRules()
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    private func deleteRule(_ rule: UserRule) async {
        do {
            try await NanoChatAPI.shared.deleteUserRule(id: rule.id)
            rules.removeAll { $0.id == rule.id }
            rulePendingDelete = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct UserRuleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let mode: UserRuleManagementEditorMode
    let onSave: (UserRuleEditorInput) -> Void

    @State private var name: String
    @State private var attach: UserRuleAttachMode
    @State private var ruleText: String

    init(mode: UserRuleManagementEditorMode, onSave: @escaping (UserRuleEditorInput) -> Void) {
        self.mode = mode
        self.onSave = onSave

        switch mode {
        case .create:
            _name = State(initialValue: "")
            _attach = State(initialValue: .always)
            _ruleText = State(initialValue: "")
        case .edit(let rule):
            _name = State(initialValue: rule.name)
            _attach = State(initialValue: rule.attach)
            _ruleText = State(initialValue: rule.rule)
        }
    }

    private var hasValidInput: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !ruleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Rule") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $attach) {
                        ForEach(UserRuleAttachMode.allCases) { mode in
                            Text(mode.rawValue.capitalized).tag(mode)
                        }
                    }
                    TextEditor(text: $ruleText)
                        .frame(minHeight: 170)
                }
                .listRowBackground(Theme.Colors.sectionBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.backgroundStart)
            .navigationTitle(mode.id == "create" ? "New Rule" : "Edit Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let input = UserRuleEditorInput(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            attach: attach,
                            rule: ruleText.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        onSave(input)
                        dismiss()
                    }
                    .disabled(!hasValidInput)
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
