// SPDX-License-Identifier: MIT
import SwiftUI
import AppKit

struct WindowRoot: View {
    @EnvironmentObject var appModel: AppModel
    @StateObject private var window = WindowModel()
    @State private var registered = false

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            WorkspaceView()
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(item: conflictBinding()) { pending in
            ConflictDialog(
                context: pending.context,
                resolve: { window.transfers.resolve($0) }
            )
            .environmentObject(window)
            .environmentObject(window.transfers)
        }
        .overlay(alignment: .bottom) {
            TransferProgressOverlay()
        }
        .environmentObject(window)
        .environmentObject(window.transfers)
        .onAppear {
            guard !registered else { return }
            appModel.register(window)
            registered = true
        }
        .onDisappear { appModel.unregister(window) }
        .onReceive(NotificationCenter.default.publisher(for: .spoonliftNewTab)) { _ in
            guard let pane = window.activePane else { return }
            let url = pane.activeTab?.currentURL ?? FileManager.default.homeDirectoryForCurrentUser
            pane.addTab(url: url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .spoonliftNewPane)) { _ in
            window.addPane()
        }
        .onReceive(NotificationCenter.default.publisher(for: .spoonliftCloseTab)) { _ in
            guard let pane = window.activePane else { return }
            if !pane.closeActiveTab() {
                window.closePane(id: pane.id)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .spoonliftToggleHidden)) { _ in
            window.activeTab?.showHidden.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .spoonliftTogglePreview)) { _ in
            if let tab = window.activeTab { tab.previewPaneOpen.toggle() }
        }
    }

    private func conflictBinding() -> Binding<TransferCoordinator.PendingConflict?> {
        Binding(
            get: { window.transfers.pendingConflict },
            set: { newValue in
                if newValue == nil, window.transfers.pendingConflict != nil {
                    window.transfers.resolve(.cancel)
                }
            }
        )
    }
}

private struct TransferProgressOverlay: View {
    @EnvironmentObject var transfers: TransferCoordinator
    var body: some View {
        if !transfers.transfers.isEmpty {
            TransferProgressWindow()
                .padding(16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
