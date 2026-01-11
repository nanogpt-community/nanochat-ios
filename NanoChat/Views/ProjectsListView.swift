import SwiftUI

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
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    } else {
                        List {
                            ForEach(projects, id: \.id) { project in
                                NavigationLink {
                                    ProjectDetailView(project: project)
                                } label: {
                                    ProjectRow(project: project)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: Theme.Spacing.xs, leading: Theme.Spacing.lg, bottom: Theme.Spacing.xs, trailing: Theme.Spacing.lg))
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("Projects")
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showingNewProject = true }) {
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
                .sheet(isPresented: $showingNewProject) {
                    NewProjectView { project in
                        Task {
                            await createProject(project)
                        }
                    }
                    .presentationDetents([.large])
                    .presentationBackground(.ultraThinMaterial)
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

                if let description = project.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .glassCard()
    }
}

struct ProjectDetailView: View {
    let project: ProjectResponse

    var body: some View {
        ZStack {
            Theme.Gradients.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header card
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
                        
                        if let description = project.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(Theme.Spacing.xl)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xl))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                            .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                    )
                    
                    // Details section
                    SettingsSection(title: "Details") {
                        VStack(spacing: Theme.Spacing.md) {
                            SettingsRow(
                                icon: "person.fill",
                                iconColor: Theme.Colors.primary,
                                title: "Role",
                                value: project.role.capitalized
                            )
                            
                            Divider().background(Theme.Colors.glassBorder)
                            
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
                        SettingsSection(title: "System Prompt") {
                            Text(systemPrompt)
                                .font(.body)
                                .foregroundStyle(Theme.Colors.text)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // Metadata section
                    SettingsSection(title: "Metadata") {
                        VStack(spacing: Theme.Spacing.md) {
                            SettingsRow(
                                icon: "calendar.badge.plus",
                                iconColor: Theme.Colors.textSecondary,
                                title: "Created",
                                value: project.createdAt.formatted(date: .abbreviated, time: .shortened)
                            )
                            
                            Divider().background(Theme.Colors.glassBorder)
                            
                            SettingsRow(
                                icon: "calendar.badge.clock",
                                iconColor: Theme.Colors.textSecondary,
                                title: "Updated",
                                value: project.updatedAt.formatted(date: .abbreviated, time: .shortened)
                            )
                        }
                    }
                    
                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.md)
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct NewProjectView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var systemPrompt = ""
    @State private var selectedColor = "#007AFF"

    let colors = ["#007AFF", "#5856D6", "#FF2D55", "#FF9500", "#FFCC00", "#4CD964", "#5AC8FA", "#8E8E93"]

    let onCreate: (CreateProjectRequest) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Details section
                        SettingsSection(title: "Details") {
                            VStack(spacing: Theme.Spacing.md) {
                                TextField("Project name", text: $name)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(Theme.Colors.text)
                                
                                Divider().background(Theme.Colors.glassBorder)
                                
                                TextField("Description (optional)", text: $description)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(Theme.Colors.text)
                            }
                        }
                        
                        // System Prompt section
                        SettingsSection(title: "System Prompt (Optional)") {
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
                        }
                        
                        // Color section
                        SettingsSection(title: "Color") {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: Theme.Spacing.md) {
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
                        }
                        
                        Spacer(minLength: Theme.Spacing.xxl)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)
                }
            }
            .navigationTitle("New Project")
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
                    .foregroundStyle(name.isEmpty ? Theme.Colors.textTertiary : Theme.Colors.secondary)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ProjectsListView()
}
