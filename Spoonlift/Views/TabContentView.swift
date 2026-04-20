// SPDX-License-Identifier: MIT
import SwiftUI
import AppKit

struct InfoTargetWrapper: Identifiable {
    let url: URL
    var id: String { url.path }
}

struct TabContentView: View {
    @ObservedObject var pane: PaneModel
    @ObservedObject var tab: TabModel
    @EnvironmentObject var window: WindowModel
    @EnvironmentObject var favorites: FavoritesStore
    @Environment(\.undoManager) private var undoManager

    @State private var renameTarget: FileItem?
    @State private var renameText: String = ""
    @State private var infoTarget: InfoTargetWrapper?
    @State private var isNewFolderPresented: Bool = false
    @State private var newFolderName: String = ""

    /// True when this tab is the active tab of the active pane in the window.
    /// Notifications are broadcast app-wide; only the active tab should act on them.
    private var isActive: Bool {
        window.activePaneID == pane.id && pane.activeTabID == tab.id
    }

    var body: some View {
        mainStack
            .onAppear { tab.reload() }
            .sheet(item: $renameTarget, content: renameSheet)
            .sheet(item: $infoTarget, content: infoSheet)
            .sheet(isPresented: $isNewFolderPresented, content: newFolderSheet)
            .modifier(TabShortcutListener(isActive: isActive, handler: handleShortcut))
    }

    private func handleShortcut(_ name: Notification.Name) {
        switch name {
        case .spoonliftCopy:       copySelected()
        case .spoonliftCut:        cutSelected()
        case .spoonliftPaste:      pasteItems()
        case .spoonliftDuplicate:  duplicateSelected()
        case .spoonliftCopyPath:   copyPathSelected()
        case .spoonliftTrash:      trashSelected()
        case .spoonliftGetInfo:    getInfoSelected()
        case .spoonliftNewFolder:  beginNewFolder()
        case .spoonliftQuickLook:  quickLookSelected()
        default: break
        }
    }

    private var mainStack: some View {
        VStack(spacing: 0) {
            PaneToolbar(
                pane: pane,
                tab: tab,
                onAddFavorite: { favorites.add(tab.currentURL) },
                onAddPane: { window.addPane(at: tab.currentURL) },
                onClosePane: { window.closePane(id: pane.id) },
                canClosePane: window.panes.count > 1,
                onNewFolder: beginNewFolder
            )
            Divider()
            PathBar(tab: tab)
            Divider()
            contentRow
            Divider()
            StatusBarView(tab: tab)
        }
    }

    private var contentRow: some View {
        HStack(spacing: 0) {
            fileView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .dropDestination(for: URL.self) { urls, _ in
                    handleDrop(urls: urls)
                    return true
                }
            if tab.previewPaneOpen {
                Divider()
                PreviewPaneView(urls: Array(tab.selection))
                    .frame(width: 280)
            }
        }
    }

    @ViewBuilder
    private var fileView: some View {
        switch tab.viewMode {
        case .list:
            FileListView(
                tab: tab, pane: pane,
                onRename: beginRename,
                onGetInfo: beginGetInfo,
                onNewFolder: beginNewFolder
            )
        case .icons:
            FileIconsView(
                tab: tab, pane: pane,
                onRename: beginRename,
                onGetInfo: beginGetInfo,
                onNewFolder: beginNewFolder
            )
        case .columns:
            FileColumnsView(
                tab: tab, pane: pane,
                onRename: beginRename,
                onGetInfo: beginGetInfo,
                onNewFolder: beginNewFolder
            )
        case .brief:
            FileBriefView(
                tab: tab, pane: pane,
                onRename: beginRename,
                onGetInfo: beginGetInfo,
                onNewFolder: beginNewFolder
            )
        }
    }

