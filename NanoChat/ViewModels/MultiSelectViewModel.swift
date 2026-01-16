import Foundation
import SwiftUI

/// ViewModel for managing multi-select state in lists
@MainActor
final class MultiSelectViewModel<T: Identifiable & Hashable>: ObservableObject {
    @Published var isEditMode: Bool = false
    @Published var selectedItems: Set<T.ID> = []
    @Published var items: [T] = []

    // MARK: - Selection Management

    func toggleSelection(_ item: T) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
            HapticManager.shared.selectionChanged()
        } else {
            selectedItems.insert(item.id)
            HapticManager.shared.selectionChanged()
        }
    }

    func isSelected(_ item: T) -> Bool {
        selectedItems.contains(item.id)
    }

    func selectAll() {
        selectedItems = Set(items.map { $0.id })
        HapticManager.shared.selectionChanged()
    }

    func deselectAll() {
        selectedItems.removeAll()
        HapticManager.shared.tap()
    }

    func toggleSelectAll() {
        if selectedItems.count == items.count {
            deselectAll()
        } else {
            selectAll()
        }
    }

    func exitEditMode() {
        isEditMode = false
        selectedItems.removeAll()
        HapticManager.shared.tap()
    }

    func enterEditMode() {
        isEditMode = true
        HapticManager.shared.heavyTap()
    }

    // MARK: - Batch Operations

    /// Delete selected items
    func deleteSelected(using deleteFunction: @MainActor @escaping (Set<T.ID>) async -> Void) async {
        guard !selectedItems.isEmpty else { return }

        let itemsToDelete = selectedItems
        exitEditMode()

        await deleteFunction(itemsToDelete)
        HapticManager.shared.warning()
    }

    /// Move selected items to a project
    func moveToProject(using moveFunction: @MainActor @escaping (Set<T.ID>, String?) async -> Void, projectId: String?) async {
        guard !selectedItems.isEmpty else { return }

        let itemsToMove = selectedItems
        exitEditMode()

        await moveFunction(itemsToMove, projectId)
        HapticManager.shared.success()
    }

    /// Export selected items
    func exportSelected(using exportFunction: @MainActor @escaping (Set<T.ID>) -> Void) {
        guard !selectedItems.isEmpty else { return }

        exportFunction(selectedItems)
        HapticManager.shared.success()
        exitEditMode()
    }

    /// Star selected items
    func starSelected(using starFunction: @MainActor @escaping (Set<T.ID>) async -> Void) async {
        guard !selectedItems.isEmpty else { return }

        let itemsToStar = selectedItems
        exitEditMode()

        await starFunction(itemsToStar)
        HapticManager.shared.success()
    }

    // MARK: - Computed Properties

    var hasSelection: Bool {
        !selectedItems.isEmpty
    }

    var selectionCount: Int {
        selectedItems.count
    }

    var isAllSelected: Bool {
        !items.isEmpty && selectedItems.count == items.count
    }

    var selectionDescription: String {
        if selectedItems.count == 1 {
            return "1 item selected"
        }
        return "\(selectedItems.count) items selected"
    }
}

// MARK: - Multi-Selectable List Row Modifier

extension View {
    /// Adds multi-select capability to list rows
    @ViewBuilder
    func multiSelectable<Item: Identifiable & Hashable>(
        item: Item,
        selectionMode: Bool,
        isSelected: Bool,
        onTap: @escaping () -> Void,
        onLongPress: @escaping () -> Void
    ) -> some View {
        self
            .contentShape(Rectangle())
            .onTapGesture {
                if selectionMode {
                    onTap()
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                if !selectionMode {
                    onLongPress()
                }
            }
            .overlay(
                Group {
                    if selectionMode {
                        ZStack {
                            Circle()
                                .fill(isSelected ? Theme.Colors.secondary : Color.clear)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Theme.Gradients.glass, lineWidth: 1)
                                )

                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(Theme.Spacing.sm)
                    }
                }
            )
    }
}
