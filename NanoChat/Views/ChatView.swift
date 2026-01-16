import AVKit
import SwiftUI

struct ChatView: View {
    let conversation: ConversationResponse
    let onMessageSent: (() -> Void)?
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var modelManager = ModelManager()
    @StateObject private var multiSelectViewModel = MultiSelectViewModel<MessageResponse>()
    @ObservedObject private var audioPreferences = AudioPreferences.shared
    @State private var assistantManager = AssistantManager()
    @State private var messageText = ""
    @State private var showVoiceRecorder = false
    @State private var voiceErrorMessage: String?
    @FocusState private var isInputFocused: Bool
    @State private var webSearchMode: WebSearchMode = .off
    @State private var webSearchProvider: WebSearchProvider = .linkup
    @State private var selectedImages: [Data] = []
    @State private var selectedDocuments: [URL] = []
    @State private var isUploading = false
    @State private var showProviderPicker = false
    @State private var showModelPicker = false

    @State private var showImageSettings = false
    @State private var showVideoSettings = false
    @State private var searchText = ""
    @State private var isSearchVisible = false
    @State private var selectedDocument: MessageDocumentResponse?


    var body: some View {
        ZStack {
            backgroundView

            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    if isSearchVisible {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Theme.Colors.textSecondary)
                            TextField("Search in chat...", text: $searchText)
                                .textFieldStyle(.plain)
                                .foregroundStyle(Theme.Colors.text)

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
                        .simultaneousGesture(TapGesture().onEnded {
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
                .navigationTitle(conversation.title)

                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    toolbarItems
                }
                .onAppear {
                    Task {
                        await loadData()
                    }
                }
                .onChange(of: viewModel.messages) { _, newValue in
                    multiSelectViewModel.items = newValue
                    multiSelectViewModel.selectedItems = multiSelectViewModel.selectedItems.intersection(Set(newValue.map { $0.id }))
                }
                .onChange(of: viewModel.messages.count) { _, _ in
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
            }
        }
        .sheet(isPresented: $showVoiceRecorder) {
            VoiceRecorderSheet(audioPreferences: audioPreferences) { transcription in
                handleTranscription(transcription)
            } onError: { message in
                voiceErrorMessage = message
            }
        }
        .sheet(item: Binding<PreviewDocumentItem?>(
            get: { selectedDocument.map { PreviewDocumentItem(document: $0) } },
            set: { if $0 == nil { selectedDocument = nil } }
        )) { item in
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
    }

    private var backgroundView: some View {
        ZStack {
            Theme.Gradients.background
                .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.Colors.primary.opacity(0.15), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 100, y: -100)
                .ignoresSafeArea()
        }
    }
    
    private var displayedMessages: [MessageResponse] {
        if searchText.isEmpty {
            return viewModel.messages
        }
        return viewModel.messages.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
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
                            conversationId: conversation.id,
                            onRegenerate: message.role == "assistant" ? regenerateHandler : nil,
                            onMessageUpdated: { _ in
                                Task {
                                    await viewModel.loadMessages(conversationId: conversation.id)
                                }
                            },
                            onBranch: {
                                Task {
                                    await viewModel.loadConversations()
                                    await viewModel.loadMessages(conversationId: conversation.id)
                                }
                            },
                            onDocumentTap: { document in
                                selectedDocument = document
                            },
                            isSelected: multiSelectViewModel.isSelected(message),
                            onTap: {
                                if multiSelectViewModel.isEditMode {
                                    multiSelectViewModel.toggleSelection(message)
                                }
                            }
                        )
                        .id(message.id)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
                    }

