// SPDX-License-Identifier: MIT
import Foundation
import SwiftUI

@MainActor
final class TabModel: ObservableObject, Identifiable {
    let id = UUID()
    @Published var currentURL: URL
    @Published var items: [FileItem] = []
    @Published var selection: Set<URL> = []
    @Published var sortField: SortField { didSet { objectWillChange.send() } }
    @Published var sortDirection: SortDirection { didSet { objectWillChange.send() } }
    @Published var viewMode: ViewMode
    @Published var showHidden: Bool { didSet { reload() } }
    @Published var previewPaneOpen: Bool
    @Published var searchText: String = ""

    private var backStack: [URL] = []
    private var forwardStack: [URL] = []

    init(url: URL,
         viewMode: ViewMode = .list,
         sortField: SortField = .name,
         sortDirection: SortDirection = .ascending,
         showHidden: Bool = false,
         previewPaneOpen: Bool = false) {
        self.currentURL = url
        self.viewMode = viewMode
        self.sortField = sortField
        self.sortDirection = sortDirection
        self.showHidden = showHidden
        self.previewPaneOpen = previewPaneOpen
        reload()
    }

    convenience init(state: TabState) {
        self.init(
            url: URL(fileURLWithPath: state.path),
            viewMode: state.viewMode,
            sortField: state.sortField,
            sortDirection: state.sortDirection,
            showHidden: state.showHidden,
            previewPaneOpen: state.previewPaneOpen
        )
    }

    var displayedItems: [FileItem] {
        let filtered: [FileItem] = searchText.isEmpty
            ? items
            : items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        return filtered.sorted(by: compare)
    }

    private func compare(_ a: FileItem, _ b: FileItem) -> Bool {
        if a.isDirectory != b.isDirectory { return a.isDirectory }
        let asc: Bool
        switch sortField {
        case .name: asc = a.name.localizedStandardCompare(b.name) == .orderedAscending
        case .size: asc = a.size < b.size
        case .kind: asc = a.kind.localizedCaseInsensitiveCompare(b.kind) == .orderedAscending
        case .modified: asc = a.modified < b.modified
        case .created: asc = a.created < b.created
        }
        return sortDirection == .ascending ? asc : !asc
    }

    func reload() {
        items = FileSystemService.listDirectory(currentURL, showHidden: showHidden)
        selection = selection.intersection(Set(items.map(\.url)))
    }

    func navigate(to url: URL, recordHistory: Bool = true) {
        let standardized = url.standardizedFileURL
        guard standardized.path != currentURL.standardizedFileURL.path else { return }
        if recordHistory {
            backStack.append(currentURL)
            forwardStack.removeAll()
        }
        currentURL = standardized
        selection.removeAll()
        reload()
    }

    var canGoBack: Bool { !backStack.isEmpty }
    var canGoForward: Bool { !forwardStack.isEmpty }

    func goBack() {
        guard let previous = backStack.popLast() else { return }
        forwardStack.append(currentURL)
        currentURL = previous
        selection.removeAll()
        reload()
    }

    func goForward() {
        guard let next = forwardStack.popLast() else { return }
        backStack.append(currentURL)
        currentURL = next
        selection.removeAll()
        reload()
    }

    func goUp() {
        let parent = currentURL.deletingLastPathComponent()
        if parent.path != currentURL.path {
            navigate(to: parent)
        }
    }

    var title: String {
        currentURL.lastPathComponent.isEmpty ? currentURL.path : currentURL.lastPathComponent
    }

    func snapshot() -> TabState {
        TabState(
            path: currentURL.path,
            viewMode: viewMode,
            sortField: sortField,
            sortDirection: sortDirection,
            showHidden: showHidden,
            previewPaneOpen: previewPaneOpen
        )
    }
}
