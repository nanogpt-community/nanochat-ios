import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingDateRangePicker = false
    @State private var showingModelPicker = false
    @State private var showingProjectPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchHeader

                    // Filters
                    if viewModel.hasActiveFilters {
                        filtersBar
                    }

                    Divider()
                        .overlay(Theme.Colors.glassBorder)

                    // Content
                    content
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .liquidGlassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        HapticManager.shared.tap()
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }

                if viewModel.hasActiveFilters {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Clear") {
                            HapticManager.shared.tap()
                            viewModel.clearFilters()
                        }
                        .foregroundStyle(Theme.Colors.secondary)
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadData()
                }
            }
            .searchable(text: $viewModel.query, prompt: "Search messages...")
            .onChange(of: viewModel.query) { _, _ in
                viewModel.performSearch()
            }
        }
    }

    private var searchHeader: some View {
        GlassEffectContainer {
            HStack(spacing: Theme.Spacing.sm) {
                // Search icon badge
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(width: 32, height: 32)
                    .glassEffect(in: .circle)

                Text("Search messages")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.textTertiary)

                Spacer()

                // Filter buttons with glass effect
                Button {
                    showingDateRangePicker = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(viewModel.startDate != nil || viewModel.endDate != nil ? Theme.Colors.accent : Theme.Colors.text)
                        .frame(width: 32, height: 32)
                        .tint(viewModel.startDate != nil || viewModel.endDate != nil ? Theme.Colors.accent : nil)
                        .glassEffect(in: .circle)
                }
                .buttonStyle(.plain)

                Button {
                    showingModelPicker = true
                } label: {
                    Image(systemName: "cpu")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(viewModel.selectedModel != nil ? Theme.Colors.accent : Theme.Colors.text)
                        .frame(width: 32, height: 32)
                        .tint(viewModel.selectedModel != nil ? Theme.Colors.accent : nil)
                        .glassEffect(in: .circle)
                }
                .buttonStyle(.plain)

                Button {
                    showingProjectPicker = true
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(viewModel.selectedProject != nil ? Theme.Colors.accent : Theme.Colors.text)
                        .frame(width: 32, height: 32)
                        .tint(viewModel.selectedProject != nil ? Theme.Colors.accent : nil)
                        .glassEffect(in: .circle)
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation {
                        viewModel.starredOnly.toggle()
                        viewModel.performSearch()
                    }
                } label: {
                    Image(systemName: viewModel.starredOnly ? "star.fill" : "star")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(viewModel.starredOnly ? Theme.Colors.warning : Theme.Colors.text)
                        .frame(width: 32, height: 32)
                        .tint(viewModel.starredOnly ? Theme.Colors.warning : nil)
                        .glassEffect(in: .circle)
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation {
                        viewModel.hasAttachments.toggle()
                        viewModel.performSearch()
                    }
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(viewModel.hasAttachments ? Theme.Colors.accent : Theme.Colors.text)
                        .frame(width: 32, height: 32)
                        .tint(viewModel.hasAttachments ? Theme.Colors.accent : nil)
                        .glassEffect(in: .circle)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.md)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm)
    }

    private var filtersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                if let startDate = viewModel.startDate, let endDate = viewModel.endDate {
                    FilterChip(
                        label: formatDateRange(startDate, endDate),
                        icon: "calendar"
                    ) {
                        viewModel.startDate = nil
                        viewModel.endDate = nil
                        viewModel.performSearch()
                    }
                }

                if let model = viewModel.selectedModel {
                    FilterChip(
                        label: model,
                        icon: "cpu"
                    ) {
                        viewModel.selectedModel = nil
                        viewModel.performSearch()
                    }
                }

                if let project = viewModel.selectedProject,
                   let projectObj = viewModel.availableProjectsForFilter.first(where: { $0.id == project }) {
                    FilterChip(
                        label: projectObj.name,
                        icon: "folder"
                    ) {
                        viewModel.selectedProject = nil
                        viewModel.performSearch()
                    }
                }

                if viewModel.starredOnly {
                    FilterChip(
                        label: "Starred",
                        icon: "star.fill"
                    ) {
                        viewModel.starredOnly = false
                        viewModel.performSearch()
                    }
                }

                if viewModel.hasAttachments {
                    FilterChip(
                        label: "Attachments",
                        icon: "paperclip"
                    ) {
                        viewModel.hasAttachments = false
                        viewModel.performSearch()
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var content: some View {
        Group {
            if viewModel.isLoading && viewModel.results.isEmpty {
                ProgressView()
                    .tint(Theme.Colors.secondary)
            } else if viewModel.results.isEmpty && viewModel.hasActiveFilters {
                ContentUnavailableView {
                    Label("No Results", systemImage: "magnifyingglass")
                        .foregroundStyle(Theme.Colors.textSecondary)
                } description: {
                    Text("Try adjusting your search filters")
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            } else if !viewModel.query.isEmpty || viewModel.hasActiveFilters {
                searchResults
            } else {
                emptyState
            }
        }
    }

    private var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(viewModel.results) { result in
                    SearchResultRow(result: result)
                        .padding(.horizontal, Theme.Spacing.lg)
                }
            }
            .padding(.vertical, Theme.Spacing.md)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Search Messages", systemImage: "doc.text.magnifyingglass")
                .foregroundStyle(Theme.Colors.textSecondary)
        } description: {
            Text("Search across all your conversations")
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }

    private func formatDateRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: SearchViewModel.SearchResult
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Conversation title
            HStack {
                Image(systemName: "message.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondary)

                Text(result.conversation.title)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)

                Spacer()

                Text(result.message.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)

                if result.message.starred == true {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondary)
                }
            }

            // Message preview
            Text(result.message.content)
                .font(.body)
                .foregroundStyle(Theme.Colors.text)
                .lineLimit(isExpanded ? nil : 3)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }

            // Attachments indicator
            if (result.message.images?.isEmpty == false) || (result.message.documents?.isEmpty == false) {
                HStack(spacing: Theme.Spacing.xs) {
                    if let images = result.message.images, !images.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "photo.fill")
                            Text("\(images.count)")
                        }
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.textTertiary)
                    }

                    if let documents = result.message.documents, !documents.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "doc.fill")
                            Text("\(documents.count)")
                        }
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.textTertiary)
                    }

                    Spacer()
                }
            }
        }
        .padding(Theme.Spacing.md)
        .glassCard()
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let icon: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)

            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.Colors.text)

            Button {
                HapticManager.shared.tap()
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .tint(Theme.Colors.accent)
        .glassEffect()
    }
}