    private func renameSheet(_ item: FileItem) -> some View {
        RenameSheet(
            originalName: item.name,
            text: $renameText,
            onCommit: {
                _ = FileSystemService.rename(item.url, to: renameText)
                tab.reload()
                renameTarget = nil
            },
            onCancel: { renameTarget = nil }
        )
    }

    private func infoSheet(_ target: InfoTargetWrapper) -> some View {
        GetInfoSheet(url: target.url, onDismiss: { infoTarget = nil })
    }

    private func newFolderSheet() -> some View {
        NewFolderSheet(
            name: $newFolderName,
            onCommit: {
                let trimmed = newFolderName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    _ = FileSystemService.makeDirectory(in: tab.currentURL, named: trimmed)
                    tab.reload()
                }
                isNewFolderPresented = false
                newFolderName = ""
            },
            onCancel: {
                isNewFolderPresented = false
                newFolderName = ""
            }
        )
    }

    private func beginRename(_ item: FileItem) {
        renameText = item.name
        renameTarget = item
    }

    private func beginGetInfo(_ url: URL) {
        infoTarget = InfoTargetWrapper(url: url)
    }

    private func beginNewFolder() {
        newFolderName = "untitled folder"
        isNewFolderPresented = true
    }

    private func copySelected() {
        guard !tab.selection.isEmpty else { return }
        Pasteboard.copy(Array(tab.selection))
    }

    private func cutSelected() {
        guard !tab.selection.isEmpty else { return }
        Pasteboard.cut(Array(tab.selection))
    }

    private func pasteItems() {
        let (urls, isCut) = Pasteboard.read()
        guard !urls.isEmpty else { return }
        window.transfers.start(
            kind: isCut ? .move : .copy,
            sources: urls,
            destinationDir: tab.currentURL
        )
    }

    private func duplicateSelected() {
        guard !tab.selection.isEmpty else { return }
        for url in tab.selection {
            _ = FileSystemService.duplicate(url)
        }
        tab.reload()
    }

    private func getInfoSelected() {
        if let first = tab.selection.first {
            infoTarget = InfoTargetWrapper(url: first)
        } else {
            infoTarget = InfoTargetWrapper(url: tab.currentURL)
        }
    }

    private func copyPathSelected() {
        let urls = tab.selection.isEmpty ? [tab.currentURL] : Array(tab.selection)
        Pasteboard.copyPath(urls)
    }

    private func trashSelected() {
        guard !tab.selection.isEmpty else { return }
        let urls = Array(tab.selection)
        let results = FileSystemService.moveToTrash(urls)
        let restorable: [(URL, URL)] = results.compactMap { (original, trashed) in
            guard let trashed else { return nil }
            return (original, trashed)
        }
        let failures = urls.filter { results[$0] == nil || results[$0] == .some(nil) }

        if !restorable.isEmpty {
            undoManager?.registerUndo(withTarget: tab) { t in
                MainActor.assumeIsolated {
                    for (original, trashed) in restorable {
                        try? FileManager.default.moveItem(at: trashed, to: original)
                    }
                    t.reload()
                }
            }
            undoManager?.setActionName("Move to Trash")
        }

        if !failures.isEmpty {
            window.transfers.reportError(
                title: "Couldn't move \(failures.count) item\(failures.count == 1 ? "" : "s") to the Trash",
                message: "macOS blocked the operation. Grant Spoonlift Full Disk Access: System Settings → Privacy & Security → Full Disk Access → + → /Applications/Spoonlift.app."
            )
        }

        tab.selection.removeAll()
        tab.reload()
    }

    private func quickLookSelected() {
        QuickLookCoordinator.shared.toggle(urls: Array(tab.selection))
    }

    private func handleDrop(urls: [URL]) {
        guard !urls.isEmpty else { return }
        let isMove = NSEvent.modifierFlags.contains(.command)
        window.transfers.start(
            kind: isMove ? .move : .copy,
            sources: urls,
            destinationDir: tab.currentURL
        )
    }
}
