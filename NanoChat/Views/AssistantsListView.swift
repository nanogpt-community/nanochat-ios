import SwiftUI

struct AssistantsListView: View {
    @State private var assistants: [AssistantResponse] = []
    @State private var isLoading = false
    @State private var showingNewAssistant = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Theme.Gradients.background
                .ignoresSafeArea()

            // Subtle glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.Colors.primary.opacity(0.12), .clear],
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: 350
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: 100, y: 100)
                .ignoresSafeArea()

            NavigationStack {
                Group {
                    if isLoading && assistants.isEmpty {
                        AssistantsListSkeleton()
                            .transition(.opacity)
                    } else if assistants.isEmpty {
                        ContentUnavailableView {
                            Label("No Assistants", systemImage: "person.2")
                                .foregroundStyle(Theme.Colors.textSecondary)
                        } description: {
                            Text("Create assistants to customize your AI experience")
                                .foregroundStyle(Theme.Colors.textTertiary)
                        } actions: {
                            Button("Create Assistant") {
                                showingNewAssistant = true
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    } else {
                        List {
                            ForEach(assistants, id: \.id) { assistant in
                                NavigationLink {
                                    AssistantDetailView(assistant: assistant)
                                } label: {
                                    AssistantRow(assistant: assistant)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: Theme.Spacing.xs, leading: Theme.Spacing.lg, bottom: Theme.Spacing.xs, trailing: Theme.Spacing.lg))
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        HapticManager.shared.tap()
                                        Task {
                                            await setDefaultAssistant(assistant)
                                        }
                                    } label: {
                                        Label(
                                            assistant.isDefault ? "Unset Default" : "Set Default",
                                            systemImage: assistant.isDefault ? "star.slash.fill" : "star.fill"
                                        )
                                    }
                                    .tint(Theme.Colors.warning)
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("Assistants")
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showingNewAssistant = true }) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Gradients.primary)
                                    .frame(width: 36, height: 36)
                                    .shadow(color: Theme.Colors.primary.opacity(0.4), radius: 6, x: 0, y: 3)

                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingNewAssistant) {
                    NewAssistantView { assistant in
                        Task {
                            await createAssistant(assistant)
                        }
                    }
                    .presentationDetents([.large])
                    .presentationBackground(.ultraThinMaterial)
                }
                .task {
                    await loadAssistants()
                }
                .refreshable {
                    await loadAssistants()
                }
                .alert("Error", isPresented: .constant(errorMessage != nil)) {
                    Button("OK") {
                        errorMessage = nil
                    }
                } message: {
                    if let error = errorMessage {
                        Text(error)
                    }
                }
            }
        }
    }

    private func loadAssistants() async {
        isLoading = true
        defer { isLoading = false }

        do {
            assistants = try await NanoChatAPI.shared.getAssistants()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createAssistant(_ assistant: CreateAssistantRequest) async {
        do {
            let newAssistant = try await NanoChatAPI.shared.createAssistant(
                name: assistant.name,
                systemPrompt: assistant.systemPrompt,
                defaultModelId: assistant.defaultModelId,
                defaultWebSearchMode: assistant.defaultWebSearchMode
            )
            HapticManager.shared.success()
            assistants.append(newAssistant)
        } catch {
            HapticManager.shared.error()
            errorMessage = error.localizedDescription
        }
    }
    
    private func setDefaultAssistant(_ assistant: AssistantResponse) async {
        // TODO: Implement set default API call when available
        HapticManager.shared.success()
    }
}

struct AssistantRow: View {
    let assistant: AssistantResponse

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.secondary, Theme.Colors.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(assistant.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.Colors.text)
                        .lineLimit(1)

                    Spacer()

                    if assistant.isDefault {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondary)
                    }
                }

                if let description = assistant.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(2)
                }

                Text(assistant.systemPrompt)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(Theme.Spacing.md)
        .glassCard()
    }
}

struct AssistantDetailView: View {
    let assistant: AssistantResponse

    var body: some View {
        List {
            Section {
                Text(assistant.name)
                    .foregroundStyle(Theme.Colors.text)
                if let description = assistant.description {
                    Text(description)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            } header: {
                Text("Name")
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Section {
                Text(assistant.systemPrompt)
                    .font(.body)
                    .foregroundStyle(Theme.Colors.text)
                    .textSelection(.enabled)
            } header: {
                Text("System Prompt")
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Section {
                if let modelId = assistant.defaultModelId {
                    LabeledContent("Default Model", value: modelId)
                }
                if let webSearchMode = assistant.defaultWebSearchMode {
                    LabeledContent("Web Search", value: webSearchMode)
                }
                LabeledContent("Default", value: assistant.isDefault ? "Yes" : "No")
            } header: {
                Text("Settings")
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Gradients.background)
        .navigationTitle(assistant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct NewAssistantView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var systemPrompt = ""
    @State private var description = ""
    @State private var defaultModelId = "gpt-4"
    @State private var defaultWebSearchMode = "off"

    let onCreate: (CreateAssistantRequest) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .foregroundStyle(Theme.Colors.text)
                    TextField("Description (optional)", text: $description)
                        .foregroundStyle(Theme.Colors.text)
                } header: {
                    Text("Details")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Section {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 150)
                        .foregroundStyle(Theme.Colors.text)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                } header: {
                    Text("System Prompt")
                        .foregroundStyle(Theme.Colors.textSecondary)
                } footer: {
                    Text("Define the assistant's behavior and personality")
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                Section {
                    Picker("Model", selection: $defaultModelId) {
                        Text("GPT-4").tag("gpt-4")
                        Text("GPT-4 Turbo").tag("gpt-4-turbo")
                        Text("Claude 3.5 Sonnet").tag("claude-3.5-sonnet")
                    }
                    .foregroundStyle(Theme.Colors.text)

                    Picker("Web Search", selection: $defaultWebSearchMode) {
                        Text("Off").tag("off")
                        Text("Standard").tag("standard")
                        Text("Deep").tag("deep")
                    }
                    .foregroundStyle(Theme.Colors.text)
                } header: {
                    Text("Configuration")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("New Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let request = CreateAssistantRequest(
                            name: name,
                            systemPrompt: systemPrompt,
                            defaultModelId: defaultModelId.isEmpty ? nil : defaultModelId,
                            defaultWebSearchMode: defaultWebSearchMode == "off" ? nil : defaultWebSearchMode,
                            defaultWebSearchProvider: nil
                        )
                        onCreate(request)
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.secondary)
                    .disabled(name.isEmpty || systemPrompt.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AssistantsListView()
        .preferredColorScheme(.dark)
}
