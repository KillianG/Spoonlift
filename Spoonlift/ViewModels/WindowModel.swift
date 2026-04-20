// SPDX-License-Identifier: MIT
import Foundation
import SwiftUI

@MainActor
final class WindowModel: ObservableObject, Identifiable {
    let id = UUID()
    @Published var panes: [PaneModel] = []
    @Published var activePaneID: UUID?
    let transfers = TransferCoordinator()

    var activePane: PaneModel? {
        panes.first { $0.id == activePaneID }
    }

    var activeTab: TabModel? {
        activePane?.activeTab
    }

    func addPane(at url: URL? = nil) {
        let start = url ?? activeTab?.currentURL ?? FileManager.default.homeDirectoryForCurrentUser
        let pane = PaneModel(initialURL: start)
        panes.append(pane)
        activePaneID = pane.id
    }

    func closePane(id: UUID) {
        guard panes.count > 1 else { return }
        panes.removeAll { $0.id == id }
        if activePaneID == id { activePaneID = panes.first?.id }
    }

    func closeActivePane() {
        guard let id = activePaneID else { return }
        closePane(id: id)
    }

    func activate(paneID: UUID) {
        activePaneID = paneID
    }

    func snapshot() -> WindowState {
        WindowState(
            panes: panes.map { $0.snapshot() },
            activePaneIndex: panes.firstIndex(where: { $0.id == activePaneID }) ?? 0
        )
    }

    func restore(from state: WindowState) {
        panes = state.panes.map { PaneModel(state: $0) }
        if panes.isEmpty { panes = [PaneModel(initialURL: FileManager.default.homeDirectoryForCurrentUser)] }
        let idx = max(0, min(state.activePaneIndex, panes.count - 1))
        activePaneID = panes[idx].id
    }
}
