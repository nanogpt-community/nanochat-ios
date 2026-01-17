import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct ProjectsListView: View {
    @State private var projects: [ProjectResponse] = []
    @State private var isLoading = false
    @State private var showingNewProject = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && projects.isEmpty {
                    ProgressView()
                } else if projects.isEmpty {
                    ContentUnavailableView {
                        Label("No Projects", systemImage: "folder")
                    } description: {
                        Text("Create projects to organize your conversations")
                    } actions: {
                        Button("Create Project") {
                            showingNewProject = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(projects, id: \.id) { project in
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
                            .listRowBackground(Theme.Colors.sectionBackground)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Theme.Colors.backgroundStart)
                }
            }
            .background(Theme.Colors.backgroundStart)
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewProject = true }) {
                        Image(systemName: "plus")
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
            Circle()
                .fill(Color(hex: project.color ?? "#007AFF"))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "folder.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(project.name)
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.text)
                        .lineLimit(1)

                    Spacer()

                    Text(project.role.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
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
        .padding(.vertical, 4)
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
        NavigationStack(path: $navigationPath) {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(Color(hex: project.color ?? "#007AFF"))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "folder.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            )

                        VStack(alignment: .leading) {
                            Text(project.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.Colors.text)
                            if let description = project.description, !description.isEmpty {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(Color.clear)
                }

                Section("Details") {
                    LabeledContent("Role", value: project.role.capitalized)
                        .foregroundStyle(Theme.Colors.text)
                    LabeledContent("Shared", value: project.isShared ? "Yes" : "No")
                        .foregroundStyle(Theme.Colors.text)
                }
                .listRowBackground(Theme.Colors.sectionBackground)

                if let systemPrompt = project.systemPrompt, !systemPrompt.isEmpty {
                    Section("System Prompt") {
                        Text(systemPrompt)
                            .foregroundStyle(Theme.Colors.text)
                            .textSelection(.enabled)
                    }
                    .listRowBackground(Theme.Colors.sectionBackground)
                }

                Section("Conversations") {
                    Button {
                        Task { await createConversation() }
                    } label: {
                        Label("New Chat", systemImage: "plus")
                    }
                    .foregroundStyle(Theme.Colors.accent)
                    .disabled(isCreatingConversation)
                    .listRowBackground(Theme.Colors.sectionBackground)

                    if isLoadingConversations {
                        ProgressView().frame(maxWidth: .infinity)
                            .listRowBackground(Theme.Colors.sectionBackground)
                    } else if conversations.isEmpty {
                        Text("No conversations yet")
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .listRowBackground(Theme.Colors.sectionBackground)
                    } else {
                        ForEach(conversations, id: \.id) { conversation in
                            NavigationLink(value: conversation) {
                                ProjectConversationRow(conversation: conversation)
                            }
                            .listRowBackground(Theme.Colors.sectionBackground)
                        }
                    }
                }

                Section("Members") {
                    if canManageMembers {
                        Button {
                            showingAddMember = true
                        } label: {
                            Label("Add Member", systemImage: "person.badge.plus")
                        }
                        .foregroundStyle(Theme.Colors.accent)
                        .listRowBackground(Theme.Colors.sectionBackground)
                    }

                    if isLoadingMembers {
                        ProgressView().frame(maxWidth: .infinity)
                            .listRowBackground(Theme.Colors.sectionBackground)
                    } else if members.isEmpty {
                        Text("No members yet")
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .listRowBackground(Theme.Colors.sectionBackground)
                    } else {
                        ForEach(members, id: \.id) { member in
                            ProjectMemberRow(member: member)
                                .swipeActions {
                                    if canManageMembers && member.role.lowercased() != "owner" {
                                        Button(role: .destructive) {
                                            Task { await removeMember(member) }
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    }
                                }
                                .listRowBackground(Theme.Colors.sectionBackground)
                        }
                    }
                }

                Section("Files") {
                    if canManageFiles {
                        Button {
                            showingFileImporter = true
                        } label: {
                            Label("Upload File", systemImage: "doc.badge.plus")
                        }
                        .foregroundStyle(Theme.Colors.accent)
                        .disabled(isUploadingFile)
                        .listRowBackground(Theme.Colors.sectionBackground)
                    }

                    if isUploadingFile {
                        ProgressView("Uploading...")
                            .listRowBackground(Theme.Colors.sectionBackground)
                    } else if isLoadingFiles {
                        ProgressView().frame(maxWidth: .infinity)
                            .listRowBackground(Theme.Colors.sectionBackground)
                    } else if files.isEmpty {
                        Text("No files uploaded")
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .listRowBackground(Theme.Colors.sectionBackground)
                    } else {
                        ForEach(files, id: \.id) { file in
                            ProjectFileRow(file: file, onOpen: { fileToPreview = file })
                                .swipeActions {
                                    if canManageFiles {
                                        Button(role: .destructive) {
                                            Task { await deleteFile(file) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                                .listRowBackground(Theme.Colors.sectionBackground)
                        }
                    }
                }

                Section("Metadata") {
                    LabeledContent("Created", value: project.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(Theme.Colors.text)
                    LabeledContent("Updated", value: project.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(Theme.Colors.text)
                }
                .listRowBackground(Theme.Colors.sectionBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.backgroundStart)
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
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
                        }
                    }
                }
            }
            .navigationDestination(for: ConversationResponse.self) { conversation in
                ChatView(
                    conversation: conversation,
                    showSidebar: .constant(false), // Or handle properly if needed
                    onMessageSent: {
                        Task {
                            await loadConversations()
                        }
                    },
                    isPushed: true
                )
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
        async let conversationsTask: Void = loadConversations()
        async let membersTask: Void = loadMembers()
        async let filesTask: Void = loadFiles()
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.Colors.text)
                    .lineLimit(1)

                Text(conversation.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            
            Spacer()
            
            if conversation.pinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondary)
            }
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
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(Text(initials).font(.caption))

            VStack(alignment: .leading) {
                Text(displayName)
                    .font(.subheadline)
                if let email = member.user.email, email != displayName {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(member.role.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}

struct ProjectFileRow: View {
    let file: ProjectFileResponse
    let onOpen: () -> Void

    private var formattedSize: String? {
        guard let size = file.storage?.size else { return nil }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    var body: some View {
        Button(action: onOpen) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(Theme.Colors.secondary)
                
                VStack(alignment: .leading) {
                    Text(file.fileName)
                        .font(.subheadline)
                    HStack {
                        Text(file.fileType.uppercased())
                        if let size = formattedSize {
                            Text("• " + size)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ProjectFilePreviewSheet: View {
    let file: ProjectFileResponse
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            // Placeholder for file preview logic
            Text("Preview for \(file.fileName)")
                .navigationTitle(file.fileName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
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
            Form {
                Section("Details") {
                    TextField("Project name", text: $name)
                        .foregroundStyle(Theme.Colors.text)
                    TextField("Description (optional)", text: $description)
                        .foregroundStyle(Theme.Colors.text)
                }
                .listRowBackground(Theme.Colors.sectionBackground)

                Section("System Prompt") {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 120)
                        .foregroundStyle(Theme.Colors.text)
                        .scrollContentBackground(.hidden)
                }
                .listRowBackground(Theme.Colors.sectionBackground)

                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))]) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical)
                }
                .listRowBackground(Theme.Colors.sectionBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.backgroundStart)
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let request = UpdateProjectRequest(
                            name: name,
                            description: description.isEmpty ? nil : description,
                            systemPrompt: systemPrompt.isEmpty ? nil : systemPrompt,
                            color: selectedColor
                        )
                        onSave(request)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .foregroundStyle(Theme.Colors.accent)
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
            Form {
                Section {
                    TextField("Email address", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .foregroundStyle(Theme.Colors.text)

                    Picker("Role", selection: $role) {
                        Text("Editor").tag(ProjectMemberRole.editor)
                        Text("Viewer").tag(ProjectMemberRole.viewer)
                    }
                    .foregroundStyle(Theme.Colors.text)
                }
                .listRowBackground(Theme.Colors.sectionBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.backgroundStart)
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(email, role.rawValue)
                        dismiss()
                    }
                    .disabled(email.isEmpty)
                    .foregroundStyle(Theme.Colors.accent)
                }
            }
        }
    }
}

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
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
            Form {
                Section("Details") {
                    TextField("Project name", text: $name)
                        .foregroundStyle(Theme.Colors.text)
                    TextField("Description (optional)", text: $description)
                        .foregroundStyle(Theme.Colors.text)
                }
                .listRowBackground(Theme.Colors.sectionBackground)

                Section("System Prompt") {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 120)
                        .foregroundStyle(Theme.Colors.text)
                        .scrollContentBackground(.hidden)
                }
                .listRowBackground(Theme.Colors.sectionBackground)

                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))]) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical)
                }
                .listRowBackground(Theme.Colors.sectionBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.backgroundStart)
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let request = CreateProjectRequest(
                            name: name,
                            description: description.isEmpty ? nil : description,
                            systemPrompt: systemPrompt.isEmpty ? nil : systemPrompt,
                            color: selectedColor
                        )
                        onCreate(request)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .foregroundStyle(Theme.Colors.accent)
                }
            }
        }
    }
}
