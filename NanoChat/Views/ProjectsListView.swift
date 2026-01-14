import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct ProjectsListView: View {
    @State private var projects: [ProjectResponse] = []
    @State private var isLoading = false
    @State private var showingNewProject = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Theme.Gradients.background
                .ignoresSafeArea()

            NavigationStack {
                Group {
                    if isLoading && projects.isEmpty {
                        ProgressView()
                            .tint(Theme.Colors.secondary)
                    } else if projects.isEmpty {
                        ContentUnavailableView {
                            Label("No Projects", systemImage: "folder")
                                .foregroundStyle(Theme.Colors.textSecondary)
                        } description: {
                            Text("Create projects to organize your conversations")
                                .foregroundStyle(Theme.Colors.textTertiary)
                        } actions: {
                            Button("Create Project") {
                                showingNewProject = true
                            }
                            .buttonStyle(LiquidGlassButtonStyle())
                        }
                    } else {
                        GlassList {
                            ForEach(projects, id: \.id) { project in
                                GlassListRow {
                                    NavigationLink {
                                        ProjectDetailView(
                                            project: project,
                                            onUpdate: { updatedProject in
                                                if let index = projects.firstIndex(where: {
                                                    $0.id == updatedProject.id
                                                }) {
                                                    projects[index] = updatedProject
                                                } else {
                                                    projects.append(updatedProject)
                                                }
                                                projects.sort { $0.updatedAt > $1.updatedAt }
                                            },
                                            onDelete: { deletedId in
                                                projects.removeAll { $0.id == deletedId }
                                            }
                                        )
                                    } label: {
                                        ProjectRow(project: project)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Projects")
                .navigationBarTitleDisplayMode(.large)
                .liquidGlassNavigationBar()
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showingNewProject = true }) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Gradients.primary)
                                    .frame(width: 36, height: 36)
                                    .shadow(
                                        color: Theme.Colors.primary.opacity(0.4), radius: 6, x: 0,
                                        y: 3)

                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingNewProject) {
                    NewProjectView { project in
                        Task {
                            await createProject(project)
                        }
                    }
                }
                .task {
                    await loadProjects()
                }
                .refreshable {
                    await loadProjects()
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

    private func loadProjects() async {
        isLoading = true
        defer { isLoading = false }

        do {
            projects = try await NanoChatAPI.shared.getProjects()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createProject(_ project: CreateProjectRequest) async {
        do {
            let newProject = try await NanoChatAPI.shared.createProject(
                name: project.name,
                description: project.description,
                systemPrompt: project.systemPrompt,
                color: project.color
            )
            projects.append(newProject)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ProjectRow: View {
    let project: ProjectResponse

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Color circle with shadow
            ZStack {
                Circle()
                    .fill(Color(hex: project.color ?? "#007AFF").opacity(0.3))
                    .frame(width: 48, height: 48)
                    .blur(radius: 8)

                Circle()
                    .fill(Color(hex: project.color ?? "#007AFF"))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "folder.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.9))
                    )
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(project.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.Colors.text)
                        .lineLimit(1)

                    Spacer()

                    Text(project.role.capitalized)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Theme.Colors.glassBackground)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .clipShape(Capsule())
                }

                if let description = project.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

struct ProjectDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var project: ProjectResponse
    @State private var conversations: [ConversationResponse] = []
    @State private var isLoadingConversations = false
    @State private var isCreatingConversation = false
    @State private var members: [ProjectMemberResponse] = []
    @State private var isLoadingMembers = false
    @State private var files: [ProjectFileResponse] = []
    @State private var isLoadingFiles = false
    @State private var isUploadingFile = false
    @State private var fileToPreview: ProjectFileResponse?
    @State private var isUpdatingProject = false
    @State private var isDeletingProject = false
    @State private var showingEditProject = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAddMember = false
    @State private var showingFileImporter = false
    @State private var errorMessage: String?
    @State private var navigationPath = [ConversationResponse]()

    let onUpdate: ((ProjectResponse) -> Void)?
    let onDelete: ((String) -> Void)?

    init(
        project: ProjectResponse,
        onUpdate: ((ProjectResponse) -> Void)? = nil,
        onDelete: ((String) -> Void)? = nil
    ) {
        _project = State(initialValue: project)
        self.onUpdate = onUpdate
        self.onDelete = onDelete
    }

    private var canEditProject: Bool {
        project.role.lowercased() != "viewer"
    }

    private var canDeleteProject: Bool {
        project.role.lowercased() == "owner"
    }

    private var canManageMembers: Bool {
        project.role.lowercased() == "owner"
    }

    private var canManageFiles: Bool {
        project.role.lowercased() != "viewer"
    }

    private var allowedFileTypes: [UTType] {
        let markdown = UTType(filenameExtension: "md") ?? .plainText
        let epub = UTType(filenameExtension: "epub") ?? .data
        return [.pdf, .plainText, markdown, epub]
    }

    var body: some View {
        ZStack {
            Theme.Gradients.background
                .ignoresSafeArea()

            NavigationStack(path: $navigationPath) {
                GlassList {
                    // Header card
                    GlassListSection {
                        GlassListRow(showDivider: false) {
                            VStack(spacing: Theme.Spacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: project.color ?? "#007AFF").opacity(0.3))
                                        .frame(width: 90, height: 90)
                                        .blur(radius: 15)

                                    Circle()
                                        .fill(Color(hex: project.color ?? "#007AFF"))
                                        .frame(width: 70, height: 70)
                                        .overlay(
                                            Image(systemName: "folder.fill")
                                                .font(.system(size: 28))
                                                .foregroundStyle(.white)
                                        )
                                }

                                Text(project.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Theme.Colors.text)

                                if let description = project.description, !description.isEmpty {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                        }
                    }

                    // Details section
                    GlassListSection("Details") {
                        GlassListRow {
                            SettingsRow(
                                icon: "person.fill",
                                iconColor: Theme.Colors.primary,
                                title: "Role",
                                value: project.role.capitalized
                            )
                        }

                        GlassListRow(showDivider: false) {
                            SettingsRow(
                                icon: "person.2.fill",
                                iconColor: Theme.Colors.secondary,
                                title: "Shared",
                                value: project.isShared ? "Yes" : "No"
                            )
                        }
                    }

                    // System Prompt section
                    if let systemPrompt = project.systemPrompt, !systemPrompt.isEmpty {
                        GlassListSection("System Prompt") {
                            GlassListRow(showDivider: false) {
                                Text(systemPrompt)
                                    .font(.body)
                                    .foregroundStyle(Theme.Colors.text)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, Theme.Spacing.xs)
                            }
                        }
                    }

                    // Conversations section
                    GlassListSection("Conversations") {
                        GlassListRow {
                            Button {
                                Task {
                                    await createConversation()
                                }
                            } label: {
                                Label("New Chat", systemImage: "plus.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.Colors.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            .disabled(isCreatingConversation)
                        }

                        if isLoadingConversations {
                            GlassListRow(showDivider: false) {
                                ProgressView()
                                    .tint(Theme.Colors.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        } else if conversations.isEmpty {
                            GlassListRow(showDivider: false) {
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("No conversations yet")
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.Colors.text)

                                    Text("Start a chat to add conversations to this project.")
                                        .font(.caption)
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            ForEach(conversations, id: \.id) { conversation in
                                GlassListRow {
                                    NavigationLink(value: conversation) {
                                        ProjectConversationRow(conversation: conversation)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Members section
                    GlassListSection("Members") {
                        if canManageMembers {
                            GlassListRow {
                                Button {
                                    showingAddMember = true
                                } label: {
                                    Label("Add Member", systemImage: "person.badge.plus")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.Colors.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if isLoadingMembers {
                            GlassListRow(showDivider: false) {
                                ProgressView()
                                    .tint(Theme.Colors.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        } else if members.isEmpty {
                            GlassListRow(showDivider: false) {
                                Text("No members yet")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            ForEach(members, id: \.id) { member in
                                GlassListRow {
                                    ProjectMemberRow(member: member)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contextMenu {
                                            if canManageMembers
                                                && member.role.lowercased() != "owner"
                                            {
                                                Button(role: .destructive) {
                                                    Task {
                                                        await removeMember(member)
                                                    }
                                                } label: {
                                                    Label("Remove Member", systemImage: "trash")
                                                }
                                            }
                                        }
                                }
                            }
                        }
                    }

                    // Files section
                    GlassListSection("Files") {
                        if canManageFiles {
                            GlassListRow {
                                Button {
                                    showingFileImporter = true
                                } label: {
                                    Label("Upload File", systemImage: "doc.badge.plus")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.Colors.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .disabled(isUploadingFile)
                            }
                        }

                        if isUploadingFile {
                            GlassListRow(showDivider: false) {
                                ProgressView("Uploading...")
                                    .tint(Theme.Colors.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        } else if isLoadingFiles {
                            GlassListRow(showDivider: false) {
                                ProgressView()
                                    .tint(Theme.Colors.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        } else if files.isEmpty {
                            GlassListRow(showDivider: false) {
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("No files uploaded")
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.Colors.textSecondary)

                                    Text("Supported: PDF, Markdown, Text, EPUB")
                                        .font(.caption)
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            ForEach(files, id: \.id) { file in
                                GlassListRow {
                                    ProjectFileRow(
                                        file: file,
                                        onOpen: {
                                            fileToPreview = file
                                        }
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contextMenu {
                                        Button {
                                            fileToPreview = file
                                        } label: {
                                            Label("Open", systemImage: "arrow.up.right.square")
                                        }

                                        if canManageFiles {
                                            Button(role: .destructive) {
                                                Task {
                                                    await deleteFile(file)
                                                }
                                            } label: {
                                                Label("Remove File", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Metadata section
                    GlassListSection("Metadata") {
                        GlassListRow {
                            SettingsRow(
                                icon: "calendar.badge.plus",
                                iconColor: Theme.Colors.textSecondary,
                                title: "Created",
                                value: project.createdAt.formatted(
                                    date: .abbreviated, time: .shortened)
                            )
                        }

                        GlassListRow(showDivider: false) {
                            SettingsRow(
                                icon: "calendar.badge.clock",
                                iconColor: Theme.Colors.textSecondary,
                                title: "Updated",
                                value: project.updatedAt.formatted(
                                    date: .abbreviated, time: .shortened)
                            )
                        }
                    }

                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .navigationDestination(for: ConversationResponse.self) { conversation in
                    ChatView(
                        conversation: conversation,
                        onMessageSent: {
                            Task {
                                await loadConversations()
                            }
                        })
                }
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            Task {
                                await createConversation()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Theme.Gradients.primary)
                                    .frame(width: 36, height: 36)
                                    .shadow(
                                        color: Theme.Colors.primary.opacity(0.4), radius: 6, x: 0,
                                        y: 3)

                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .disabled(isCreatingConversation)

                        if canEditProject || canDeleteProject {
                            Menu {
                                if canEditProject {
                                    Button {
                                        showingEditProject = true
                                    } label: {
                                        Label("Edit Project", systemImage: "pencil")
                                    }
                                }

                                if canDeleteProject {
                                    Button(role: .destructive) {
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete Project", systemImage: "trash")
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                            .disabled(isUpdatingProject || isDeletingProject)
                        }
                    }
                }
                .task {
                    await loadAll()
                }
                .refreshable {
                    await loadAll()
                }
                .sheet(isPresented: $showingEditProject) {
                    EditProjectView(project: project) { request in
                        Task {
                            await updateProject(request)
                        }
                    }
                }
                .sheet(isPresented: $showingAddMember) {
                    AddProjectMemberView { email, role in
                        Task {
                            await addMember(email: email, role: role)
                        }
                    }
                    .presentationDetents([.medium])
                }
                .fileImporter(
                    isPresented: $showingFileImporter,
                    allowedContentTypes: allowedFileTypes
                ) { result in
                    switch result {
                    case .success(let url):
                        Task {
                            await uploadFile(from: url)
                        }
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
                .confirmationDialog(
                    "Delete Project?",
                    isPresented: $showingDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete Project", role: .destructive) {
                        Task {
                            await deleteProject()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will remove the project and unassign its conversations.")
                }
                .sheet(item: $fileToPreview) { file in
                    ProjectFilePreviewSheet(file: file)
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
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .liquidGlassNavigationBar()
    }

    private func loadConversations() async {
        isLoadingConversations = true
        defer { isLoadingConversations = false }

        do {
            conversations = try await NanoChatAPI.shared.getConversations(projectId: project.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadMembers() async {
        isLoadingMembers = true
        defer { isLoadingMembers = false }

        do {
            let loaded = try await NanoChatAPI.shared.getProjectMembers(projectId: project.id)
            members = loaded.sorted { left, right in
                if left.role.lowercased() == "owner" { return true }
                if right.role.lowercased() == "owner" { return false }
                return (left.user.name ?? left.user.email ?? "")
                    < (right.user.name ?? right.user.email ?? "")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadFiles() async {
        isLoadingFiles = true
        defer { isLoadingFiles = false }

        do {
            files = try await NanoChatAPI.shared.getProjectFiles(projectId: project.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadAll() async {
        async let conversationsTask = loadConversations()
        async let membersTask = loadMembers()
        async let filesTask = loadFiles()
        _ = await (conversationsTask, membersTask, filesTask)
    }

    private func createConversation() async {
        guard !isCreatingConversation else { return }
        isCreatingConversation = true
        defer { isCreatingConversation = false }

        do {
            HapticManager.shared.tap()
            let newConversation = try await NanoChatAPI.shared.createConversation(
                title: "New Chat",
                projectId: project.id
            )
            HapticManager.shared.success()
            conversations.insert(newConversation, at: 0)
            navigationPath.append(newConversation)
        } catch {
            HapticManager.shared.error()
            errorMessage = error.localizedDescription
        }
    }

    private func addMember(email: String, role: String) async {
        guard canManageMembers else { return }

        do {
            let member = try await NanoChatAPI.shared.addProjectMember(
                projectId: project.id,
                email: email,
                role: role
            )
            HapticManager.shared.success()
            members.append(member)
            members.sort { left, right in
                if left.role.lowercased() == "owner" { return true }
                if right.role.lowercased() == "owner" { return false }
                return (left.user.name ?? left.user.email ?? "")
                    < (right.user.name ?? right.user.email ?? "")
            }
        } catch {
            HapticManager.shared.error()
            errorMessage = error.localizedDescription
        }
    }

    private func removeMember(_ member: ProjectMemberResponse) async {
        guard canManageMembers, member.role.lowercased() != "owner" else { return }

        do {
            try await NanoChatAPI.shared.removeProjectMember(
                projectId: project.id,
                userId: member.userId
            )
            HapticManager.shared.success()
            members.removeAll { $0.id == member.id }
        } catch {
            HapticManager.shared.error()
            errorMessage = error.localizedDescription
        }
    }

    private func uploadFile(from url: URL) async {
        guard canManageFiles else { return }
        isUploadingFile = true
        defer { isUploadingFile = false }

        do {
            let uploaded = try await NanoChatAPI.shared.uploadProjectFile(
                projectId: project.id,
                fileURL: url
            )
            HapticManager.shared.success()
            files.insert(uploaded, at: 0)
        } catch {
            HapticManager.shared.error()
            errorMessage = error.localizedDescription
        }
    }

    private func deleteFile(_ file: ProjectFileResponse) async {
        guard canManageFiles else { return }

        do {
            try await NanoChatAPI.shared.deleteProjectFile(
                projectId: project.id,
                fileId: file.id
            )
            HapticManager.shared.success()
            files.removeAll { $0.id == file.id }
        } catch {
            HapticManager.shared.error()
            errorMessage = error.localizedDescription
        }
    }

    private func updateProject(_ request: UpdateProjectRequest) async {
        guard canEditProject, !isUpdatingProject else { return }
        isUpdatingProject = true
        defer { isUpdatingProject = false }

        do {
            let updated = try await NanoChatAPI.shared.updateProject(
                id: project.id,
                name: request.name,
                description: request.description,
                systemPrompt: request.systemPrompt,
                color: request.color
            )
            let merged = ProjectResponse(
                id: updated.id,
                name: updated.name,
                description: updated.description,
                systemPrompt: updated.systemPrompt,
                color: updated.color,
                role: project.role,
                isShared: project.isShared,
                createdAt: updated.createdAt,
                updatedAt: updated.updatedAt
            )
            HapticManager.shared.success()
            project = merged
            onUpdate?(merged)
        } catch {
            HapticManager.shared.error()
            errorMessage = error.localizedDescription
        }
    }

    private func deleteProject() async {
        guard canDeleteProject, !isDeletingProject else { return }
        isDeletingProject = true
        defer { isDeletingProject = false }

        do {
            try await NanoChatAPI.shared.deleteProject(id: project.id)
            HapticManager.shared.success()
            onDelete?(project.id)
            dismiss()
        } catch {
            HapticManager.shared.error()
            errorMessage = error.localizedDescription
        }
    }
}

struct ProjectConversationRow: View {
    let conversation: ConversationResponse

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.sm) {
                Text(conversation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.Colors.text)
                    .lineLimit(1)

                Spacer()

                if conversation.pinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondary)
                }

                if let cost = conversation.costUsd {
                    Text("$\(String(format: "%.4f", cost))")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            Text(conversation.updatedAt, style: .relative)
                .font(.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }
}

struct ProjectMemberRow: View {
    let member: ProjectMemberResponse

    private var displayName: String {
        member.user.name ?? member.user.email ?? "Unknown"
    }

    private var initials: String {
        String(displayName.prefix(1)).uppercased()
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Circle()
                .fill(Theme.Gradients.primary)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(initials)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(displayName)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.text)
                    .lineLimit(1)

                if let email = member.user.email, email != displayName {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(member.role.capitalized)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Theme.Colors.glassBackground)
                .foregroundStyle(Theme.Colors.textSecondary)
                .clipShape(Capsule())
        }
    }
}

struct ProjectFileRow: View {
    let file: ProjectFileResponse
    let onOpen: () -> Void

    @State private var showInlinePreview = false
    @State private var isLoadingPreview = false
    @State private var previewText: String?
    @State private var previewDocument: PDFDocument?

    private var formattedSize: String? {
        guard let size = file.storage?.size else { return nil }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    private var downloadURL: URL? {
        URL(string: "\(APIConfiguration.shared.baseURL)/api/storage/\(file.storageId)")
    }

    private var supportsInlinePreview: Bool {
        file.fileType == "pdf" || file.fileType == "text" || file.fileType == "markdown"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous)
                        .fill(Theme.Colors.glassBackground)
                        .frame(width: 36, height: 36)

                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.Colors.secondary)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(file.fileName)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.text)
                        .lineLimit(1)

                    HStack(spacing: Theme.Spacing.sm) {
                        Text(file.fileType.uppercased())
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.textSecondary)

                        if let formattedSize {
                            Text(formattedSize)
                                .font(.caption2)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                }

                Spacer()

                HStack(spacing: Theme.Spacing.sm) {
                    Button {
                        onOpen()
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .buttonStyle(.plain)

                    if let downloadURL {
                        ShareLink(item: downloadURL) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if supportsInlinePreview {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showInlinePreview.toggle()
                    }
                    if showInlinePreview {
                        Task {
                            await loadInlinePreviewIfNeeded()
                        }
                    }
                } label: {
                    Label(
                        showInlinePreview ? "Hide Preview" : "Show Preview",
                        systemImage: "doc.text.magnifyingglass"
                    )
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }

            if showInlinePreview {
                if isLoadingPreview {
                    ProgressView()
                        .tint(Theme.Colors.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if file.fileType == "pdf" {
                    if let document = previewDocument {
                        PDFInlineView(document: document)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                    } else {
                        Text("Preview unavailable")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                } else {
                    Text(previewText ?? "Preview unavailable")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Text(file.createdAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }

    private func loadInlinePreviewIfNeeded() async {
        guard !isLoadingPreview else { return }

        if file.fileType == "pdf", previewDocument != nil {
            return
        }

        if file.fileType == "text" || file.fileType == "markdown",
            previewText != nil
        {
            return
        }

        isLoadingPreview = true
        defer { isLoadingPreview = false }

        if file.fileType == "text" || file.fileType == "markdown" {
            let content = file.extractedContent ?? ""
            if !content.isEmpty {
                previewText = trimmedPreview(content)
                return
            }
        }

        do {
            let data = try await NanoChatAPI.shared.downloadStorageData(storageId: file.storageId)
            if file.fileType == "pdf" {
                previewDocument = PDFDocument(data: data)
            } else {
                previewText = trimmedPreview(String(decoding: data, as: UTF8.self))
            }
        } catch {
            previewText = "Preview unavailable"
        }
    }

    private func trimmedPreview(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let maxChars = 800
        if trimmed.count > maxChars {
            return String(trimmed.prefix(maxChars)) + "…"
        }
        return trimmed
    }
}

enum ProjectMemberRole: String, CaseIterable, Identifiable {
    case editor
    case viewer

    var id: String { rawValue }
}

struct PDFInlineView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        view.displayMode = .singlePage
        view.displayDirection = .vertical
        view.usePageViewController(true, withViewOptions: nil)
        view.autoScales = true
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}

struct EditProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var description: String
    @State private var systemPrompt: String
    @State private var selectedColor: String

    let colors = [
        "#007AFF", "#5856D6", "#FF2D55", "#FF9500", "#FFCC00", "#4CD964", "#5AC8FA", "#8E8E93",
    ]

    let onSave: (UpdateProjectRequest) -> Void

    init(project: ProjectResponse, onSave: @escaping (UpdateProjectRequest) -> Void) {
        _name = State(initialValue: project.name)
        _description = State(initialValue: project.description ?? "")
        _systemPrompt = State(initialValue: project.systemPrompt ?? "")
        _selectedColor = State(initialValue: project.color ?? "#007AFF")
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.background
                    .ignoresSafeArea()

                GlassList {
                    GlassListSection("Details") {
                        GlassListRow {
                            TextField("Project name", text: $name)
                                .textFieldStyle(.plain)
                                .foregroundStyle(Theme.Colors.text)
                        }

                        GlassListRow(showDivider: false) {
                            TextField("Description (optional)", text: $description)
                                .textFieldStyle(.plain)
                                .foregroundStyle(Theme.Colors.text)
                        }
                    }

                    GlassListSection("System Prompt (Optional)") {
                        GlassListRow(showDivider: false) {
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                TextEditor(text: $systemPrompt)
                                    .frame(minHeight: 120)
                                    .foregroundStyle(Theme.Colors.text)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)

                                Text("Optional system prompt for all conversations in this project")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                            .padding(.vertical, Theme.Spacing.xs)
                        }
                    }

                    GlassListSection("Color") {
                        GlassListRow(showDivider: false) {
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 50))],
                                spacing: Theme.Spacing.md
                            ) {
                                ForEach(colors, id: \.self) { color in
                                    ZStack {
                                        if selectedColor == color {
                                            Circle()
                                                .fill(Color(hex: color).opacity(0.3))
                                                .frame(width: 52, height: 52)
                                        }

                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 44, height: 44)
                                            .overlay {
                                                if selectedColor == color {
                                                    Image(systemName: "checkmark")
                                                        .foregroundStyle(.white)
                                                        .font(.system(size: 16, weight: .bold))
                                                }
                                            }
                                    }
                                    .onTapGesture {
                                        HapticManager.shared.selection()
                                        selectedColor = color
                                    }
                                }
                            }
                            .padding(.vertical, Theme.Spacing.sm)
                        }
                    }

                    Spacer(minLength: Theme.Spacing.xxl)
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .liquidGlassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticManager.shared.tap()
                        let request = UpdateProjectRequest(
                            name: name,
                            description: description.isEmpty ? nil : description,
                            systemPrompt: systemPrompt.isEmpty ? nil : systemPrompt,
                            color: selectedColor
                        )
                        onSave(request)
                        dismiss()
                    }
                    .foregroundStyle(
                        name.isEmpty ? Theme.Colors.textTertiary : Theme.Colors.secondary
                    )
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct AddProjectMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var role: ProjectMemberRole = .viewer

    let onAdd: (String, String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.background
                    .ignoresSafeArea()

                GlassList {
                    GlassListSection("Member") {
                        GlassListRow {
                            TextField("Email address", text: $email)
                                .textFieldStyle(.plain)
                                .foregroundStyle(Theme.Colors.text)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                        }

                        GlassListRow(showDivider: false) {
                            Picker("Role", selection: $role) {
                                ForEach(ProjectMemberRole.allCases) { role in
                                    Text(role.rawValue.capitalized)
                                        .tag(role)
                                }
                            }
                            .tint(Theme.Colors.secondary)
                        }
                    }

                    Spacer(minLength: Theme.Spacing.xxl)
                }
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .liquidGlassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        HapticManager.shared.tap()
                        onAdd(email.trimmingCharacters(in: .whitespacesAndNewlines), role.rawValue)
                        dismiss()
                    }
                    .foregroundStyle(
                        email.isEmpty ? Theme.Colors.textTertiary : Theme.Colors.secondary
                    )
                    .disabled(email.isEmpty)
                }
            }
        }
    }
}

struct ProjectFilePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let file: ProjectFileResponse

    @State private var isLoading = false
    @State private var data: Data?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.background
                    .ignoresSafeArea()

                Group {
                    if isLoading {
                        ProgressView()
                            .tint(Theme.Colors.secondary)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    } else if let data {
                        previewBody(for: data)
                    } else {
                        Text("Preview unavailable")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .navigationTitle(file.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .liquidGlassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .task {
                await loadData()
            }
        }
    }

    @ViewBuilder
    private func previewBody(for data: Data) -> some View {
        if file.fileType == "pdf", let document = PDFDocument(data: data) {
            PDFInlineView(document: document)
        } else if file.fileType == "text" || file.fileType == "markdown" {
            ScrollView {
                Text(String(decoding: data, as: UTF8.self))
                    .font(.body)
                    .foregroundStyle(Theme.Colors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            VStack(spacing: Theme.Spacing.md) {
                Text("Preview not available for this file type.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)

                if let url = URL(
                    string: "\(APIConfiguration.shared.baseURL)/api/storage/\(file.storageId)")
                {
                    ShareLink(item: url) {
                        Label("Download File", systemImage: "square.and.arrow.down")
                    }
                    .foregroundStyle(Theme.Colors.secondary)
                }
            }
        }
    }

    private func loadData() async {
        guard data == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            data = try await NanoChatAPI.shared.downloadStorageData(storageId: file.storageId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct NewProjectView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var systemPrompt = ""
    @State private var selectedColor = "#007AFF"

    let colors = [
        "#007AFF", "#5856D6", "#FF2D55", "#FF9500", "#FFCC00", "#4CD964", "#5AC8FA", "#8E8E93",
    ]

    let onCreate: (CreateProjectRequest) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.background
                    .ignoresSafeArea()

                GlassList {
                    // Details section
                    GlassListSection("Details") {
                        GlassListRow {
                            TextField("Project name", text: $name)
                                .textFieldStyle(.plain)
                                .foregroundStyle(Theme.Colors.text)
                        }

                        GlassListRow(showDivider: false) {
                            TextField("Description (optional)", text: $description)
                                .textFieldStyle(.plain)
                                .foregroundStyle(Theme.Colors.text)
                        }
                    }

                    // System Prompt section
                    GlassListSection("System Prompt (Optional)") {
                        GlassListRow(showDivider: false) {
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                TextEditor(text: $systemPrompt)
                                    .frame(minHeight: 100)
                                    .foregroundStyle(Theme.Colors.text)

                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)

                                Text("Optional system prompt for all conversations in this project")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                            .padding(.vertical, Theme.Spacing.xs)
                        }
                    }

                    // Color section
                    GlassListSection("Color") {
                        GlassListRow(showDivider: false) {
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 50))],
                                spacing: Theme.Spacing.md
                            ) {
                                ForEach(colors, id: \.self) { color in
                                    ZStack {
                                        if selectedColor == color {
                                            Circle()
                                                .fill(Color(hex: color).opacity(0.3))
                                                .frame(width: 52, height: 52)
                                        }

                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 44, height: 44)
                                            .overlay {
                                                if selectedColor == color {
                                                    Image(systemName: "checkmark")
                                                        .foregroundStyle(.white)
                                                        .font(.system(size: 16, weight: .bold))
                                                }
                                            }
                                    }
                                    .onTapGesture {
                                        HapticManager.shared.selection()
                                        selectedColor = color
                                    }
                                }
                            }
                            .padding(.vertical, Theme.Spacing.sm)
                        }
                    }

                    Spacer(minLength: Theme.Spacing.xxl)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .liquidGlassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        HapticManager.shared.success()
                        let request = CreateProjectRequest(
                            name: name,
                            description: description.isEmpty ? nil : description,
                            systemPrompt: systemPrompt.isEmpty ? nil : systemPrompt,
                            color: selectedColor
                        )
                        onCreate(request)
                        dismiss()
                    }
                    .foregroundStyle(
                        name.isEmpty ? Theme.Colors.textTertiary : Theme.Colors.secondary
                    )
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ProjectsListView()
}
