// SPDX-License-Identifier: MIT
import SwiftUI
import AppKit

struct FileListView: View {
    @ObservedObject var tab: TabModel
    let pane: PaneModel
    @EnvironmentObject var window: WindowModel
    @EnvironmentObject var favorites: FavoritesStore
    @Environment(\.undoManager) private var undoManager
    var onRename: (FileItem) -> Void
    var onGetInfo: (URL) -> Void
    var onNewFolder: () -> Void

    var body: some View {
        Table(tab.displayedItems, selection: $tab.selection) {
            TableColumn("Name") { item in
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
            }

            TableColumn("Size") { item in
                Text(item.isDirectory ? "—" : ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .width(min: 60, ideal: 90)

            TableColumn("Kind") { item in
                Text(item.kind)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .width(min: 80, ideal: 140)

            TableColumn("Date Modified") { item in
                Text(Self.formatted(item.modified))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .width(min: 120, ideal: 180)
        }
        .contextMenu(forSelectionType: URL.self) { selection in
            FileContextMenuContent(
                selection: selection,
                tab: tab,
                pane: pane,
                window: window,
                favorites: favorites,
                undoManager: undoManager,
                onRename: onRename,
                onGetInfo: onGetInfo,
                onNewFolder: onNewFolder
            )
        } primaryAction: { selection in
            openPrimary(selection)
        }
    }

    private func openPrimary(_ selection: Set<URL>) {
        guard let url = selection.first else { return }
        if let item = tab.displayedItems.first(where: { $0.url == url }),
           item.isDirectory && !item.isPackage {
            tab.navigate(to: item.url)
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    static func formatted(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