// MARK: - Date Range Picker Sheet

struct DateRangePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var startDate: Date?
    @Binding var endDate: Date?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.background.ignoresSafeArea()

                VStack(spacing: Theme.Spacing.lg) {
                    DateRangePicker(
                        startDate: $startDate,
                        endDate: $endDate,
                        onApply: { dismiss() }
                    )

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Date Range")
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
                    Button("Apply") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.secondary)
                }
            }
        }
    }
}

// MARK: - Custom Date Range Picker

struct DateRangePicker: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    let onApply: () -> Void

    @State private var startTemp = Date()
    @State private var endTemp = Date()

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("From")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)

                DatePicker("", selection: $startTemp, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("To")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)

                DatePicker("", selection: $endTemp, in: startTemp..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }

            HStack(spacing: Theme.Spacing.md) {
                Button("Clear") {
                    startDate = nil
                    endDate = nil
                    onApply()
                }
                .buttonStyle(.bordered)
                .tint(Theme.Colors.textTertiary)

                Spacer()

                Button("Apply") {
                    startDate = startTemp
                    endDate = endTemp
                    onApply()
                }
                .buttonStyle(.bordered)
                .tint(Theme.Colors.secondary)
            }
        }
        .padding()
        .glassCard()
        .onAppear {
            startTemp = startDate ?? Date().addingTimeInterval(-30 * 24 * 3600)
            endTemp = endDate ?? Date()
        }
    }
}

#Preview {
    SearchView()
}
