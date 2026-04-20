// SPDX-License-Identifier: MIT
import SwiftUI
import AppKit

struct FileIconsView: View {
    @ObservedObject var tab: TabModel
    let pane: PaneModel
    @EnvironmentObject var window: WindowModel
    @EnvironmentObject var favorites: FavoritesStore
    @Environment(\.undoManager) private var undoManager
    var onRename: (FileItem) -> Void
    var onGetInfo: (URL) -> Void
    var onNewFolder: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 96, maximum: 128), spacing: 8)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(tab.displayedItems) { item in
                    cell(for: item)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .top)
        }
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

    private func cell(for item: FileItem) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Image(nsImage: item.icon)
                    .resizable()
                    .interpolation(.medium)
                    .frame(width: 56, height: 56)
                if !item.tagNames.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(Array(item.tagNames.prefix(3)), id: \.self) { name in
                            Circle()
                                .fill(FinderTagColor.color(forTagName: name))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .offset(x: 8, y: -4)
                }
            }
            Text(item.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .truncationMode(.middle)
        }
        .frame(width: 100, height: 96)
        .padding(6)
        .background(
            tab.selection.contains(item.url) ? Color.accentColor.opacity(0.25) : Color.clear,
            in: RoundedRectangle(cornerRadius: 6)
        )
        .contentShape(Rectangle())
        .draggable(item.url)
        .onTapGesture(count: 2) {
            if item.isDirectory && !item.isPackage {
                tab.navigate(to: item.url)
            } else {
                NSWorkspace.shared.open(item.url)
            }
        }
        .onTapGesture {
            if NSEvent.modifierFlags.contains(.command) {
                if tab.selection.contains(item.url) {
                    tab.selection.remove(item.url)
                } else {
                    tab.selection.insert(item.url)
                }
            } else {
                tab.selection = [item.url]
            }
        }
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

    private func trashSelected() {
        guard !tab.selection.isEmpty else { return }
        let results = FileSystemService.moveToTrash(Array(tab.selection))
        let restorable: [(URL, URL)] = results.compactMap { (original, trashed) in
            guard let trashed else { return nil }
            return (original, trashed)
        }
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
        tab.selection.removeAll()
        tab.reload()
    }
}
