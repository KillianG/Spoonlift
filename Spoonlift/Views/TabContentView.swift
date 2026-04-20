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

    var body: some View {
        mainStack
            .onAppear { tab.reload() }
            .sheet(item: $renameTarget, content: renameSheet)
            .sheet(item: $infoTarget, content: infoSheet)
            .sheet(isPresented: $isNewFolderPresented, content: newFolderSheet)
            .background(shortcutButtons)
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

    @ViewBuilder
    private var shortcutButtons: some View {
        ZStack {
            Button("", action: quickLookSelected).keyboardShortcut(.space, modifiers: [])
            Button("", action: copySelected).keyboardShortcut("c", modifiers: [.command])
            Button("", action: cutSelected).keyboardShortcut("x", modifiers: [.command])
            Button("", action: pasteItems).keyboardShortcut("v", modifiers: [.command])
            Button("", action: duplicateSelected).keyboardShortcut("d", modifiers: [.command])
            Button("", action: getInfoSelected).keyboardShortcut("i", modifiers: [.command])
            Button("", action: beginNewFolder).keyboardShortcut("n", modifiers: [.command, .shift])
            Button("", action: copyPathSelected).keyboardShortcut("c", modifiers: [.command, .option])
        }
        .opacity(0)
        .frame(width: 0, height: 0)
    }

    private func quickLookSelected() {
        QuickLookCoordinator.shared.toggle(urls: Array(tab.selection))
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
        }
    }

    private func copyPathSelected() {
        let urls = tab.selection.isEmpty ? [tab.currentURL] : Array(tab.selection)
        Pasteboard.copyPath(urls)
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
