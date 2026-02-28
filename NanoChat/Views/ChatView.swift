import AVKit
import SwiftUI
import UIKit

struct ChatView: View {
    let conversation: ConversationResponse
    // Add binding for sidebar state
    @Binding var showSidebar: Bool
    // Add callback for new chat
    var onNewChat: (() -> Void)?
    var isPushed: Bool  // Add this property

    let onMessageSent: (() -> Void)?
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var modelManager = ModelManager()
    @StateObject private var multiSelectViewModel = MultiSelectViewModel<MessageResponse>()
    @ObservedObject private var audioPreferences = AudioPreferences.shared
    @StateObject private var audioPlayback = AudioPlaybackManager.shared
    @State private var assistantManager = AssistantManager()
    @State private var messageText = ""
    @State private var showVoiceRecorder = false
    @State private var voiceErrorMessage: String?
    @FocusState private var isInputFocused: Bool
    @State private var webSearchMode: WebSearchMode = .off
    @State private var webSearchProvider: WebSearchProvider = .linkup
    @State private var webSearchExaDepth: WebSearchExaDepth = .auto
    @State private var webSearchContextSize: WebSearchContextSize = .medium
    @State private var webSearchKagiSource: WebSearchKagiSource = .web
    @State private var webSearchValyuSearchType: WebSearchValyuSearchType = .all
    @State private var reasoningEffort: ReasoningEffort = .low
    @State private var temporaryMode = false
    @State private var selectedImages: [Data] = []
    @State private var selectedDocuments: [URL] = []
    @State private var isUploading = false
    @State private var showProviderPicker = false
    @State private var showModelPicker = false

    @State private var showImageSettings = false
    @State private var showVideoSettings = false
    @State private var searchText = ""
    @State private var messageSearchMode: ConversationSearchMode = .words
    @State private var isSearchVisible = false
    @State private var selectedDocument: MessageDocumentResponse?
    @State private var showAssistantPicker = false
    @State private var shouldAutoScrollToBottom = true
    @State private var conversationIsPublic = false
    @State private var isUpdatingConversationVisibility = false
    @State private var showPromptTemplates = false
    @State private var showPromptVariables = false
    @State private var isLoadingPromptTemplates = false
    @State private var isEnhancingPrompt = false
    @State private var promptTemplates: [PromptTemplate] = []
    @State private var selectedPromptTemplate: PromptTemplate?
    @State private var promptVariableValues: [String: String] = [:]

    @Environment(\.dismiss) private var dismiss  // For back button behavior
    @Environment(\.colorScheme) private var colorScheme

    private var isWebSearchEnabled: Bool {
        webSearchMode != .off
    }

    private var activeConversationId: String {
        viewModel.currentConversation?.id ?? conversation.id
    }

    // Initializer to support optional callbacks for backward compatibility
    init(
        conversation: ConversationResponse,
        showSidebar: Binding<Bool> = .constant(false),
        onNewChat: (() -> Void)? = nil,
        onMessageSent: (() -> Void)? = nil,
        isPushed: Bool = false
    ) {
        self.conversation = conversation
        self._showSidebar = showSidebar
        self.onNewChat = onNewChat
        self.onMessageSent = onMessageSent
        self.isPushed = isPushed
    }