                    // Typing indicator when generating
                    if viewModel.isGenerating {
                        TypingIndicator()
                            .id("typing-indicator")
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
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
                .animation(Theme.Animation.smooth, value: viewModel.messages.count)
                .animation(Theme.Animation.smooth, value: viewModel.isGenerating)
                .animation(Theme.Animation.smooth, value: viewModel.followUpSuggestions)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                await viewModel.loadMessages(conversationId: conversation.id)
            }
            .onChange(of: viewModel.isGenerating) { _, isGenerating in
                if isGenerating {
                    withAnimation {
                        proxy.scrollTo("typing-indicator", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.secondary.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)

                Circle()
                    .fill(Theme.Gradients.primary)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: Theme.Colors.primary.opacity(0.4), radius: 15, x: 0, y: 8)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("Start a conversation")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.text)

                Text("Ask me anything or try one of these")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            // Suggestion chips
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: Theme.Spacing.sm
            ) {
                SuggestionChip(icon: "lightbulb.fill", text: "Brainstorm ideas", color: .yellow) {
                    messageText = "Help me brainstorm ideas for "
                    isInputFocused = true
                }
                SuggestionChip(
                    icon: "pencil.line", text: "Help me write", color: Theme.Colors.secondary
                ) {
                    messageText = "Help me write "
                    isInputFocused = true
                }
                SuggestionChip(
                    icon: "book.fill", text: "Explain a topic", color: Theme.Colors.primary
                ) {
                    messageText = "Explain how "
                    isInputFocused = true
                }
                SuggestionChip(
                    icon: "chevron.left.forwardslash.chevron.right", text: "Write code",
                    color: .green
                ) {
                    messageText = "Write code that "
                    isInputFocused = true
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var regenerateHandler: () -> Void {
        return {
            if let lastUserMessage = viewModel.messages.last(where: { $0.role == "user" }),
                let model = modelManager.selectedModel
            {
                Task {
                    await viewModel.sendMessage(
                        message: lastUserMessage.content.isEmpty
                            ? "Generated Image" : lastUserMessage.content,
                        modelId: model.modelId,
                        conversationId: conversation.id,
                        webSearchEnabled: viewModel.webSearchEnabled,
                        webSearchMode: viewModel.webSearchEnabled
                            ? viewModel.webSearchMode.rawValue : nil,
                        webSearchProvider: viewModel.webSearchEnabled
                            ? viewModel.webSearchProvider.rawValue : nil,
                        providerId: viewModel.selectedProviderId
                    )
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                viewModel.messages = []
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }

        ToolbarItem(placement: .primaryAction) {
            if multiSelectViewModel.isEditMode {
                HStack(spacing: Theme.Spacing.md) {
                    Button {
                        multiSelectViewModel.exitEditMode()
                    } label: {
                        Text("Cancel")
                            .font(.subheadline)
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)

                    Text(multiSelectViewModel.selectionDescription)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            } else {
                HStack(spacing: Theme.Spacing.md) {
                    Button {
                        withAnimation {
                            isSearchVisible.toggle()
                            if !isSearchVisible {
                                searchText = ""
                            }
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(isSearchVisible ? Theme.Colors.secondary : Theme.Colors.textSecondary)
                    }

                    Button {
                        multiSelectViewModel.enterEditMode()
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Button {
                        HapticManager.shared.tap()
                        exportConversation()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    if !assistantManager.assistants.isEmpty {
                        assistantMenu(
                            assistant: assistantManager.selectedAssistant ?? assistantManager.assistants[0])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func assistantMenu(assistant: AssistantResponse) -> some View {
        Menu {
            ForEach(assistantManager.assistants) { menuAssistant in
                Button {
                    assistantManager.selectAssistant(menuAssistant)
                } label: {
                    HStack {
                        Text(menuAssistant.name)
                        if menuAssistant.id == assistantManager.selectedAssistant?.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.Colors.secondary)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.secondary)
                Text(assistant.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.Colors.text)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private func loadData() async {
        await viewModel.loadMessages(conversationId: conversation.id)
        await modelManager.loadModels()
        await assistantManager.loadAssistants()
    }

    private func scrollToLastMessage(proxy: ScrollViewProxy) {
        if let lastMessage = displayedMessages.last {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    @ViewBuilder
    private var inputArea: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Model and Web Search Selection
            HStack(spacing: Theme.Spacing.sm) {
                // Model Selection
                if let selectedModel = modelManager.selectedModel {
                    modelSelector(model: selectedModel)
                } else if modelManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Theme.Colors.secondary)
                }

                // Check Model Capabilities
                let isImageModel = modelManager.selectedModel?.capabilities?.images == true
                let isVideoModel = modelManager.selectedModel?.capabilities?.video == true

                if isImageModel {
                    // Image Generation Settings Button
                    Button {
                        showImageSettings = true
                    } label: {
                        HStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.glassBackground)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                                    )
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.Colors.secondary)
                            }
                            Text("Image Settings")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Colors.text)
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .glassCard()
                    }
                    .sheet(isPresented: $showImageSettings) {
                        if let model = modelManager.selectedModel {
                            ImageGenerationSettingsView(
                                model: model, params: $viewModel.imageParams
                            )
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.visible)
                        }
                    }
                } else if isVideoModel {
                    // Video Generation Settings Button
                    Button {
                        showVideoSettings = true
                    } label: {
                        HStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.glassBackground)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                                    )
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.Colors.secondary)
                            }
                            Text("Video Settings")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Colors.text)
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .glassCard()
                    }
                    .sheet(isPresented: $showVideoSettings) {
                        if let model = modelManager.selectedModel {
                            VideoGenerationSettingsView(
                                model: model, params: $viewModel.videoParams
                            )
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.visible)
                        }
                    }
                } else {
                    // Standard Web Search Toggle
                    WebSearchToggle(
                        webSearchMode: $webSearchMode,
                        webSearchEnabled: $viewModel.webSearchEnabled,
                        webSearchProvider: $webSearchProvider
                    )

                    // Provider Selection Button (only show if model supports provider selection)
                    if viewModel.supportsProviderSelection {
                        providerSelectorButton
                    }
                }
            }

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
                                        .frame(width: 80, height: 80)
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
                                        .font(.title2)
                                        .foregroundStyle(Theme.Colors.secondary)
                                    Text(documentURL.lastPathComponent)
                                        .font(.caption2)
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                        .lineLimit(1)
                                }
                                .frame(width: 80, height: 80)
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
                .frame(height: 100)
            }

            // Message Input (existing)
            HStack(alignment: .bottom, spacing: Theme.Spacing.sm) {
                AttachmentButton { imageData in
                    selectedImages.append(imageData)
                } onDocumentSelected: { documentURL in
                    selectedDocuments.append(documentURL)
                } onVoiceInput: {
                    showVoiceRecorder = true
                }

                // Input field with focus glow
                TextField("Message", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .focused($isInputFocused)
                    .foregroundStyle(Theme.Colors.text)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.glassPane)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .stroke(
                                isInputFocused ? Theme.Gradients.primary : Theme.Gradients.glass,
                                lineWidth: isInputFocused ? 1.5 : 1
                            )
                    )
                    .shadow(
                        color: isInputFocused ? Theme.Colors.secondary.opacity(0.2) : .clear,
                        radius: 8,
                        x: 0,
                        y: 0
                    )
                    .animation(Theme.Animation.quick, value: isInputFocused)
                    .lineLimit(1...6)

                sendButton
            }
        }
        .padding(Theme.Spacing.lg)
        .background {
            Rectangle()
                .fill(Theme.Colors.glassPane)
        }
    }

    @ViewBuilder
    private func modelSelector(model: UserModel) -> some View {
        Button {
            showModelPicker = true
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.glassBackground)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                        )

                    Image(systemName: "cpu")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.secondary)
                }

                Text(model.name ?? model.modelId)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.text)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .frame(minWidth: 140)
            .glassCard()
            .animation(.none, value: model.modelId)
        }
        .sheet(isPresented: $showModelPicker) {
            ModelPicker(
                groupedModels: modelManager.groupedModels,
                selectedModelId: modelManager.selectedModel?.modelId
            ) { selectedModel in
                modelManager.selectModel(selectedModel)
                UserDefaults.standard.set(selectedModel.modelId, forKey: "lastUsedModel")
                showModelPicker = false
            }
            .presentationDetents([PresentationDetent.medium, PresentationDetent.large])
            .presentationDragIndicator(Visibility.visible)
        }
    }

    @ViewBuilder
    private func modelSelectorLabel(model: UserModel) -> some View {
        HStack {
            Text(model.name ?? model.modelId)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.text)

            Spacer()

            ModelCapabilityBadges(
                capabilities: model.capabilities, subscriptionIncluded: model.subscriptionIncluded
            )
            .font(.caption)

            if modelManager.selectedModel?.id == model.id {
                Image(systemName: "checkmark")
                    .foregroundStyle(Theme.Colors.secondary)
            }
        }
    }

    @ViewBuilder
    private var sendButton: some View {
        Button(action: sendMessage) {
            ZStack {
                if (messageText.isEmpty && selectedImages.isEmpty && selectedDocuments.isEmpty)
                    || viewModel.isGenerating || isUploading || modelManager.selectedModel == nil
                {
                    Circle()
                        .fill(Theme.Colors.glassBackground)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                        )

                    if isUploading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(Theme.Colors.textTertiary)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                } else {
                    Circle()
                        .fill(Theme.Gradients.primary)
                        .frame(width: 44, height: 44)
                        .shadow(color: Theme.Colors.primary.opacity(0.4), radius: 8, x: 0, y: 4)

                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(
            (messageText.isEmpty && selectedImages.isEmpty && selectedDocuments.isEmpty)
                || viewModel.isGenerating || isUploading || modelManager.selectedModel == nil
        )
        .scaleEffect((viewModel.isGenerating || isUploading) ? 0.95 : 1.0)
        .animation(.easeOut(duration: 0.2), value: viewModel.isGenerating)
        .animation(.easeOut(duration: 0.2), value: isUploading)
    }

    @ViewBuilder
    private var providerSelectorButton: some View {
        Button {
            showProviderPicker = true
        } label: {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.glassBackground)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                        )

                    Image(systemName: "server.rack")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.primary)
                }

                Text(viewModel.selectedProviderId ?? "Auto")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.text)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .glassCard()
        }
        .sheet(isPresented: $showProviderPicker) {
            ProviderPicker(
                availableProviders: viewModel.availableProviders,
                selectedProviderId: viewModel.selectedProviderId
            ) { providerId in
                viewModel.selectProvider(providerId: providerId)

                // Save this choice if a model is selected
                if let modelId = modelManager.selectedModel?.modelId, let providerId = providerId {
                    modelManager.saveLastProvider(for: modelId, providerId: providerId)
                }

                showProviderPicker = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private func sendMessage() {
        guard let model = modelManager.selectedModel,
            !messageText.isEmpty || !selectedImages.isEmpty || !selectedDocuments.isEmpty
        else { return }

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

        let webSearchEnabled = viewModel.webSearchEnabled
        let webSearchModeString = webSearchEnabled ? webSearchMode.rawValue : nil
        let webSearchProviderString = webSearchEnabled ? webSearchProvider.rawValue : nil

        let isImageModel = model.capabilities?.images == true
        let isVideoModel = model.capabilities?.video == true

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
                conversationId: conversation.id,
                webSearchEnabled: isImageModel || isVideoModel ? false : webSearchEnabled,  // Disable search for gen models
                webSearchMode: isImageModel || isVideoModel ? nil : webSearchModeString,
                webSearchProvider: isImageModel || isVideoModel ? nil : webSearchProviderString,
                providerId: isImageModel || isVideoModel ? nil : viewModel.selectedProviderId,  // Disable provider check if desired, or keep it
                images: uploadedImages.isEmpty ? nil : uploadedImages,
                documents: uploadedDocuments.isEmpty ? nil : uploadedDocuments,
                imageParams: isImageModel ? viewModel.imageParams : nil,
                videoParams: isVideoModel ? viewModel.videoParams : nil
            )

            // Generate follow-up questions after message generation completes
            // Only for text models (not image/video generation)
            if !isImageModel && !isVideoModel,
                let lastMessage = viewModel.messages.last,
                lastMessage.role == "assistant",
                lastMessage.content.count > 100
            {
                await viewModel.fetchFollowUpQuestions(
                    conversationId: conversation.id,
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

    // MARK: - Message Batch Operations

    private var messageBatchOperationsBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button {
                batchCopyMessages()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(Theme.Colors.primary)

            Button {
                batchExportMessages()
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(Theme.Colors.secondary)

            Button {
                Task {
                    await batchToggleStar()
                }
            } label: {
                Label("Star", systemImage: "star.fill")
                    .font(.caption)
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
            let combinedContent = selectedMessages
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
        await viewModel.loadMessages(conversationId: conversation.id)
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
    let onTap: () -> Void

    @State private var isReasoningExpanded = false
    @State private var showCopyFeedback = false
    @State private var userRating: MessageRating?
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
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                avatarView
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    headerView
                    mediaAttachmentsView
                    reasoningView
                    messageContentView
                    footerView
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }
                .background(isSelected ? Theme.Colors.secondary.opacity(0.1) : Color.clear)
            }
            
            // Selection indicator
            if isSelected {
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
                    // Long press to enter edit mode is handled at parent level
                    HapticManager.shared.longPressActivated()
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
        Circle()
            .fill(
                message.role == "user"
                    ? Theme.Colors.userBubbleGradient
                    : LinearGradient(
                        colors: [Theme.Colors.secondary, Theme.Colors.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: message.role == "user" ? "person.fill" : "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            )
    }
    
    private var headerView: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(message.role == "user" ? "You" : "Assistant")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Colors.text)

            Spacer()

            Button {
                toggleStarred()
            } label: {
                if isStarring {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(Theme.Colors.secondary)
                } else {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundStyle(
                            isStarred ? Theme.Colors.secondary : Theme.Colors.textTertiary)
                }
            }
            .buttonStyle(.plain)
            .disabled(isStarring)

            if message.role == "assistant" {
                Button {
                    Task {
                        await toggleSpeechPlayback()
                    }
                } label: {
                    if isSynthesizingSpeech
                        || audioPlayback.isLoadingMessageId == message.id
                    {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(Theme.Colors.secondary)
                    } else {
                        Image(
                            systemName: audioPlayback.currentlyPlayingMessageId
                                == message.id
                                ? "stop.fill" : "speaker.wave.2"
                        )
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
                .buttonStyle(.plain)
            }

            if let model = message.modelId {
                Text(model)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
    }
    
    @ViewBuilder
    private var mediaAttachmentsView: some View {
        // Display attached and inline-detected images
        if !allImages.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(allImages) { imageItem in
                        Button {
                            selectedImage = imageItem
                            HapticManager.shared.selection()
                        } label: {
                            AsyncImage(url: imageItem.url) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                        .fill(Theme.Colors.glassBackground)
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            ProgressView()
                                                .tint(Theme.Colors.secondary)
                                        )
                                case .success(let loadedImage):
                                    loadedImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: Theme.CornerRadius.sm))
                                case .failure:
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                        .fill(Theme.Colors.glassBackground)
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundStyle(Theme.Colors.textTertiary)
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                    .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
        }

        // Display inline-detected videos (generated content URLs)
        if !inlineVideoURLs.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(inlineVideoURLs, id: \.absoluteString) { videoURL in
                    let player = player(for: videoURL)
                    VideoPlayer(player: player)
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                        )
                        .onAppear {
                            cachePlayer(player, for: videoURL)
                        }
                        .onDisappear {
                            player.pause()
                            player.replaceCurrentItem(with: nil)
                            videoPlayers.removeValue(forKey: videoURL.absoluteString)
                        }
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
        }

        // Display attached documents
        if let documents = message.documents, !documents.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                ForEach(documents, id: \.storageId) { document in
                    Button {
                        HapticManager.shared.tap()
                        onDocumentTap?(document)
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: documentIcon(for: document.fileType))
                                .font(.title3)
                                .foregroundStyle(Theme.Colors.secondary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(document.fileName ?? "Document")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.text)
                                    .lineLimit(1)

                                Text(document.fileType.uppercased())
                                    .font(.caption2)
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.glassPane)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .strokeBorder(Theme.Gradients.glass, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
    }
    
    @ViewBuilder
    private var reasoningView: some View {
        if let reasoning = message.reasoning, !reasoning.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isReasoningExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                        Text("Reasoning")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Image(
                            systemName: isReasoningExpanded ? "chevron.up" : "chevron.down"
                        )
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
                .buttonStyle(.plain)

                if isReasoningExpanded {
                    Text(reasoning)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(Theme.Spacing.sm)
                        .glassCard()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
    
    @ViewBuilder
    private var messageContentView: some View {
        if isEditing {
            VStack(spacing: Theme.Spacing.sm) {
                TextEditor(text: $editedContent)
                    .font(.body)
                    .foregroundStyle(Theme.Colors.text)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.glassPane)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .strokeBorder(Theme.Gradients.glass, lineWidth: 1)
                    )
                    .frame(minHeight: 100)

                HStack(spacing: Theme.Spacing.sm) {
                    Button {
                        saveEdit()
                    } label: {
                        Label("Save", systemImage: "checkmark")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isSaving)

                    Button {
                        isEditing = false
                        editedContent = ""
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
        } else {
            MessageContent(content: message.content)
                .padding(Theme.Spacing.md)
                .glassCard()
                .contextMenu {
                    Button {
                        HapticManager.shared.tap()
                        startEditing()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    if message.role == "assistant" {
                        Button {
                            HapticManager.shared.tap()
                            onRegenerate?()
                        } label: {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                        }
                    }

                    Button {
                        HapticManager.shared.tap()
                        UIPasteboard.general.string = message.content
                        withAnimation {
                            showCopyFeedback = true
                        }
                        HapticManager.shared.success()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation {
                                showCopyFeedback = false
                            }
                        }
                    } label: {
                        Label(
                            showCopyFeedback ? "Copied!" : "Copy",
                            systemImage: showCopyFeedback ? "checkmark" : "doc.on.doc")
                    }

                    Button {
                        HapticManager.shared.tap()
                        shareMessage()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
        }
    }
    
    @ViewBuilder
    private var footerView: some View {
        if message.role == "assistant" {
            HStack(spacing: Theme.Spacing.sm) {
                Button {
                    rateMessage(.thumbsUp)
                } label: {
                    Image(
                        systemName: userRating == .thumbsUp
                            ? "hand.thumbsup.fill" : "hand.thumbsup"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        userRating == .thumbsUp
                            ? Theme.Colors.secondary : Theme.Colors.textTertiary)
                }
                .buttonStyle(.plain)

                Button {
                    rateMessage(.thumbsDown)
                } label: {
                    Image(
                        systemName: userRating == .thumbsDown
                            ? "hand.thumbsdown.fill" : "hand.thumbsdown"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        userRating == .thumbsDown
                            ? Theme.Colors.secondary : Theme.Colors.textTertiary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    branchConversation()
                } label: {
                    if isBranching {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isBranching)
            }
            .padding(.horizontal, Theme.Spacing.xs)
        }
    }
    
    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .fill(Theme.Colors.secondary)
                .frame(width: 20, height: 20)

            Image(systemName: "checkmark")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .padding(Theme.Spacing.xs)
        .transition(.scale.combined(with: .opacity))
    }



    private func toggleSpeechPlayback() async {
        guard message.role == "assistant" else { return }

        if audioPlayback.currentlyPlayingMessageId == message.id {
            audioPlayback.stop()
            return
        }

        let text = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isSynthesizingSpeech = true
        audioPlayback.isLoadingMessageId = message.id

        defer {
            isSynthesizingSpeech = false
            audioPlayback.isLoadingMessageId = nil
        }

        do {
            let result = try await NanoChatAPI.shared.textToSpeech(
                text: text,
                model: audioPreferences.ttsModel,
                voice: audioPreferences.ttsVoice,
                speed: audioPreferences.ttsSpeed
            )
            let data = try await resolveSpeechData(from: result)
            try audioPlayback.play(data: data, messageId: message.id)
        } catch {
            speechErrorMessage = error.localizedDescription
        }
    }

    private func resolveSpeechData(from result: TTSResult) async throws -> Data {
        switch result {
        case .audioData(let data):
            return data
        case .audioUrl(let url):
            return try await NanoChatAPI.shared.fetchAudioData(from: url)
        case .pending(let ticket):
            let url = try await pollTTSStatus(ticket)
            return try await NanoChatAPI.shared.fetchAudioData(from: url)
        }
    }

    private func pollTTSStatus(_ ticket: TTSPendingTicket) async throws -> URL {
        let maxAttempts = 60
        let interval: UInt64 = 3_000_000_000

        for _ in 0..<maxAttempts {
            let status = try await NanoChatAPI.shared.fetchTTSStatus(ticket: ticket)
            if status.status == "completed", let audioUrl = status.audioUrl,
                let url = URL(string: audioUrl)
            {
                return url
            }

            if status.status == "error" {
                throw APIError.invalidResponse
            }

            try await Task.sleep(nanoseconds: interval)
        }

        throw APIError.invalidResponse
    }

    private func startEditing() {
        editedContent = message.content
        withAnimation {
            isEditing = true
        }
    }

    private func saveEdit() {
        guard !editedContent.isEmpty else { return }

        isSaving = true

        Task {
            do {
                _ = try await NanoChatAPI.shared.updateMessageContent(
                    messageId: message.id,
                    content: editedContent
                )

                // Create updated message
                let updatedMessage = message
                // Note: In a real app, you'd get the full updated message from the API
                // For now, we'll trigger a reload from the parent

                await MainActor.run {
                    isSaving = false
                    isEditing = false
                    onMessageUpdated?(updatedMessage)
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }

    private func branchConversation() {
        isBranching = true

        Task {
            do {
                _ = try await NanoChatAPI.shared.branchConversation(
                    conversationId: conversationId,
                    fromMessageId: message.id
                )

                await MainActor.run {
                    isBranching = false
                    onBranch?()
                }
            } catch {
                await MainActor.run {
                    isBranching = false
                }
            }
        }
    }

    private func toggleStarred() {
        guard !isStarring else { return }
        let nextValue = !isStarred
        isStarred = nextValue
        isStarring = true
        HapticManager.shared.selection()

        Task {
            do {
                _ = try await NanoChatAPI.shared.setMessageStarred(
                    messageId: message.id,
                    starred: nextValue
                )
                await MainActor.run {
                    HapticManager.shared.success()
                    isStarring = false
                    onMessageUpdated?(message)
                }
            } catch {
                await MainActor.run {
                    HapticManager.shared.error()
                    isStarred.toggle()
                    isStarring = false
                }
            }
        }
    }

    private func rateMessage(_ rating: MessageRating) {
        let newRating: MessageRating? = userRating == rating ? nil : rating
        let apiThumb: MessageThumbsRating? = switch newRating {
        case .thumbsUp: .up
        case .thumbsDown: .down
        case nil: nil
        }

        withAnimation {
            userRating = newRating
        }
        HapticManager.shared.selection()

        Task {
            do {
                _ = try await NanoChatAPI.shared.rateMessage(
                    messageId: message.id,
                    thumbs: apiThumb
                )
            } catch {
                // Revert on failure
                await MainActor.run {
                    withAnimation {
                        userRating = userRating == newRating ? (rating == .thumbsUp ? .thumbsDown : .thumbsUp) : userRating
                    }
                }
            }
        }
    }

    // Inline media helpers
    private var inlineImageURLs: [URL] {
        detectedURLs.filter { imageExtensions.contains($0.pathExtension.lowercased()) }
    }

    private var inlineVideoURLs: [URL] {
        detectedURLs.filter { videoExtensions.contains($0.pathExtension.lowercased()) }
    }

    private var allImages: [ImagePreviewItem] {
        var items: [ImagePreviewItem] = []

        if let images = message.images {
            for image in images {
                if let url = URL(string: resolveStorageURL(image.url)) {
                    let name =
                        image.fileName?.trimmingCharacters(in: .whitespacesAndNewlines)
                        ?? url.lastPathComponent
                    items.append(
                        ImagePreviewItem(
                            url: url,
                            fileName: name.isEmpty ? "image" : name
                        )
                    )
                }
            }
        }

        for url in inlineImageURLs {
            let name = url.lastPathComponent
            items.append(ImagePreviewItem(url: url, fileName: name.isEmpty ? "image" : name))
        }

        var seen: Set<String> = []
        return items.filter { item in
            let key = item.url.absoluteString
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    private var detectedURLs: [URL] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches =
            detector?.matches(
                in: message.content,
                options: [],
                range: NSRange(location: 0, length: message.content.utf16.count)
            ) ?? []

        return matches.compactMap { match in
            guard let range = Range(match.range, in: message.content) else { return nil }
            let raw = String(message.content[range])
            let resolved = resolveStorageURL(raw)
            return URL(string: resolved)
        }
    }

    private func player(for url: URL) -> AVPlayer {
        videoPlayers[url.absoluteString] ?? AVPlayer(url: url)
    }

    private func cachePlayer(_ player: AVPlayer, for url: URL) {
        videoPlayers[url.absoluteString] = player
    }

    private func resolveStorageURL(_ url: String) -> String {
        // If URL is relative (starts with /), prepend the base URL
        if url.hasPrefix("/") {
            return APIConfiguration.shared.baseURL + url
        }
        return url
    }

    private func documentIcon(for fileType: String) -> String {
        switch fileType.lowercased() {
        case "pdf":
            return "doc.fill"
        case "markdown", "md":
            return "doc.text.fill"
        case "epub":
            return "book.fill"
        default:
            return "doc.plaintext.fill"
        }
    }

    private var imageExtensions: Set<String> {
        ["png", "jpg", "jpeg", "gif", "webp", "heic", "heif"]
    }

    private var videoExtensions: Set<String> {
        ["mp4", "mov", "m4v", "webm"]
    }

    private func shareMessage() {
        let activityViewController = UIActivityViewController(
            activityItems: [message.content],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
    }
}

struct VoiceRecorderSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var audioPreferences: AudioPreferences
    let onTranscription: (String) -> Void
    let onError: (String) -> Void

    @StateObject private var recorder = AudioRecorder()
    @State private var isTranscribing = false
    @State private var hasPermission = true

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("Voice Input")
                        .font(.title3)
                        .foregroundStyle(Theme.Colors.text)

                    Text(hasPermission ? formattedTime : "Microphone access required")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Button {
                    handleRecordToggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                recorder.isRecording
                                    ? AnyShapeStyle(Theme.Colors.error)
                                    : AnyShapeStyle(Theme.Gradients.primary)
                            )
                            .frame(width: 72, height: 72)

                        Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!hasPermission || isTranscribing)

                if isTranscribing {
                    ProgressView("Transcribing...")
                        .tint(Theme.Colors.secondary)
                }

                Spacer()

                HStack(spacing: Theme.Spacing.md) {
                    Button("Cancel") {
                        recorder.reset()
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button("Transcribe") {
                        Task {
                            await transcribeRecording()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(recorder.lastRecordingURL == nil || isTranscribing)
                }
            }
            .padding(Theme.Spacing.xl)
            .background(Theme.Gradients.background)
            .navigationTitle("Voice Input")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                hasPermission = await recorder.requestPermission()
                if !hasPermission {
                    onError("Microphone access is required to record audio.")
                }
            }
        }
    }

    private var formattedTime: String {
        let totalSeconds = Int(recorder.elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func handleRecordToggle() {
        if recorder.isRecording {
            Task {
                _ = await recorder.stopRecording()
            }
        } else {
            do {
                try recorder.startRecording()
            } catch {
                onError("Failed to start recording: \(error.localizedDescription)")
            }
        }
    }

    private func transcribeRecording() async {
        guard let url = await recorder.stopRecording() else { return }
        isTranscribing = true

        defer {
            isTranscribing = false
        }

        do {
            let response = try await NanoChatAPI.shared.transcribeAudio(
                fileURL: url,
                model: audioPreferences.sttModel,
                language: audioPreferences.sttLanguage
            )

            let transcription = response.transcription ?? response.text ?? ""
            if transcription.isEmpty {
                onError("Transcription returned empty text.")
                return
            }

            onTranscription(transcription)
            dismiss()
        } catch {
            onError("Transcription failed: \(error.localizedDescription)")
        }
    }
}

enum MessageRating {
    case thumbsUp
    case thumbsDown
}

// MARK: - Suggestion Chip Component

struct SuggestionChip: View {
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.shared.lightTap()
            action()
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.text)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .padding(.horizontal, Theme.Spacing.md)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(Theme.Colors.glassBorder, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Button style that provides scale feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Document Preview Helper

struct PreviewDocumentItem: Identifiable {
    let id = UUID()
    let document: MessageDocumentResponse
}

// MARK: - Typing Indicator

/// Animated typing indicator that shows when AI is generating a response
struct TypingIndicator: View {
    @State private var animatingDot1 = false
    @State private var animatingDot2 = false
    @State private var animatingDot3 = false
    @State private var glowOpacity: Double = 0.3

    let animationDuration: Double = 0.5

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Avatar (matches assistant avatar)
            ZStack {
                Circle()
                    .fill(Theme.Colors.secondary.opacity(glowOpacity))
                    .frame(width: 40, height: 40)
                    .blur(radius: 10)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.secondary, Theme.Colors.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    )
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Assistant")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.text)

                // Typing dots container
                HStack(spacing: 6) {
                    TypingDot(isAnimating: animatingDot1)
                    TypingDot(isAnimating: animatingDot2)
                    TypingDot(isAnimating: animatingDot3)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.glassPane)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                        .strokeBorder(Theme.Gradients.glass, lineWidth: 1)
                )
            }

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        withAnimation(
            .easeInOut(duration: animationDuration)
                .repeatForever(autoreverses: true)
        ) {
            animatingDot1 = true
        }

        withAnimation(
            .easeInOut(duration: animationDuration)
                .repeatForever(autoreverses: true)
                .delay(0.15)
        ) {
            animatingDot2 = true
        }

        withAnimation(
            .easeInOut(duration: animationDuration)
                .repeatForever(autoreverses: true)
                .delay(0.3)
        ) {
            animatingDot3 = true
        }

        withAnimation(
            .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
        ) {
            glowOpacity = 0.6
        }
    }
}

/// Individual animated dot for typing indicator
struct TypingDot: View {
    let isAnimating: Bool

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Theme.Colors.secondary, Theme.Colors.primary],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 8, height: 8)
            .offset(y: isAnimating ? -4 : 2)
            .opacity(isAnimating ? 1.0 : 0.5)
    }
}

struct MessageContent: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            ForEach(parseContent(content)) { segment in
                switch segment.type {
                case .text:
                    if !segment.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // Apply custom header styling for H1 and H2
                        if let headerLevel = segment.headerLevel {
                            Text(segment.content.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces))
                                .font(headerLevel == 1 ? .title2 : .title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.Colors.text)
                                .padding(.top, 4)
                                .padding(.bottom, 2)
                                .overlay(
                                    Rectangle()
                                        .fill(Theme.Colors.glassBorder)
                                        .frame(height: 1),
                                    alignment: .bottom
                                )
                        } else {
                            Text(safeAttributedString(from: segment.content))
                                .font(.body)
                                .foregroundStyle(Theme.Colors.text)
                                .textSelection(.enabled)
                        }
                    }
                case .code(let language):
                    CodeBlockView(code: segment.content, language: language)
                }
            }
        }
    }
    
    private func safeAttributedString(from markdown: String) -> AttributedString {
        do {
            let attributed = try AttributedString(markdown: markdown)
            return attributed
        } catch {
            return AttributedString(markdown)
        }
    }
    
    private func parseContent(_ content: String) -> [MessageSegment] {
        var segments: [MessageSegment] = []
        let lines = content.components(separatedBy: .newlines)
        var currentText = ""
        var inCodeBlock = false
        var codeBlockLanguage: String?
        var codeBlockContent = ""
        
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if inCodeBlock {
                    // End of code block
                    if !currentText.isEmpty {
                        segments.append(MessageSegment(type: .text, content: currentText))
                        currentText = ""
                    }
                    segments.append(MessageSegment(type: .code(language: codeBlockLanguage), content: codeBlockContent.trimmingCharacters(in: .newlines)))
                    codeBlockContent = ""
                    inCodeBlock = false
                    codeBlockLanguage = nil
                } else {
                    // Start of code block
                    if !currentText.isEmpty {
                        segments.append(MessageSegment(type: .text, content: currentText))
                        currentText = ""
                    }
                    inCodeBlock = true
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.count > 3 {
                        codeBlockLanguage = String(trimmed.dropFirst(3))
                    }
                }
            } else if inCodeBlock {
                codeBlockContent += line + "\n"
            } else {
                // Header detection (Basic H1/H2)
                // Note: This is a simple line-based parser. It might split paragraphs if not careful.
                // For better robustness, we should group non-header lines.
                if line.hasPrefix("# ") || line.hasPrefix("## ") {
                    if !currentText.isEmpty {
                        segments.append(MessageSegment(type: .text, content: currentText))
                        currentText = ""
                    }
                    let level = line.hasPrefix("## ") ? 2 : 1
                    segments.append(MessageSegment(type: .text, content: line, headerLevel: level))
                } else {
                    currentText += line + "\n"
                }
            }
        }
        
        if !currentText.isEmpty {
            segments.append(MessageSegment(type: .text, content: currentText))
        }
        
        return segments
    }
}

struct MessageSegment: Identifiable {
    let id = UUID()
    let type: SegmentType
    let content: String
    var headerLevel: Int? = nil
    
    enum SegmentType {
        case text
        case code(language: String?)
    }
}

struct CodeBlockView: View {
    let code: String
    let language: String?
    @State private var isCopied = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(language?.isEmpty == false ? language! : "code")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = code
                    HapticManager.shared.success()
                    withAnimation {
                        isCopied = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isCopied = false
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied" : "Copy")
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.4))
            
            // Code with basic syntax highlighting
            ScrollView(.horizontal, showsIndicators: true) {
                // Use a ZStack to layer syntax highlighted text over the original text (hidden) for sizing
                // or just construct an AttributedString
                Text(syntaxHighlight(code))
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(Theme.Colors.text)
                    .padding(12)
                    .frame(minWidth: 100, alignment: .leading)
            }
            .background(Color(red: 0.1, green: 0.1, blue: 0.12)) // Darker code background
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Colors.glassBorder, lineWidth: 1)
        )
    }
    
    private func syntaxHighlight(_ code: String) -> AttributedString {
        var attributed = AttributedString(code)
        attributed.foregroundColor = .white
        
        // Basic keywords
        let keywords = ["import", "from", "class", "struct", "func", "var", "let", "if", "else", "return", "true", "false", "nil", "const", "await", "async", "try", "catch", "case", "switch", "default", "public", "private", "static", "void", "int", "float", "double", "string", "bool", "new"]
        
        // Helper to convert NSRange to AttributedString range
        func applyColor(_ color: Color, to matches: [NSTextCheckingResult]) {
            for match in matches {
                let range = match.range
                if let stringRange = Range(range, in: code) {
                    let startOffset = code.distance(from: code.startIndex, to: stringRange.lowerBound)
                    let length = code.distance(from: stringRange.lowerBound, to: stringRange.upperBound)
                    
                    let startIndex = attributed.index(attributed.startIndex, offsetByCharacters: startOffset)
                    let endIndex = attributed.index(startIndex, offsetByCharacters: length)
                    
                    attributed[startIndex..<endIndex].foregroundColor = color
                }
            }
        }
        
        // 1. Comments
        if let commentRegex = try? NSRegularExpression(pattern: "//.*") {
            let matches = commentRegex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            applyColor(.gray, to: matches)
        }
        
        // 2. Keywords
        for keyword in keywords {
            if let regex = try? NSRegularExpression(pattern: "\\b\(keyword)\\b") {
                let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
                applyColor(Color(red: 1.0, green: 0.4, blue: 0.6), to: matches)
            }
        }
        
        // 3. Strings
        if let stringRegex = try? NSRegularExpression(pattern: "\"[^\"]*\"|'[^']*'|`[^`]*`") {
            let matches = stringRegex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            applyColor(Color(red: 0.6, green: 0.8, blue: 0.4), to: matches)
        }
        
        // 4. Function calls
        if let callRegex = try? NSRegularExpression(pattern: "\\b\\w+(?=\\()") {
            let matches = callRegex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            applyColor(Color(red: 0.4, green: 0.7, blue: 1.0), to: matches)
        }
        
        return attributed
    }
}

#Preview {
    NavigationStack {
        ChatView(
            conversation: ConversationResponse(
                id: "1",
                title: "Test Chat",
                userId: "user1",
                projectId: nil,
                pinned: false,
                generating: false,
                costUsd: nil,
                createdAt: .now,
                updatedAt: .now,
                isPublic: false
            ), onMessageSent: nil)
    }
    .preferredColorScheme(.dark)
}
