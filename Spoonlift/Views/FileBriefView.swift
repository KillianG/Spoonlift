// SPDX-License-Identifier: MIT
import SwiftUI
import AppKit

struct FileBriefView: View {
    @ObservedObject var tab: TabModel
    let pane: PaneModel
    @EnvironmentObject var window: WindowModel
    @EnvironmentObject var favorites: FavoritesStore
    @Environment(\.undoManager) private var undoManager
    var onRename: (FileItem) -> Void
    var onGetInfo: (URL) -> Void
    var onNewFolder: () -> Void

    var body: some View {
        List(tab.displayedItems, selection: $tab.selection) { item in
            HStack(spacing: 6) {
                Image(nsImage: item.icon)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .draggable(item.url)
                Text(item.name).lineLimit(1)
                if !item.tagNames.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(Array(item.tagNames.prefix(3)), id: \.self) { name in
                            Circle()
                                .fill(FinderTagColor.color(forTagName: name))
                                .frame(width: 7, height: 7)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .contextMenu {
                FileContextMenuContent(
                    selection: tab.selection.contains(item.url) ? tab.selection : [item.url],
                    tab: tab,
                    pane: pane,
                    window: window,
                    favorites: favorites,
                    undoManager: undoManager,
                    onRename: onRename,
                    onGetInfo: onGetInfo,
                    onNewFolder: onNewFolder
                )
            }
        }
        .listStyle(.plain)
        .contextMenu {
            FileContextMenuContent(
                selection: [],
                tab: tab, pane: pane,
                window: window, favorites: favorites,
                undoManager: undoManager,
                onRename: onRename,
                onGetInfo: onGetInfo,
                onNewFolder: onNewFolder
            )
        }
        .background {
            Button("", action: trashSelected)
                .keyboardShortcut(.delete, modifiers: [.command])
                .opacity(0)
                .frame(width: 0, height: 0)
        }
    }

    private func trashSelected() {
        guard !tab.selection.isEmpty else { return }
        let results = FileSystemService.moveToTrash(Array(tab.selection))
        let restorable: [(URL, URL)] = results.compactMap { (original, trashed) in
            guard let trashed else { return nil }
            return (original, trashed)
        }
        if !restorable.isEmpty {
            undoManager?.registerUndo(withTarget: tab) { t in
                for (original, trashed) in restorable {
                    try? FileManager.default.moveItem(at: trashed, to: original)
                }
                t.reload()
            }
            undoManager?.setActionName("Move to Trash")
        }
        tab.selection.removeAll()
        tab.reload()
    }
}