    var body: some View {
        ZStack {
            // Background is handled by parent RootView, but we can keep a transparent one
            // or subtle gradient if we want to differentiate.
            Color.clear

            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    // Custom Header
                    chatHeader

                    if isSearchVisible {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Theme.Colors.textSecondary)
                            TextField("Search in chat...", text: $searchText)
                                .textFieldStyle(.plain)
                                .foregroundStyle(Theme.Colors.text)

                            Menu {
                                Picker("Search Mode", selection: $messageSearchMode) {
                                    ForEach(ConversationSearchMode.allCases) { mode in
                                        Text(mode.displayName).tag(mode)
                                    }
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }

                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }
                            }
                        }
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.glassBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    messagesView(proxy: proxy)
                        .contentShape(Rectangle())
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                isInputFocused = false
                            })
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 0) {
                        if multiSelectViewModel.isEditMode && multiSelectViewModel.hasSelection {
                            messageBatchOperationsBar
                        }
                        inputArea
                    }
                }
                .toolbar(.hidden)  // Hide default navigation bar
                .onAppear {
                    Task {
                        await loadData()
                    }
                }
                .onChange(of: viewModel.currentConversation?.isPublic) { _, newValue in
                    if let newValue {
                        conversationIsPublic = newValue
                    }
                }
                .onChange(of: viewModel.messages) { _, newValue in
                    multiSelectViewModel.items = newValue
                    multiSelectViewModel.selectedItems = multiSelectViewModel.selectedItems
                        .intersection(Set(newValue.map { $0.id }))
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    guard shouldAutoScrollToBottom else { return }
                    scrollToLastMessage(proxy: proxy)
                }
                .onChange(of: modelManager.selectedModel?.modelId) { _, newValue in
                    if let modelId = newValue {
                        Task {
                            await viewModel.fetchModelProviders(modelId: modelId)
                            // Restore last used provider for this model
                            if let lastProvider = modelManager.getLastProvider(for: modelId) {
                                // Verify this provider is still available for this model
                                if viewModel.availableProviders.contains(where: {
                                    $0.provider == lastProvider
                                }) {
                                    viewModel.selectProvider(providerId: lastProvider)
                                }
                            }
                        }
                    }
                }
                .onChange(of: assistantManager.selectedAssistant?.id) { _, _ in
                    Task {
                        await applyAssistantDefaults()
                    }
                }
            }
        }
        .overlay(pickerOverlays)
        .sheet(isPresented: $showVoiceRecorder) {
            VoiceRecorderSheet(
                audioPreferences: audioPreferences,
                onTranscription: { transcription in
                    handleTranscription(transcription)
                },
                onError: { message in
                    voiceErrorMessage = message
                }
            )
        }
        .sheet(
            item: Binding<PreviewDocumentItem?>(
                get: { selectedDocument.map { PreviewDocumentItem(document: $0) } },
                set: { if $0 == nil { selectedDocument = nil } }
            )
        ) { item in
            DocumentPreviewView(document: item.document) {
                selectedDocument = nil
            }
        }
        .alert(
            "Audio Error",
            isPresented: Binding(
                get: { voiceErrorMessage != nil },
                set: { if !$0 { voiceErrorMessage = nil } }
            )
        ) {
            Button("OK") {
                voiceErrorMessage = nil
            }
        } message: {
            Text(voiceErrorMessage ?? "")
        }
        .sheet(isPresented: $showPromptTemplates) {
            PromptTemplatePickerView(
                templates: promptTemplates,
                isLoading: isLoadingPromptTemplates,
                onRefresh: { Task { await loadPromptTemplates() } },
                onApply: { template in
                    handlePromptTemplateSelection(template)
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPromptVariables) {
            if let selectedPromptTemplate {
                PromptVariableValuesView(
                    template: selectedPromptTemplate,
                    values: $promptVariableValues,
                    onApply: {
                        applyPromptTemplate(selectedPromptTemplate, with: promptVariableValues)
                        showPromptVariables = false
                    },
                    onCancel: { showPromptVariables = false }
                )
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var chatHeader: some View {
        HStack(spacing: Theme.scaled(12)) {
            if multiSelectViewModel.isEditMode {
                // Edit mode header
                Button {
                    multiSelectViewModel.exitEditMode()
                } label: {
                    Text("Cancel")
                        .font(Theme.font(size: 16))
                        .foregroundStyle(Theme.Colors.accent)
                }

                Spacer()

                Text(multiSelectViewModel.selectionDescription)
                    .font(Theme.font(size: 15, weight: .medium))
                    .foregroundStyle(Theme.Colors.text)

                Spacer()

                Button {
                    multiSelectViewModel.toggleSelectAll()
                } label: {
                    Text(multiSelectViewModel.isAllSelected ? "Deselect All" : "Select All")
                        .font(Theme.font(size: 16))
                        .foregroundStyle(Theme.Colors.accent)
                }
            } else if isPushed {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(Theme.font(size: 18, weight: .medium))
                        .foregroundStyle(Theme.Colors.text)
                }

                Spacer()

                // Model Selector Pill
                modelSelectorPill

                Spacer()

                // More menu with edit option
                Menu {
                    Button {
                        multiSelectViewModel.enterEditMode()
                    } label: {
                        Label("Select Messages", systemImage: "checkmark.circle")
                    }

                    Button {
                        withAnimation { isSearchVisible.toggle() }
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }

                    Button {
                        Task {
                            await loadPromptTemplates()
                            showPromptTemplates = true
                        }
                    } label: {
                        Label("Prompt Templates", systemImage: "text.badge.plus")
                    }

                    Button {
                        enhanceCurrentPrompt()
                    } label: {
                        Label(
                            isEnhancingPrompt ? "Enhancing..." : "Enhance Prompt",
                            systemImage: "wand.and.stars"
                        )
                    }
                    .disabled(
                        isEnhancingPrompt
                            || messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        toggleConversationPublic()
                    } label: {
                        Label(
                            conversationIsPublic ? "Disable Public Link" : "Enable Public Link",
                            systemImage: conversationIsPublic ? "lock.fill" : "globe"
                        )
                    }
                    .disabled(isUpdatingConversationVisibility)

                    if conversationIsPublic {
                        Button {
                            copyPublicShareLink()
                        } label: {
                            Label("Copy Public Link", systemImage: "doc.on.doc")
                        }

                        Button {
                            openPublicShareLink()
                        } label: {
                            Label("Open Public Link", systemImage: "arrow.up.right.square")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(Theme.font(size: 22))
                        .foregroundStyle(Theme.Colors.text)
                }
            } else {
                // Sidebar Toggle (Hamburger Menu)
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showSidebar.toggle()
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(Theme.font(size: 22, weight: .medium))
                        .foregroundStyle(Theme.Colors.text)
                }

                // Model Selector Pill (Centered)
                modelSelectorPill

                Spacer()

                // Right side action buttons
                // More menu
                Menu {
                    Button {
                        multiSelectViewModel.enterEditMode()
                    } label: {
                        Label("Select Messages", systemImage: "checkmark.circle")
                    }

                    Button {
                        withAnimation { isSearchVisible.toggle() }
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showAssistantPicker = true
                        }
                    } label: {
                        Label("Change Assistant", systemImage: "person.circle")
                    }

                    Button {
                        Task {
                            await loadPromptTemplates()
                            showPromptTemplates = true
                        }
                    } label: {
                        Label("Prompt Templates", systemImage: "text.badge.plus")
                    }

                    Button {
                        enhanceCurrentPrompt()
                    } label: {
                        Label(
                            isEnhancingPrompt ? "Enhancing..." : "Enhance Prompt",
                            systemImage: "wand.and.stars"
                        )
                    }
                    .disabled(
                        isEnhancingPrompt
                            || messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        toggleConversationPublic()
                    } label: {
                        Label(
                            conversationIsPublic ? "Disable Public Link" : "Enable Public Link",
                            systemImage: conversationIsPublic ? "lock.fill" : "globe"
                        )
                    }
                    .disabled(isUpdatingConversationVisibility)

                    if conversationIsPublic {
                        Button {
                            copyPublicShareLink()
                        } label: {
                            Label("Copy Public Link", systemImage: "doc.on.doc")
                        }

                        Button {
                            openPublicShareLink()
                        } label: {
                            Label("Open Public Link", systemImage: "arrow.up.right.square")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(Theme.font(size: 22))
                        .foregroundStyle(Theme.Colors.text)
                }

                // New Chat Button
                Button {
                    onNewChat?()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(Theme.font(size: 20))
                        .foregroundStyle(Theme.Colors.text)
                }
            }
        }
        .padding(.horizontal, Theme.scaled(16))
        .padding(.vertical, Theme.scaled(12))
        .background(Theme.Colors.backgroundStart)
        .animation(.easeInOut(duration: 0.2), value: multiSelectViewModel.isEditMode)
    }

    private var modelSelectorPill: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showModelPicker = true
            }
        } label: {
            HStack(spacing: Theme.scaled(6)) {
                if let selectedModel = modelManager.selectedModel {
                    Text(selectedModel.name ?? selectedModel.modelId)
                        .font(Theme.font(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.text)
                        .lineLimit(1)
                } else {
                    Text("Select Model")
                        .font(Theme.font(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.text)
                }

                Image(systemName: "chevron.down")
                    .font(Theme.font(size: 10, weight: .bold))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .rotationEffect(showModelPicker ? .degrees(180) : .degrees(0))
            }
            .padding(.horizontal, Theme.scaled(12))
            .padding(.vertical, Theme.scaled(8))
            .background(Theme.Colors.glassSurface)
            .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var pickerOverlays: some View {
        ZStack {
            if showModelPicker {
                modelPickerOverlay
            }

            if showProviderPicker {
                providerPickerOverlay
            }

            if showAssistantPicker {
                assistantPickerOverlay
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showModelPicker)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showProviderPicker)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showAssistantPicker)
    }

    @ViewBuilder
    private var modelPickerOverlay: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showModelPicker = false
                }
            }

        VStack {
            ModelPicker(
                groupedModels: filteredModelGroups,
                selectedModelId: modelManager.selectedModel?.modelId,
                onSelect: { selectedModel in
                    modelManager.selectModel(selectedModel)
                    UserDefaults.standard.set(selectedModel.modelId, forKey: "lastUsedModel")
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showModelPicker = false
                    }
                },
                onDismiss: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showModelPicker = false
                    }
                }
            )
            .padding(.top, Theme.scaled(60))
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var filteredModelGroups: [ModelGroup] {
        if let providerId = viewModel.selectedProviderId {
            let filtered = modelManager.groupedModels.filter {
                $0.name.localizedCaseInsensitiveContains(providerId)
            }
            return filtered.isEmpty ? modelManager.groupedModels : filtered
        }
        return modelManager.groupedModels
    }

    @ViewBuilder
    private var providerPickerOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showProviderPicker = false
                }
            }

        VStack {
            Spacer()
            ProviderPicker(
                availableProviders: viewModel.availableProviders,
                selectedProviderId: viewModel.selectedProviderId,
                onSelectProvider: { providerId in
                    viewModel.selectProvider(providerId: providerId)
                    if let modelId = modelManager.selectedModel?.modelId,
                        let providerId = providerId
                    {
                        modelManager.saveLastProvider(for: modelId, providerId: providerId)
                    }
                    withAnimation { showProviderPicker = false }
                },
                webSearchMode: $webSearchMode,
                webSearchProvider: $webSearchProvider,
                webSearchExaDepth: $webSearchExaDepth,
                webSearchContextSize: $webSearchContextSize,
                webSearchKagiSource: $webSearchKagiSource,
                webSearchValyuSearchType: $webSearchValyuSearchType,
                reasoningEffort: $reasoningEffort,
                temporaryMode: $temporaryMode
            )
            .padding(.bottom, 80)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private var assistantPickerOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showAssistantPicker = false
                }
            }

        VStack {
            // Inline assistant picker
            VStack(spacing: 0) {
                Text("Select Assistant")
                    .font(Theme.font(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.text)
                    .padding(.vertical, Theme.scaled(12))
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.glassBackground)

                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(assistantManager.assistants) { assistant in
                            Button {
                                assistantManager.selectAssistant(assistant)
                                withAnimation { showAssistantPicker = false }
                            } label: {
                                HStack(spacing: Theme.scaled(12)) {
                                    Image(
                                        systemName: assistant.isDefault
                                            ? "person.circle.fill" : "person.circle"
                                    )
                                    .font(Theme.font(size: 24))
                                    .foregroundStyle(
                                        assistant.isDefault
                                            ? Theme.Colors.accent : Theme.Colors.textSecondary)

                                    VStack(alignment: .leading, spacing: Theme.scaled(4)) {
                                        HStack(spacing: Theme.scaled(6)) {
                                            Text(assistant.name)
                                                .font(Theme.font(size: 16))
                                                .foregroundStyle(Theme.Colors.text)

                                            if assistant.isDefault {
                                                Text("Default")
                                                    .font(Theme.font(size: 11))
                                                    .padding(.horizontal, Theme.scaled(6))
                                                    .padding(.vertical, Theme.scaled(2))
                                                    .background(Theme.Colors.accent.opacity(0.2))
                                                    .foregroundStyle(Theme.Colors.accent)
                                                    .clipShape(Capsule())
                                            }
                                        }

                                        if let description = assistant.description,
                                            !description.isEmpty
                                        {
                                            Text(description)
                                                .font(Theme.font(size: 13))
                                                .foregroundStyle(Theme.Colors.textSecondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer()

                                    if assistantManager.selectedAssistant?.id == assistant.id {
                                        Image(systemName: "checkmark")
                                            .font(Theme.font(size: 16))
                                            .foregroundStyle(Theme.Colors.accent)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, Theme.scaled(16))
                                .padding(.vertical, Theme.scaled(12))
                                .background(
                                    assistantManager.selectedAssistant?.id == assistant.id
                                        ? Theme.Colors.secondary.opacity(0.1) : Color.clear
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Divider().padding(.leading, Theme.scaled(16))
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .frame(maxHeight: Theme.scaled(350))
            .background(Theme.Colors.backgroundStart)
            .clipShape(RoundedRectangle(cornerRadius: Theme.scaled(16)))
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, Theme.scaled(16))
            .padding(.top, Theme.scaled(60))

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var backgroundView: some View {
        Theme.Colors.backgroundStart
            .ignoresSafeArea()
    }

    private var displayedMessages: [MessageResponse] {
        var messages = viewModel.messages

        // Filter out the message currently being streamed to avoid duplicate bubbles
        if let streamingId = viewModel.streamingMessageId {
            messages = messages.filter { $0.id != streamingId }
        }

        if searchText.isEmpty {
            return messages
        }
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return messages }

        return messages.filter { message in
            messageMatchesSearch(message.content, query: trimmed)
        }
    }

    private func messageMatchesSearch(_ content: String, query: String) -> Bool {
        let normalizedContent = content.lowercased()
        let normalizedQuery = query.lowercased()

        switch messageSearchMode {
        case .exact:
            return normalizedContent.contains(normalizedQuery)
        case .words:
            let queryWords = normalizedQuery.split(whereSeparator: \.isWhitespace)
            guard !queryWords.isEmpty else { return true }
            let contentWords = normalizedContent.split(whereSeparator: \.isWhitespace)
            return queryWords.allSatisfy { queryWord in
                contentWords.contains { contentWord in
                    contentWord.hasPrefix(queryWord)
                }
            }
        case .fuzzy:
            if normalizedContent.contains(normalizedQuery) { return true }
            return fuzzyMatch(needle: normalizedQuery, haystack: normalizedContent)
        }
    }

    private func fuzzyMatch(needle: String, haystack: String) -> Bool {
        if needle.isEmpty { return true }
        var haystackIndex = haystack.startIndex

        for char in needle {
            while haystackIndex < haystack.endIndex && haystack[haystackIndex] != char {
                haystack.formIndex(after: &haystackIndex)
            }

            if haystackIndex == haystack.endIndex {
                return false
            }

            haystack.formIndex(after: &haystackIndex)
        }

        return true
    }

    @ViewBuilder
    private func messagesView(proxy: ScrollViewProxy) -> some View {
        if viewModel.isLoading && viewModel.messages.isEmpty {
            ChatSkeleton()
                .transition(.opacity)
        } else if viewModel.messages.isEmpty && !viewModel.isGenerating {
            GeometryReader { geometry in
                ScrollView {
                    emptyStateView
                        .frame(minHeight: geometry.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        } else if displayedMessages.isEmpty && !searchText.isEmpty {
            GeometryReader { geometry in
                ScrollView {
                    ContentUnavailableView.search(text: searchText)
                        .frame(minHeight: geometry.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.lg) {
                    ForEach(Array(displayedMessages.enumerated()), id: \.element.id) {
                        index, message in
                        MessageBubble(
                            message: message,
                            conversationId: activeConversationId,
                            onRegenerate: message.role == "assistant" ? regenerateHandler : nil,
                            onMessageUpdated: { _ in
                                Task {
                                    await viewModel.loadMessages(
                                        conversationId: activeConversationId)
                                }
                            },
                            onBranch: {
                                Task {
                                    await viewModel.loadConversations()
                                    await viewModel.loadMessages(
                                        conversationId: activeConversationId)
                                }
                            },
                            onDocumentTap: { document in
                                selectedDocument = document
                            },
                            isSelected: multiSelectViewModel.isSelected(message),
                            isSelectionMode: multiSelectViewModel.isEditMode,
                            onTap: {
                                multiSelectViewModel.toggleSelection(message)
                            },
                            onLongPress: {
                                multiSelectViewModel.enterEditMode()
                                multiSelectViewModel.toggleSelection(message)
                            },
                            metadata: viewModel.messageMetadata[message.id]
                        )
                        .id(message.id)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
                    }

                    // Streaming content or typing indicator when generating
                    if viewModel.isGenerating {
                        if !viewModel.streamingContent.isEmpty {
                            StreamingMessageBubble(
                                content: viewModel.streamingContent,
                                reasoning: viewModel.streamingReasoning
                            )
                            .id("streaming-message")
                        } else {
                            TypingIndicator()
                                .id("typing-indicator")
                        }
                    }

                    // Follow-up questions after generation completes
                    if !viewModel.isGenerating,
                        !viewModel.followUpSuggestions.isEmpty,
                        let lastMessage = viewModel.messages.last,
                        lastMessage.role == "assistant"
                    {
                        FollowUpQuestionsView(suggestions: viewModel.followUpSuggestions) {
                            suggestion in
                            messageText = suggestion
                            isInputFocused = true
                        }
                        .id("follow-up-questions")
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("bottom-anchor")
                        .onAppear {
                            shouldAutoScrollToBottom = true
                        }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
                .animation(Theme.Animation.smooth, value: viewModel.messages.count)
                .animation(Theme.Animation.smooth, value: viewModel.isGenerating)
                .animation(Theme.Animation.smooth, value: viewModel.followUpSuggestions)
                .animation(.none, value: viewModel.streamingContent)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                await viewModel.loadMessages(conversationId: activeConversationId)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        guard viewModel.isGenerating else { return }
                        guard value.translation.height > 12 else { return }
                        shouldAutoScrollToBottom = false
                    }
            )
            .onChange(of: viewModel.isGenerating) { _, isGenerating in
                if isGenerating && shouldAutoScrollToBottom {
                    withAnimation {
                        proxy.scrollTo("typing-indicator", anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.streamingContent) { _, _ in
                if viewModel.isGenerating
                    && !viewModel.streamingContent.isEmpty
                    && shouldAutoScrollToBottom
                {
                    withAnimation {
                        proxy.scrollTo("streaming-message", anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.followUpSuggestions) { _, suggestions in
                guard !viewModel.isGenerating, !suggestions.isEmpty, shouldAutoScrollToBottom else {
                    return
                }
                Task {
                    try? await Task.sleep(nanoseconds: 120_000_000)
                    await MainActor.run {
                        withAnimation {
                            proxy.scrollTo("follow-up-questions", anchor: .bottom)
                        }
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            // Clean empty state - No icons or suggestions
            Spacer()
        }
    }

    private var regenerateHandler: () -> Void {
        return {
            // Find the last assistant message to regenerate
            guard
                let lastAssistantMessage = viewModel.messages.last(where: { $0.role == "assistant" }
                ),
                viewModel.messages.last(where: { $0.role == "user" }) != nil,
                let model = modelManager.selectedModel
            else { return }

            Task {
                // Delete the old assistant message first
                do {
                    _ = try await NanoChatAPI.shared.deleteMessage(
                        messageId: lastAssistantMessage.id)
                    // Remove from local messages array
                    await MainActor.run {
                        viewModel.messages.removeAll { $0.id == lastAssistantMessage.id }
                    }
                } catch {
                    print("Failed to delete message for regeneration: \(error)")
                    // Continue anyway - the new message will be added
                }

                // Generate a new response (without creating a new user message)
                // The API will see the conversation ending with the user message
                await viewModel.regenerateResponse(
                    conversationId: activeConversationId,
                    modelId: model.modelId,
                    assistantId: assistantManager.selectedAssistant?.id,
                    webSearchEnabled: isWebSearchEnabled,
                    webSearchMode: isWebSearchEnabled ? webSearchMode.rawValue : nil,
                    webSearchProvider: isWebSearchEnabled ? webSearchProvider.rawValue : nil,
                    webSearchExaDepth: isWebSearchEnabled && webSearchProvider == .exa
                        ? webSearchExaDepth.rawValue : nil,
                    webSearchContextSize: isWebSearchEnabled
                        ? webSearchContextSize.rawValue : nil,
                    webSearchKagiSource: isWebSearchEnabled && webSearchProvider == .kagi
                        ? webSearchKagiSource.rawValue : nil,
                    webSearchValyuSearchType: isWebSearchEnabled && webSearchProvider == .valyu
                        ? webSearchValyuSearchType.rawValue : nil,
                    providerId: viewModel.selectedProviderId,
                    reasoningEffort: model.capabilities?.reasoning == true
                        && reasoningEffort != .low
                        ? reasoningEffort.rawValue : nil,
                    temporaryMode: temporaryMode ? true : nil
                )
            }
        }
    }

    private func loadData() async {
        await viewModel.loadConversations()
        await viewModel.loadMessages(conversationId: conversation.id)
        if let fromLoadedConversation = viewModel.currentConversation?.isPublic {
            conversationIsPublic = fromLoadedConversation
        } else {
            conversationIsPublic = conversation.isPublic ?? false
        }
        await modelManager.loadModels()
        await assistantManager.loadAssistants()
        await applyAssistantDefaults()
    }

    private func applyAssistantDefaults() async {
        guard let assistant = assistantManager.selectedAssistant else { return }

        if let defaultModelId = assistant.defaultModelId,
            let matchingModel = modelManager.allModels.first(where: { $0.modelId == defaultModelId }
            )
        {
            modelManager.selectModel(matchingModel)
            await viewModel.fetchModelProviders(modelId: matchingModel.modelId)
        }

        if let mode = assistant.defaultWebSearchMode,
            let parsedMode = WebSearchMode(rawValue: mode)
        {
            webSearchMode = parsedMode
        } else {
            webSearchMode = .off
        }

        if let provider = assistant.defaultWebSearchProvider,
            let parsedProvider = WebSearchProvider(rawValue: provider)
        {
            webSearchProvider = parsedProvider
        } else {
            webSearchProvider = .linkup
        }

        if let exaDepth = assistant.defaultWebSearchExaDepth,
            let parsedExaDepth = WebSearchExaDepth(rawValue: exaDepth)
        {
            webSearchExaDepth = parsedExaDepth
        } else {
            webSearchExaDepth = .auto
        }

        if let contextSize = assistant.defaultWebSearchContextSize,
            let parsedContextSize = WebSearchContextSize(rawValue: contextSize)
        {
            webSearchContextSize = parsedContextSize
        } else {
            webSearchContextSize = .medium
        }

        if let kagiSource = assistant.defaultWebSearchKagiSource,
            let parsedKagiSource = WebSearchKagiSource(rawValue: kagiSource)
        {
            webSearchKagiSource = parsedKagiSource
        } else {
            webSearchKagiSource = .web
        }

        if let valyuType = assistant.defaultWebSearchValyuSearchType,
            let parsedValyuType = WebSearchValyuSearchType(rawValue: valyuType)
        {
            webSearchValyuSearchType = parsedValyuType
        } else {
            webSearchValyuSearchType = .all
        }
    }

    private func scrollToLastMessage(proxy: ScrollViewProxy) {
        guard shouldAutoScrollToBottom else { return }
        if let lastMessage = displayedMessages.last {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    @ViewBuilder
    private var inputArea: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Attachment previews (existing)
            if !selectedImages.isEmpty || !selectedDocuments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { _, imageData in
                            ZStack(alignment: .topTrailing) {
                                if let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(
                                            width: 80 * Theme.imageScaleFactor,
                                            height: 80 * Theme.imageScaleFactor
                                        )
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                                .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                                        )
                                }

                                Button {
                                    selectedImages.removeAll { $0 == imageData }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white)
                                        .background(Circle().fill(Theme.Colors.secondary))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        ForEach(Array(selectedDocuments.enumerated()), id: \.offset) {
                            _, documentURL in
                            ZStack(alignment: .topTrailing) {
                                VStack(spacing: 4) {
                                    Image(systemName: "doc.fill")
                                        .font(Theme.Typography.title2)
                                        .foregroundStyle(Theme.Colors.secondary)
                                    Text(documentURL.lastPathComponent)
                                        .font(Theme.Typography.caption2)
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                        .lineLimit(1)
                                }
                                .frame(
                                    width: 80 * Theme.imageScaleFactor,
                                    height: 80 * Theme.imageScaleFactor
                                )
                                .padding(Theme.Spacing.sm)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                        .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                                )

                                Button {
                                    selectedDocuments.removeAll { $0 == documentURL }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white)
                                        .background(Circle().fill(Theme.Colors.secondary))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }
                .frame(height: 100 * Theme.imageScaleFactor)
            }

            // New "Capsule" Input Bar Style
            HStack(alignment: .bottom, spacing: Theme.Spacing.sm) {
                // Attach Button (Left side)
                Menu {
                    Button {
                        // Action for images handled by attachment button wrapper if possible,
                        // but let's stick to the existing AttachmentButton if it works well,
                        // or recreate a simple menu here.
                        // For now, keeping the AttachmentButton but styling it minimal.
                    } label: {
                        Label("Photos", systemImage: "photo")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(Theme.font(size: 20, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: Theme.scaled(36), height: Theme.scaled(36))
                        .background(inputControlBackground)
                        .overlay {
                            Circle()
                                .stroke(Theme.Colors.border.opacity(0.5), lineWidth: 0.8)
                        }
                        .clipShape(Circle())
                }
                .highPriorityGesture(
                    TapGesture().onEnded {
                        // This is a workaround if Menu doesn't trigger nicely,
                        // but usually Menu works.
                        // However, we have an existing AttachmentButton. Let's use it but style it.
                    }
                )
                // actually let's use the AttachmentButton but hide it inside this plus
                .overlay {
                    AttachmentButton { imageData in
                        selectedImages.append(imageData)
                    } onDocumentSelected: { documentURL in
                        selectedDocuments.append(documentURL)
                    } onVoiceInput: {
                        // Voice input is now handled separately on the right
                    }
                    .opacity(0.01)  // Invisible hit target over the plus button
                }
                .padding(.bottom, Theme.scaled(6))

                // Text Field
                TextField("Ask anything", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .focused($isInputFocused)
                    .font(Theme.font(size: 16))
                    .foregroundStyle(Theme.Colors.text)
                    .padding(.vertical, Theme.scaled(12))
                    .padding(.horizontal, Theme.scaled(16))
                    .frame(minHeight: Theme.scaled(44))
                    .lineLimit(1...6)
                    .background(inputControlBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.scaled(22)))
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.scaled(22))
                            .stroke(Theme.Colors.border.opacity(0.5), lineWidth: 0.8)
                    }

                // Search/Provider Toggle
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showProviderPicker = true
                    }
                } label: {
                    Image(systemName: isWebSearchEnabled ? "globe" : "server.rack")
                        .font(Theme.font(size: 18))
                        .foregroundStyle(
                            isWebSearchEnabled
                                ? Theme.Colors.accent : Theme.Colors.textSecondary
                        )
                        .frame(width: Theme.scaled(36), height: Theme.scaled(36))
                }
                .padding(.bottom, Theme.scaled(6))

                // Voice / Send Button
                if messageText.isEmpty && selectedImages.isEmpty && selectedDocuments.isEmpty
                    && !viewModel.isGenerating
                {
                    Button {
                        showVoiceRecorder = true
                    } label: {
                        Image(systemName: "waveform")  // ChatGPT style voice icon
                            .font(Theme.font(size: 20))
                            .foregroundStyle(Theme.Colors.text)
                            .frame(width: Theme.scaled(36), height: Theme.scaled(36))
                    }
                    .padding(.bottom, Theme.scaled(6))
                } else {
                    sendButton
                        .padding(.bottom, 6)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.lg)
        }
        .background {
            Rectangle()
                .fill(inputAreaBackgroundColor)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.Colors.border.opacity(colorScheme == .light ? 0.55 : 0.3))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var sendButton: some View {
        Button(action: sendMessage) {
            ZStack {
                if viewModel.isGenerating || isUploading {
                    Circle()
                        .fill(Theme.Colors.text)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "stop.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Theme.Colors.backgroundStart)
                        )
                } else {
                    Circle()
                        .fill(Theme.Colors.text)  // Solid black/white button
                        .frame(width: 32, height: 32)

                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.Colors.backgroundStart)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(
            viewModel.isGenerating || isUploading || modelManager.selectedModel == nil
        )
    }

    private func sendMessage() {
        guard let model = modelManager.selectedModel,
            !messageText.isEmpty || !selectedImages.isEmpty || !selectedDocuments.isEmpty
        else { return }

        shouldAutoScrollToBottom = true

        // Haptic feedback on send
        HapticManager.shared.messageSent()

        // Clear follow-up suggestions when sending a new message
        viewModel.clearFollowUpSuggestions()

        isInputFocused = false
        let currentMessage = messageText.isEmpty ? "Generated Image" : messageText
        let currentImages = selectedImages
        let currentDocuments = selectedDocuments

        messageText = ""
        selectedImages = []
        selectedDocuments = []

        let webSearchEnabled = isWebSearchEnabled
        let webSearchModeString = webSearchEnabled ? webSearchMode.rawValue : nil
        let webSearchProviderString = webSearchEnabled ? webSearchProvider.rawValue : nil
        let webSearchExaDepthString =
            (webSearchEnabled && webSearchProvider == .exa) ? webSearchExaDepth.rawValue : nil
        let webSearchContextSizeString =
            webSearchEnabled ? webSearchContextSize.rawValue : nil
        let webSearchKagiSourceString =
            (webSearchEnabled && webSearchProvider == .kagi) ? webSearchKagiSource.rawValue : nil
        let webSearchValyuSearchTypeString =
            (webSearchEnabled && webSearchProvider == .valyu)
            ? webSearchValyuSearchType.rawValue : nil
        let reasoningEffortString =
            (model.capabilities?.reasoning == true && reasoningEffort != .low)
            ? reasoningEffort.rawValue : nil

        let isImageModel = model.capabilities?.images == true
        let isVideoModel = model.capabilities?.video == true
        let targetConversationId: String? =
            (temporaryMode && viewModel.messages.isEmpty) ? nil : activeConversationId

        Task {
            // Upload attachments first
            var uploadedImages: [ImageAttachment] = []
            var uploadedDocuments: [DocumentAttachment] = []

            if !currentImages.isEmpty || !currentDocuments.isEmpty {
                isUploading = true
                defer { isUploading = false }

                // Upload images
                for imageData in currentImages {
                    do {
                        let attachment = try await NanoChatAPI.shared.uploadImage(data: imageData)
                        uploadedImages.append(attachment)
                    } catch {
                        print("Failed to upload image: \(error)")
                    }
                }

                // Upload documents
                for documentURL in currentDocuments {
                    do {
                        let attachment = try await NanoChatAPI.shared.uploadDocument(
                            url: documentURL)
                        uploadedDocuments.append(attachment)
                        print("Uploaded document: \(attachment.storageId)")
                    } catch {
                        print("Failed to upload document: \(error)")
                    }
                }
            }

            await viewModel.sendMessage(
                message: currentMessage,
                modelId: model.modelId,
                conversationId: targetConversationId,
                assistantId: assistantManager.selectedAssistant?.id,
                webSearchEnabled: isImageModel || isVideoModel ? false : webSearchEnabled,  // Disable search for gen models
                webSearchMode: isImageModel || isVideoModel ? nil : webSearchModeString,
                webSearchProvider: isImageModel || isVideoModel ? nil : webSearchProviderString,
                webSearchExaDepth: isImageModel || isVideoModel ? nil : webSearchExaDepthString,
                webSearchContextSize: isImageModel || isVideoModel
                    ? nil : webSearchContextSizeString,
                webSearchKagiSource: isImageModel || isVideoModel ? nil : webSearchKagiSourceString,
                webSearchValyuSearchType: isImageModel || isVideoModel
                    ? nil : webSearchValyuSearchTypeString,
                providerId: isImageModel || isVideoModel ? nil : viewModel.selectedProviderId,  // Disable provider check if desired, or keep it
                images: uploadedImages.isEmpty ? nil : uploadedImages,
                documents: uploadedDocuments.isEmpty ? nil : uploadedDocuments,
                imageParams: isImageModel ? viewModel.imageParams : nil,
                videoParams: isVideoModel ? viewModel.videoParams : nil,
                reasoningEffort: isImageModel || isVideoModel ? nil : reasoningEffortString,
                temporaryMode: temporaryMode ? true : nil
            )

            // Generate follow-up questions after message generation completes
            // Only for text models (not image/video generation)
            if !isImageModel && !isVideoModel,
                let lastMessage = viewModel.messages.last,
                lastMessage.role == "assistant",
                lastMessage.content.count > 100
            {
                await viewModel.fetchFollowUpQuestions(
                    conversationId: activeConversationId,
                    messageId: lastMessage.id
                )
            }

            onMessageSent?()
        }
    }

    private func handleTranscription(_ transcription: String) {
        messageText = transcription
        if audioPreferences.autoSendTranscription {
            sendMessage()
        } else {
            isInputFocused = true
        }
    }

    private func exportConversation() {
        let markdown = ExportManager.shared.exportConversationToMarkdown(
            conversation: conversation,
            messages: viewModel.messages
        )
        let filename = ExportManager.shared.sanitizeFilename(conversation.title)
        ExportManager.shared.presentShareSheet(
            content: markdown,
            fileName: filename,
            format: .markdown
        )
    }

    private var publicShareURL: URL? {
        URL(string: "\(APIConfiguration.shared.baseURL)/share/\(activeConversationId)")
    }

    private func copyPublicShareLink() {
        guard let shareURL = publicShareURL else { return }
        UIPasteboard.general.string = shareURL.absoluteString
        HapticManager.shared.success()
    }

    private func openPublicShareLink() {
        guard let shareURL = publicShareURL else { return }
        UIApplication.shared.open(shareURL)
    }

    private func toggleConversationPublic() {
        guard !isUpdatingConversationVisibility else { return }
        let nextValue = !conversationIsPublic
        let previousValue = conversationIsPublic
        conversationIsPublic = nextValue
        isUpdatingConversationVisibility = true

        Task {
            do {
                try await NanoChatAPI.shared.setConversationPublic(
                    conversationId: activeConversationId,
                    isPublic: nextValue
                )
                await viewModel.loadConversations()
                if let updated = viewModel.conversations.first(where: {
                    $0.id == activeConversationId
                }) {
                    conversationIsPublic = updated.isPublic ?? nextValue
                }
                HapticManager.shared.success()
            } catch {
                conversationIsPublic = previousValue
            }
            isUpdatingConversationVisibility = false
        }
    }

    private func loadPromptTemplates() async {
        isLoadingPromptTemplates = true
        defer { isLoadingPromptTemplates = false }

        do {
            promptTemplates = try await NanoChatAPI.shared.getPrompts()
        } catch {
            promptTemplates = []
        }
    }

    private func handlePromptTemplateSelection(_ template: PromptTemplate) {
        selectedPromptTemplate = template
        let variables = template.variables ?? []

        if variables.isEmpty {
            applyPromptTemplate(template, with: [:])
            return
        }

        promptVariableValues = Dictionary(
            uniqueKeysWithValues: variables.map { variable in
                (variable.name, variable.defaultValue ?? "")
            }
        )
        showPromptVariables = true
    }

    private func enhanceCurrentPrompt() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !isEnhancingPrompt else { return }

        isEnhancingPrompt = true
        Task {
            do {
                let enhanced = try await NanoChatAPI.shared.enhancePrompt(trimmed)
                messageText = enhanced
                HapticManager.shared.success()
            } catch {
                // Keep existing text on failure.
            }
            isEnhancingPrompt = false
        }
    }

    private func applyPromptTemplate(_ template: PromptTemplate, with values: [String: String]) {
        let rendered = renderPromptTemplate(template.content, with: values)
        let mode = template.appendMode ?? .replace

        switch mode {
        case .replace:
            messageText = rendered
        case .prepend:
            if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                messageText = rendered
            } else {
                messageText = rendered + "\n\n" + messageText
            }
        case .append:
            if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                messageText = rendered
            } else {
                messageText += "\n\n" + rendered
            }
        }

        if let defaultModelId = template.defaultModelId,
            let model = modelManager.allModels.first(where: { $0.modelId == defaultModelId })
        {
            modelManager.selectModel(model)
        }

        if let modeRaw = template.defaultWebSearchMode,
            let mode = WebSearchMode(rawValue: modeRaw)
        {
            webSearchMode = mode
        }

        if let providerRaw = template.defaultWebSearchProvider,
            let provider = WebSearchProvider(rawValue: providerRaw)
        {
            webSearchProvider = provider
        }
    }

    private func renderPromptTemplate(_ content: String, with values: [String: String]) -> String {
        let pattern = #"\{\{\s*([a-zA-Z0-9_]+)(?::([^}]*))?\s*\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return content
        }

        let nsContent = content as NSString
        let matches = regex.matches(
            in: content,
            range: NSRange(location: 0, length: nsContent.length)
        )

        var result = content
        for match in matches.reversed() {
            guard match.numberOfRanges >= 3 else { continue }
            let fullRange = match.range(at: 0)
            let variableName = match.range(at: 1)
            let defaultValue = match.range(at: 2)

            let name =
                variableName.location != NSNotFound
                ? nsContent.substring(with: variableName) : ""
            let fallback =
                defaultValue.location != NSNotFound
                ? nsContent.substring(with: defaultValue) : ""
            let replacement = values[name] ?? fallback

            if let range = Range(fullRange, in: result) {
                result.replaceSubrange(range, with: replacement)
            }
        }
        return result
    }

    // MARK: - Message Batch Operations

    private var messageBatchOperationsBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button {
                batchCopyMessages()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(Theme.Typography.caption)
            }
            .buttonStyle(.bordered)
            .tint(Theme.Colors.primary)

            Button {
                batchExportMessages()
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(Theme.Typography.caption)
            }
            .buttonStyle(.bordered)
            .tint(Theme.Colors.secondary)

            Button {
                Task {
                    await batchToggleStar()
                }
            } label: {
                Label("Star", systemImage: "star.fill")
                    .font(Theme.Typography.caption)
            }
            .buttonStyle(.bordered)
            .tint(Theme.Colors.warning)
        }
        .padding()
        .background(Theme.Colors.glassPane)
        .overlay(
            Rectangle()
                .fill(Theme.Colors.glassBorder)
                .frame(height: 1),
            alignment: .top
        )
    }

    private func batchCopyMessages() {
        multiSelectViewModel.exportSelected { ids in
            let selectedMessages = viewModel.messages.filter { ids.contains($0.id) }
            let combinedContent =
                selectedMessages
                .map { message in
                    let role = message.role == "user" ? "You" : "Assistant"
                    return "\(role): \(message.content)"
                }
                .joined(separator: "\n\n---\n\n")

            UIPasteboard.general.string = combinedContent
            HapticManager.shared.success()
        }
    }

    private func batchExportMessages() {
        multiSelectViewModel.exportSelected { ids in
            let selectedMessages = viewModel.messages.filter { ids.contains($0.id) }

            // Create a temporary conversation-like structure for export
            let tempConversation = ConversationResponse(
                id: conversation.id,
                title: "\(conversation.title) (Selected Messages)",
                userId: conversation.userId,
                projectId: conversation.projectId,
                pinned: conversation.pinned,
                generating: false
            )

            let markdown = ExportManager.shared.exportConversationToMarkdown(
                conversation: tempConversation,
                messages: selectedMessages
            )
            let filename = ExportManager.shared.sanitizeFilename("\(conversation.title)-selected")
            ExportManager.shared.presentShareSheet(
                content: markdown,
                fileName: filename,
                format: .markdown
            )
        }
    }

    private func batchToggleStar() async {
        await multiSelectViewModel.starSelected { ids in
            for id in ids {
                Task {
                    try? await NanoChatAPI.shared.setMessageStarred(messageId: id, starred: true)
                }
            }
        }
        await viewModel.loadMessages(conversationId: activeConversationId)
    }

    private var inputAreaBackgroundColor: Color {
        colorScheme == .light
            ? Theme.Colors.backgroundStart : Theme.Colors.backgroundStart.opacity(0.92)
    }

    private var inputControlBackground: Color {
        colorScheme == .light ? .white : Theme.Colors.glassSurface
    }
}

struct MessageBubble: View {
    let message: MessageResponse
    let conversationId: String
    let onRegenerate: (() -> Void)?
    let onMessageUpdated: ((MessageResponse) -> Void)?
    let onBranch: (() -> Void)?
    let onDocumentTap: ((MessageDocumentResponse) -> Void)?
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    var metadata: MessageMetadata?

    @State private var isReasoningExpanded = false
    @State private var showCopyFeedback = false
    @State private var userRating: MessageThumbsRating?
    @State private var isEditing = false
    @State private var editedContent = ""
    @State private var isSaving = false
    @State private var isBranching = false
    @State private var isStarred = false
    @State private var isStarring = false
    @ObservedObject private var audioPreferences = AudioPreferences.shared
    @ObservedObject private var audioPlayback = AudioPlaybackManager.shared
    @State private var isSynthesizingSpeech = false
    @State private var speechErrorMessage: String?
    @State private var videoPlayers: [String: AVPlayer] = [:]
    @State private var selectedImage: ImagePreviewItem?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                if message.role == "assistant" {
                    avatarView
                } else {
                    Spacer(minLength: 40)
                }

                VStack(
                    alignment: message.role == "user" ? .trailing : .leading,
                    spacing: Theme.Spacing.xs
                ) {
                    headerView
                    mediaAttachmentsView
                    videoAttachmentView
                    reasoningView
                    messageContentView
                    footerView
                }

                if message.role == "assistant" {
                    Spacer(minLength: 0)  // Allow full width for assistant
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isSelectionMode {
                    onTap()
                }
            }
            .background(isSelected ? Theme.Colors.accent.opacity(0.15) : Color.clear)

            // Selection indicator (shown in selection mode)
            if isSelectionMode {
                selectionIndicator
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .onAppear {
            isStarred = message.starred ?? false
        }
        .onChange(of: message.starred) { _, newValue in
            isStarred = newValue ?? false
        }
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if !isSelectionMode {
                        onLongPress()
                    }
                }
        )
        .alert(
            "Audio Error",
            isPresented: Binding(
                get: { speechErrorMessage != nil },
                set: { if !$0 { speechErrorMessage = nil } }
            )
        ) {
            Button("OK") {
                speechErrorMessage = nil
            }
        } message: {
            Text(speechErrorMessage ?? "")
        }
        .fullScreenCover(item: $selectedImage) { imageItem in
            ImagePreviewView(item: imageItem)
        }
    }

    private var avatarView: some View {
        Group {
            if message.role == "user" {
                EmptyView()  // User doesn't need avatar in ChatGPT style, usually just right aligned bubble
            } else {
                Circle()
                    .fill(Theme.Colors.text.opacity(0.1))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.text)
                    )
            }
        }
    }

    @ViewBuilder
    private var headerView: some View {
        // ChatGPT style: No header text, just show star indicator if starred
        if isStarred {
            HStack {
                Spacer()
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.accent)
            }
        }
    }

    private func toggleStarred() {
        guard !isStarring else { return }

        isStarring = true
        let newStarredState = !isStarred

        // Optimistic UI update
        isStarred = newStarredState
        HapticManager.shared.tap()

        Task {
            do {
                _ = try await NanoChatAPI.shared.setMessageStarred(
                    messageId: message.id, starred: newStarredState)
                await MainActor.run {
                    isStarring = false
                    // Real update will come from parent refresh, but local state is good
                }
            } catch {
                await MainActor.run {
                    isStarred = !newStarredState  // Revert
                    isStarring = false
                }
            }
        }
    }

    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Theme.Colors.accent : Color.clear)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? Theme.Colors.accent : Theme.Colors.textTertiary,
                            lineWidth: 2)
                )

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(Theme.Spacing.sm)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    @ViewBuilder
    private var mediaAttachmentsView: some View {
        if (message.images?.isEmpty == false) || (message.documents?.isEmpty == false) {
            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 8) {
                if let images = message.images, !images.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8)
                    {
                        ForEach(images, id: \.storageId) { image in
                            Button {
                                if let url = resolveURL(image.url) {
                                    selectedImage = ImagePreviewItem(
                                        url: url,
                                        fileName: image.fileName ?? "Image",
                                        storageId: image.storageId
                                    )
                                }
                            } label: {
                                AuthenticatedMessageImageThumbnail(
                                    storageId: image.storageId,
                                    fallbackURL: resolveURL(image.url)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if let documents = message.documents, !documents.isEmpty {
                    ForEach(documents, id: \.url) { doc in
                        Button {
                            onDocumentTap?(doc)
                        } label: {
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundStyle(Theme.Colors.secondary)
                                Text(doc.fileName ?? "Document")
                                    .foregroundStyle(Theme.Colors.text)
                                    .lineLimit(1)
                            }
                            .padding(8)
                            .background(Theme.Colors.glassPane)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.bottom, 4)
        }
    }

    @ViewBuilder
    private var videoAttachmentView: some View {
        if let url = videoURL {
            VideoPlayerView(url: url)
                .padding(.bottom, 8)
        }
    }

    private var videoURL: URL? {
        // First check for markdown pattern [Video Result](url) like the web app does
        if let match = message.content.range(
            of: #"\[Video Result\]\((.*?)\)"#, options: .regularExpression)
        {
            let urlRange = message.content[match]
            // Extract URL from within parentheses
            if let openParen = urlRange.firstIndex(of: "("),
                let closeParen = urlRange.lastIndex(of: ")")
            {
                let urlStart = urlRange.index(after: openParen)
                let urlString = String(urlRange[urlStart..<closeParen])
                if let url = URL(string: urlString) {
                    return url
                }
            }
        }

        // Fallback: check for raw video URLs in content
        let types = [".mp4", ".mov", ".webm"]
        let words = message.content.components(separatedBy: .whitespacesAndNewlines)

        for word in words {
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)

            if let url = URL(string: cleanWord),
                url.scheme?.lowercased().hasPrefix("http") == true,
                types.contains(where: { cleanWord.lowercased().hasSuffix($0) })
            {
                return url
            }
        }
        return nil
    }

    private func resolveURL(_ urlString: String) -> URL? {
        if urlString.lowercased().hasPrefix("http") {
            return URL(string: urlString)
        }
        // Handle relative URL
        let baseURL = APIConfiguration.shared.baseURL
        // Ensure no double slash or missing slash
        let cleanBase = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        let cleanPath = urlString.hasPrefix("/") ? urlString : "/" + urlString
        return URL(string: cleanBase + cleanPath)
    }

    @ViewBuilder
    private var reasoningView: some View {
        if let reasoning = message.reasoning, !reasoning.isEmpty {
            DisclosureGroup(isExpanded: $isReasoningExpanded) {
                Text(reasoning)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(8)
                    .background(Theme.Colors.insetBackground)
                    .cornerRadius(8)
            } label: {
                Text("Reasoning Process")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .tint(Theme.Colors.textTertiary)
        }
    }

    /// Content with video markdown stripped out when video is displayed separately
    private var displayContent: String {
        var content = message.content

        // Strip [Video Result](url) markdown pattern since we display video separately
        if videoURL != nil {
            content = content.replacingOccurrences(
                of: #"\[Video Result\]\([^)]*\)"#,
                with: "",
                options: .regularExpression
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return content
    }

    @ViewBuilder
    private var messageContentView: some View {
        if isEditing {
            VStack(alignment: .trailing, spacing: 8) {
                TextEditor(text: $editedContent)
                    .scrollContentBackground(.hidden)
                    .background(Theme.Colors.glassSurface)
                    .cornerRadius(8)
                    .frame(minHeight: 100)
                    .foregroundStyle(Theme.Colors.text)

                HStack {
                    Button("Cancel") {
                        isEditing = false
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.Colors.textSecondary)

                    Button("Save") {
                        saveEdit()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.Colors.primary)
                    .disabled(isSaving)
                }
            }
        } else if !displayContent.isEmpty {
            if message.role == "user" {
                // User messages: plain text in bubble
                Text(displayContent)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.text)
                    .textSelection(.enabled)
                    .padding(12)
                    .background(Theme.Colors.userBubble)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                // Assistant messages: markdown rendering
                MarkdownText(displayContent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var footerView: some View {
        if !isEditing {
            HStack(spacing: Theme.scaled(8)) {
                if message.role == "assistant" {
                    // TTS Button
                    Button {
                        if audioPlayback.isPlaying && audioPlayback.currentMessageId == message.id {
                            audioPlayback.stopPlayback()
                        } else {
                            synthesizeSpeech()
                        }
                    } label: {
                        if isSynthesizingSpeech {
                            ProgressView()
                                .scaleEffect(0.5)
                        } else {
                            Image(
                                systemName: (audioPlayback.isPlaying
                                    && audioPlayback.currentMessageId == message.id)
                                    ? "stop.fill" : "speaker.wave.2"
                            )
                            .font(Theme.font(size: 12))
                            .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)

                    // Model name and metadata
                    if let modelId = message.modelId {
                        Text(modelId.components(separatedBy: "/").last ?? modelId)
                            .font(Theme.font(size: 11))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }

                    if let meta = metadata {
                        Text(meta.formattedCost)
                            .font(Theme.font(size: 11))
                            .foregroundStyle(Theme.Colors.textTertiary)

                        Text(meta.formattedTokens)
                            .font(Theme.font(size: 11))
                            .foregroundStyle(Theme.Colors.textTertiary)

                        if meta.tokensPerSecond > 0 {
                            Text(meta.formattedSpeed)
                                .font(Theme.font(size: 11))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }

                    // Star Button
                    Button {
                        toggleStarred()
                    } label: {
                        if isStarring {
                            ProgressView()
                                .scaleEffect(0.5)
                        } else {
                            Image(systemName: isStarred ? "star.fill" : "star")
                                .font(Theme.font(size: 12))
                                .foregroundStyle(
                                    isStarred ? Theme.Colors.secondary : Theme.Colors.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)

                    // Copy Button
                    Button {
                        UIPasteboard.general.string = message.content
                        showCopyFeedback = true
                        HapticManager.shared.success()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopyFeedback = false
                        }
                    } label: {
                        Image(systemName: showCopyFeedback ? "checkmark" : "doc.on.doc")
                            .font(Theme.font(size: 12))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .buttonStyle(.plain)

                    // Regenerate Button
                    Button {
                        onRegenerate?()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(Theme.font(size: 12))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .buttonStyle(.plain)

                    // Branch Button
                    Button {
                        branchConversation()
                    } label: {
                        if isBranching {
                            ProgressView()
                                .scaleEffect(0.5)
                        } else {
                            Image(systemName: "arrow.triangle.branch")
                                .font(Theme.font(size: 12))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isBranching)

                    Spacer()
                } else {
                    Spacer()

                    // Star Button for user messages
                    Button {
                        toggleStarred()
                    } label: {
                        if isStarring {
                            ProgressView()
                                .scaleEffect(0.5)
                        } else {
                            Image(systemName: isStarred ? "star.fill" : "star")
                                .font(Theme.font(size: 12))
                                .foregroundStyle(
                                    isStarred ? Theme.Colors.secondary : Theme.Colors.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        isEditing = true
                        editedContent = message.content
                    } label: {
                        Image(systemName: "pencil")
                            .font(Theme.font(size: 12))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        branchConversation()
                    } label: {
                        if isBranching {
                            ProgressView()
                                .scaleEffect(0.5)
                        } else {
                            Image(systemName: "arrow.triangle.branch")
                                .font(Theme.font(size: 12))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isBranching)
                }
            }
            .padding(.top, Theme.scaled(4))
        }
    }

    private func saveEdit() {
        guard !editedContent.isEmpty && editedContent != message.content else {
            isEditing = false
            return
        }

        isSaving = true

        Task {
            _ = try? await NanoChatAPI.shared.updateMessageContent(
                messageId: message.id, content: editedContent)

            await MainActor.run {
                isSaving = false
                isEditing = false
                // Trigger refresh
                onMessageUpdated?(message)
            }
        }
    }

    private func synthesizeSpeech() {
        isSynthesizingSpeech = true
        Task {
            do {
                let result = try await NanoChatAPI.shared.textToSpeech(
                    text: message.content, model: "tts-1", voice: "alloy", speed: 1.0)

                switch result {
                case .audioData(let data):
                    try audioPlayback.play(data: data, messageId: message.id)
                case .audioUrl(let url):
                    audioPlayback.playAudio(url: url, messageId: message.id)
                case .pending:
                    break  // Handle pending state if needed
                }

                await MainActor.run {
                    isSynthesizingSpeech = false
                }
            } catch {
                await MainActor.run {
                    isSynthesizingSpeech = false
                    speechErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func branchConversation() {
        guard !isBranching else { return }

        isBranching = true
        Task {
            do {
                _ = try await NanoChatAPI.shared.branchConversation(
                    conversationId: conversationId,
                    fromMessageId: message.id
                )
                await MainActor.run {
                    isBranching = false
                    HapticManager.shared.success()
                    onBranch?()
                }
            } catch {
                await MainActor.run {
                    isBranching = false
                }
            }
        }
    }
}

private struct AuthenticatedMessageImageThumbnail: View {
    let storageId: String
    let fallbackURL: URL?

    @State private var imageData: Data?
    @State private var loadFailed = false

    private static let cache = NSCache<NSString, NSData>()

    var body: some View {
        ZStack {
            Theme.Colors.glassSurface

            if let imageData {
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            } else if loadFailed {
                Image(systemName: "photo")
                    .foregroundStyle(Theme.Colors.textTertiary)
            } else {
                ProgressView()
                    .tint(Theme.Colors.secondary)
            }
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .clipped()
        .task(id: taskIdentifier) {
            await loadImage()
        }
    }

    private var taskIdentifier: String {
        "\(storageId)|\(fallbackURL?.absoluteString ?? "")"
    }

    @MainActor
    private func loadImage() async {
        let storageCacheKey = "storage:\(storageId)" as NSString
        if let cached = Self.cache.object(forKey: storageCacheKey) {
            imageData = cached as Data
            loadFailed = false
            return
        }

        do {
            let data = try await NanoChatAPI.shared.downloadStorageData(storageId: storageId)
            Self.cache.setObject(data as NSData, forKey: storageCacheKey)
            imageData = data
            loadFailed = false
            return
        } catch {
            // fall through to URL retry below
        }

        guard let fallbackURL else {
            imageData = nil
            loadFailed = true
            return
        }

        let urlCacheKey = "url:\(fallbackURL.absoluteString)" as NSString
        if let cached = Self.cache.object(forKey: urlCacheKey) {
            imageData = cached as Data
            loadFailed = false
            return
        }

        do {
            let data = try await NanoChatAPI.shared.downloadData(from: fallbackURL)
            Self.cache.setObject(data as NSData, forKey: urlCacheKey)
            imageData = data
            loadFailed = false
        } catch {
            imageData = nil
            loadFailed = true
        }
    }
}

struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                if player == nil {
                    player = AVPlayer(url: url)
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PromptTemplatePickerView: View {
    let templates: [PromptTemplate]
    let isLoading: Bool
    let onRefresh: () -> Void
    let onApply: (PromptTemplate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredTemplates: [PromptTemplate] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return templates }
        return templates.filter { template in
            template.name.localizedCaseInsensitiveContains(query)
                || template.content.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if filteredTemplates.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Prompt Templates" : "No Matching Templates",
                        systemImage: "text.badge.plus"
                    )
                } else {
                    List(filteredTemplates, id: \.id) { template in
                        Button {
                            onApply(template)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
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
                                        .lineLimit(2)
                                }
                                Text(template.content)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.Colors.textTertiary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.Colors.sectionBackground)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Theme.Colors.backgroundStart)
                }
            }
            .navigationTitle("Prompt Templates")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search templates")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh") { onRefresh() }
                }
            }
        }
    }
}

struct PromptVariableValuesView: View {
    let template: PromptTemplate
    @Binding var values: [String: String]
    let onApply: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(template.variables ?? [], id: \.name) { variable in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(variable.name)
                            .font(.headline)
                            .foregroundStyle(Theme.Colors.text)
                        if let description = variable.description, !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        TextField(
                            variable.defaultValue ?? "Value",
                            text: Binding(
                                get: { values[variable.name] ?? "" },
                                set: { values[variable.name] = $0 }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Theme.Colors.sectionBackground)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.backgroundStart)
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }
}
