// SPDX-License-Identifier: MIT
import Foundation
import SwiftUI

@MainActor
final class PaneModel: ObservableObject, Identifiable {
    let id = UUID()
    @Published var tabs: [TabModel] = []
    @Published var activeTabID: UUID?

    init(initialURL: URL) {
        let tab = TabModel(url: initialURL)
        self.tabs = [tab]
        self.activeTabID = tab.id
    }

    init(state: PaneState) {
        let built = state.tabs.map { TabModel(state: $0) }
        self.tabs = built.isEmpty
            ? [TabModel(url: FileManager.default.homeDirectoryForCurrentUser)]
            : built
        let idx = max(0, min(state.activeTabIndex, self.tabs.count - 1))
        self.activeTabID = self.tabs[idx].id
    }

    var activeTab: TabModel? {
        tabs.first { $0.id == activeTabID }
    }

    func addTab(url: URL) {
        let tab = TabModel(url: url)
        tabs.append(tab)
        activeTabID = tab.id
    }

    func duplicateActiveTab() {
        guard let tab = activeTab else { return }
        addTab(url: tab.currentURL)
    }

    @discardableResult
    func closeActiveTab() -> Bool {
        guard let id = activeTabID, tabs.count > 1 else { return false }
        tabs.removeAll { $0.id == id }
        activeTabID = tabs.first?.id
        return true
    }

    func closeTab(id: UUID) {
        tabs.removeAll { $0.id == id }
        if activeTabID == id { activeTabID = tabs.first?.id }
    }

    func activate(tabID: UUID) {
        activeTabID = tabID
    }

    func snapshot() -> PaneState {
        PaneState(
            tabs: tabs.map { $0.snapshot() },
            activeTabIndex: tabs.firstIndex(where: { $0.id == activeTabID }) ?? 0
        )
    }
}
