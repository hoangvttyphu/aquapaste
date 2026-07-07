import Foundation

@MainActor
final class ClipboardPanelViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedItemID: ClipboardItem.ID?
    @Published private(set) var canAutoPaste = PasteAutomation.canAutoPaste

    let store: ClipboardStore

    init(store: ClipboardStore) {
        self.store = store
    }

    var filteredItems: [ClipboardItem] {
        let query = normalized(searchText)
        guard query.isEmpty == false else {
            return store.items
        }

        return store.items.filter { item in
            item.searchableText.contains(query)
        }
    }

    func refreshForPresentation() {
        searchText = ""
        canAutoPaste = PasteAutomation.canAutoPaste
        syncSelection()
    }

    func syncSelection() {
        let visibleItems = filteredItems
        guard visibleItems.isEmpty == false else {
            selectedItemID = nil
            return
        }

        if let selectedItemID,
           visibleItems.contains(where: { $0.id == selectedItemID }) {
            return
        }

        self.selectedItemID = visibleItems.first?.id
    }

    func moveSelection(offset: Int) {
        let visibleItems = filteredItems
        guard visibleItems.isEmpty == false else {
            selectedItemID = nil
            return
        }

        let currentIndex = visibleItems.firstIndex(where: { $0.id == selectedItemID }) ?? 0
        let nextIndex = min(max(currentIndex + offset, 0), visibleItems.count - 1)
        selectedItemID = visibleItems[nextIndex].id
    }

    func select(_ item: ClipboardItem) {
        selectedItemID = item.id
    }

    func selectedItem() -> ClipboardItem? {
        let visibleItems = filteredItems
        guard visibleItems.isEmpty == false else {
            return nil
        }

        if let selectedItemID,
           let item = visibleItems.first(where: { $0.id == selectedItemID }) {
            return item
        }

        return visibleItems.first
    }

    private func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
