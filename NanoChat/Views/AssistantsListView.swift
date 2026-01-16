import SwiftUI

struct AssistantsListView: View {
    @State private var assistants: [AssistantResponse] = []
    @State private var isLoading = false
    @State private var showingNewAssistant = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && assistants.isEmpty {
                    ProgressView()
                } else if assistants.isEmpty {
                    ContentUnavailableView {
                        Label("No Assistants", systemImage: "person.2")
                    } description: {
                        Text("Create assistants to customize your AI experience")
                    } actions: {
                        Button("Create Assistant") {
                            showingNewAssistant = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(assistants, id: \.id) { assistant in
                            NavigationLink {
                                AssistantDetailView(assistant: assistant)
                            } label: {
                                AssistantRow(assistant: assistant)
                            }
                            .swipeActions(edge: .leading) {
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
                                .tint(.orange)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Assistants")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewAssistant = true }) {
                        Image(systemName: "plus")
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
            Circle()
                .fill(Theme.Colors.secondary.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.Colors.secondary)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(assistant.name)
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.text)
                        .lineLimit(1)

                    Spacer()

                    if assistant.isDefault {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                if let description = assistant.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Text(assistant.systemPrompt)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AssistantDetailView: View {
    let assistant: AssistantResponse

    var body: some View {
        List {
            Section("Name") {
                Text(assistant.name)
                    .font(.headline)
                if let description = assistant.description {
                    Text(description)
                        .foregroundStyle(.secondary)
                }
            }

            Section("System Prompt") {
                Text(assistant.systemPrompt)
                    .font(.body)
                    .foregroundStyle(Theme.Colors.text)
                    .textSelection(.enabled)
            }

            Section("Settings") {
                if let modelId = assistant.defaultModelId {
                    LabeledContent("Default Model", value: modelId)
                }
                if let webSearchMode = assistant.defaultWebSearchMode {
                    LabeledContent("Web Search", value: webSearchMode)
                }
                LabeledContent("Default", value: assistant.isDefault ? "Yes" : "No")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Gradients.background)
        .navigationTitle(assistant.name)
        .navigationBarTitleDisplayMode(.inline)
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
                Section("Details") {
                    TextField("Name", text: $name)
                        .foregroundStyle(Theme.Colors.text)
                    TextField("Description (optional)", text: $description)
                        .foregroundStyle(Theme.Colors.text)
                }

                Section(header: Text("System Prompt"), footer: Text("Define the assistant's behavior and personality")) {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 150)
                        .foregroundStyle(Theme.Colors.text)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                }

                Section("Configuration") {
                    Picker("Model", selection: $defaultModelId) {
                        Text("GPT-4").tag("gpt-4")
                        Text("GPT-4 Turbo").tag("gpt-4-turbo")
                        Text("Claude 3.5 Sonnet").tag("claude-3.5-sonnet")
                    }

                    Picker("Web Search", selection: $defaultWebSearchMode) {
                        Text("Off").tag("off")
                        Text("Standard").tag("standard")
                        Text("Deep").tag("deep")
                    }
                }
            }
            .navigationTitle("New Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
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
                    .disabled(name.isEmpty || systemPrompt.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AssistantsListView()
}
