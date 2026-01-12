import SwiftUI

struct ChatView: View {
    let conversation: ConversationResponse
    let onMessageSent: (() -> Void)?
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var modelManager = ModelManager()
    @State private var assistantManager = AssistantManager()
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    @State private var webSearchMode: WebSearchMode = .off
    @State private var webSearchProvider: WebSearchProvider = .linkup
    @State private var selectedImages: [Data] = []
    @State private var selectedDocuments: [URL] = []
    @State private var isUploading = false
    @State private var showProviderPicker = false
    @State private var showModelPicker = false

    var body: some View {
        ZStack {
            backgroundView

            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    messagesView(proxy: proxy)
                    inputArea
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
                                if viewModel.availableProviders.contains(where: { $0.provider == lastProvider }) {
                                    viewModel.selectProvider(providerId: lastProvider)
                                }
                            }
                        }
                    }
                }
            }
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

    @ViewBuilder
    private func messagesView(proxy: ScrollViewProxy) -> some View {
        if viewModel.messages.isEmpty && !viewModel.isGenerating {
            Spacer()
            emptyStateView
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.lg) {
                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
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
                            }
                        )
                        .id(message.id)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                    }

                    // Typing indicator when generating
                    if viewModel.isGenerating {
                        TypingIndicator()
                            .id("typing-indicator")
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
                .animation(Theme.Animation.smooth, value: viewModel.messages.count)
                .animation(Theme.Animation.smooth, value: viewModel.isGenerating)
            }
            .scrollDismissesKeyboard(.interactively)
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
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.sm) {
                SuggestionChip(icon: "lightbulb.fill", text: "Brainstorm ideas", color: .yellow) {
                    messageText = "Help me brainstorm ideas for "
                    isInputFocused = true
                }
                SuggestionChip(icon: "pencil.line", text: "Help me write", color: Theme.Colors.secondary) {
                    messageText = "Help me write "
                    isInputFocused = true
                }
                SuggestionChip(icon: "book.fill", text: "Explain a topic", color: Theme.Colors.primary) {
                    messageText = "Explain how "
                    isInputFocused = true
                }
                SuggestionChip(icon: "chevron.left.forwardslash.chevron.right", text: "Write code", color: .green) {
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
               let model = modelManager.selectedModel {
                Task {
                    await viewModel.sendMessage(
                        message: lastUserMessage.content,
                        modelId: model.modelId,
                        conversationId: conversation.id,
                        webSearchEnabled: viewModel.webSearchEnabled,
                        webSearchMode: viewModel.webSearchEnabled ? viewModel.webSearchMode.rawValue : nil,
                        webSearchProvider: viewModel.webSearchEnabled ? viewModel.webSearchProvider.rawValue : nil,
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
            if !assistantManager.assistants.isEmpty {
                assistantMenu(assistant: assistantManager.selectedAssistant ?? assistantManager.assistants[0])
            }
        }
    }

    @ViewBuilder
    private func assistantMenu(assistant: AssistantResponse) -> some View {
        Menu {
            ForEach(assistantManager.assistants) { assistant in
                Button {
                    assistantManager.selectAssistant(assistant)
                } label: {
                    HStack {
                        Text(assistant.name)
                        if assistant.id == assistant.id {
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
        if let lastMessage = viewModel.messages.last {
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

                // Web Search Toggle
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

            // Attachment previews
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
                                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
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

                        ForEach(Array(selectedDocuments.enumerated()), id: \.offset) { _, documentURL in
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

            // Message Input
            HStack(alignment: .bottom, spacing: Theme.Spacing.sm) {
                AttachmentButton { imageData in
                    selectedImages.append(imageData)
                } onDocumentSelected: { documentURL in
                    selectedDocuments.append(documentURL)
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
        .background(Theme.Colors.glassPane)
        .ignoresSafeArea(.container, edges: .bottom)
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

            ModelCapabilityBadges(capabilities: model.capabilities, subscriptionIncluded: model.subscriptionIncluded)
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
                if (messageText.isEmpty && selectedImages.isEmpty && selectedDocuments.isEmpty) || viewModel.isGenerating || isUploading || modelManager.selectedModel == nil {
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
        .disabled((messageText.isEmpty && selectedImages.isEmpty && selectedDocuments.isEmpty) || viewModel.isGenerating || isUploading || modelManager.selectedModel == nil)
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
              !messageText.isEmpty || !selectedImages.isEmpty || !selectedDocuments.isEmpty else { return }

        // Haptic feedback on send
        HapticManager.shared.tap()

        isInputFocused = false
        let currentMessage = messageText
        let currentImages = selectedImages
        let currentDocuments = selectedDocuments

        messageText = ""
        selectedImages = []
        selectedDocuments = []

        let webSearchEnabled = viewModel.webSearchEnabled
        let webSearchModeString = webSearchEnabled ? webSearchMode.rawValue : nil
        let webSearchProviderString = webSearchEnabled ? webSearchProvider.rawValue : nil

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
                        print("Uploaded image: \(attachment.storageId)")
                    } catch {
                        print("Failed to upload image: \(error)")
                    }
                }

                // Upload documents
                for documentURL in currentDocuments {
                    do {
                        let attachment = try await NanoChatAPI.shared.uploadDocument(url: documentURL)
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
                webSearchEnabled: webSearchEnabled,
                webSearchMode: webSearchModeString,
                webSearchProvider: webSearchProviderString,
                providerId: viewModel.selectedProviderId,
                images: uploadedImages.isEmpty ? nil : uploadedImages,
                documents: uploadedDocuments.isEmpty ? nil : uploadedDocuments
            )

            onMessageSent?()
        }
    }
}

struct MessageBubble: View {
    let message: MessageResponse
    let conversationId: String
    let onRegenerate: (() -> Void)?
    let onMessageUpdated: ((MessageResponse) -> Void)?
    let onBranch: (() -> Void)?
    @State private var isReasoningExpanded = false
    @State private var showCopyFeedback = false
    @State private var userRating: MessageRating?
    @State private var isEditing = false
    @State private var editedContent = ""
    @State private var isSaving = false
    @State private var isBranching = false

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Avatar
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

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Header
                HStack(spacing: Theme.Spacing.xs) {
                    Text(message.role == "user" ? "You" : "Assistant")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Colors.text)

                    Spacer()

                    if let model = message.modelId {
                        Text(model)
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                // Display attached images
                if let images = message.images, !images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(images, id: \.storageId) { image in
                                AsyncImage(url: URL(string: resolveStorageURL(image.url))) { phase in
                                    switch phase {
                                    case .empty:
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                            .fill(Theme.Colors.glassBackground)
                                            .frame(width: 120, height: 120)
                                            .overlay(ProgressView().tint(Theme.Colors.secondary))
                                    case .success(let loadedImage):
                                        loadedImage
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
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
                        }
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                }

                // Display attached documents
                if let documents = message.documents, !documents.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        ForEach(documents, id: \.storageId) { document in
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
                            }
                            .padding(Theme.Spacing.sm)
                            .background(Theme.Colors.glassPane)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                    .strokeBorder(Theme.Gradients.glass, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                }

                // Reasoning Dropdown (if available)
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
                                Image(systemName: isReasoningExpanded ? "chevron.up" : "chevron.down")
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

                // Main message content with markdown support
                Group {
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
                        Text(attributedString)
                            .font(.body)
                            .foregroundStyle(Theme.Colors.text)
                            .textSelection(.enabled)
                            .padding(Theme.Spacing.md)
                            .glassCard()
                            .contextMenu {
                                Button {
                                    startEditing()
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                if message.role == "assistant" {
                                    Button {
                                        onRegenerate?()
                                    } label: {
                                        Label("Regenerate", systemImage: "arrow.clockwise")
                                    }
                                }

                                Button {
                                    UIPasteboard.general.string = message.content
                                    withAnimation {
                                        showCopyFeedback = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        withAnimation {
                                            showCopyFeedback = false
                                        }
                                    }
                                } label: {
                                    Label(showCopyFeedback ? "Copied!" : "Copy", systemImage: showCopyFeedback ? "checkmark" : "doc.on.doc")
                                }
                            }
                    }
                }

                // Rating section (for assistant messages)
                if message.role == "assistant" {
                    HStack(spacing: Theme.Spacing.sm) {
                        Button {
                            withAnimation {
                                userRating = userRating == .thumbsUp ? nil : .thumbsUp
                            }
                        } label: {
                            Image(systemName: userRating == .thumbsUp ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .font(.caption)
                                .foregroundStyle(userRating == .thumbsUp ? Theme.Colors.secondary : Theme.Colors.textTertiary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            withAnimation {
                                userRating = userRating == .thumbsDown ? nil : .thumbsDown
                            }
                        } label: {
                            Image(systemName: userRating == .thumbsDown ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                .font(.caption)
                                .foregroundStyle(userRating == .thumbsDown ? Theme.Colors.secondary : Theme.Colors.textTertiary)
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var attributedString: AttributedString {
        do {
            let attributed = try AttributedString(
                markdown: message.content,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            )
            return attributed
        } catch {
            return AttributedString(message.content)
        }
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
                print("Error updating message: \(error)")
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
                print("Error branching conversation: \(error)")
                await MainActor.run {
                    isBranching = false
                }
            }
        }
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

#Preview {
    NavigationStack {
        ChatView(conversation: ConversationResponse(
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
