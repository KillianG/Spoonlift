// SPDX-License-Identifier: MIT
import SwiftUI
import AppKit

struct FileColumnsView: View {
    @ObservedObject var tab: TabModel
    let pane: PaneModel
    @EnvironmentObject var window: WindowModel
    @EnvironmentObject var favorites: FavoritesStore
    @Environment(\.undoManager) private var undoManager
    var onRename: (FileItem) -> Void
    var onGetInfo: (URL) -> Void
    var onNewFolder: () -> Void

    @State private var columns: [URL] = []
    @State private var selections: [URL?] = []

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(Array(columns.enumerated()), id: \.offset) { idx, dir in
                    ColumnList(
                        directory: dir,
                        showHidden: tab.showHidden,
                        selection: Binding(
                            get: { idx < selections.count ? selections[idx] : nil },
                            set: { newSel in
                                while selections.count <= idx { selections.append(nil) }
                                selections = Array(selections.prefix(idx + 1))
                                selections[idx] = newSel
                                columns = Array(columns.prefix(idx + 1))
                                if let url = newSel {
                                    tab.selection = [url]
                                    if Self.isDirectory(url), !Self.isPackage(url) {
                                        columns.append(url)
                                    }
                                }
                            }
                        ),
                        tab: tab, pane: pane,
                        window: window, favorites: favorites,
                        undoManager: undoManager,
                        onRename: onRename,
                        onGetInfo: onGetInfo,
                        onNewFolder: onNewFolder
                    )
                    .frame(width: 230)
                    Divider()
                }
            }
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
        .onAppear {
            if columns.isEmpty {
                columns = [tab.currentURL]
                selections = [nil]
            }
        }
        .onChange(of: tab.currentURL) {
            columns = [tab.currentURL]
            selections = [nil]
        }
    }

    fileprivate static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }

    fileprivate static func isPackage(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isPackageKey]).isPackage) ?? false
    }
}

private struct ColumnList: View {
    let directory: URL
    let showHidden: Bool
    @Binding var selection: URL?

    @ObservedObject var tab: TabModel
    let pane: PaneModel
    @ObservedObject var window: WindowModel
    @ObservedObject var favorites: FavoritesStore
    let undoManager: UndoManager?
    var onRename: (FileItem) -> Void
    var onGetInfo: (URL) -> Void
    var onNewFolder: () -> Void

    @State private var items: [FileItem] = []

    var body: some View {
        List(selection: $selection) {
            ForEach(items) { item in
                HStack(spacing: 6) {
                    Image(nsImage: item.icon)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .draggable(item.url)
                    Text(item.name).lineLimit(1).truncationMode(.middle)
                    Spacer(minLength: 0)
                    if item.isDirectory && !item.isPackage {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .tag(Optional(item.url))
                .contextMenu {
                    FileContextMenuContent(
                        selection: [item.url],
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
        .listStyle(.plain)
        .onAppear { load() }
        .onChange(of: directory) { load() }
        .onChange(of: showHidden) { load() }
    }

    private func load() {
        items = FileSystemService.listDirectory(directory, showHidden: showHidden)
    }
}
