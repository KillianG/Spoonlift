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
    }
}
