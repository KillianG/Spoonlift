// SPDX-License-Identifier: MIT
import SwiftUI
import AppKit

struct FileContextMenuContent: View {
    let selection: Set<URL>
    @ObservedObject var tab: TabModel
    let pane: PaneModel
    @ObservedObject var window: WindowModel
    @ObservedObject var favorites: FavoritesStore
    let undoManager: UndoManager?
    let onRename: (FileItem) -> Void
    let onGetInfo: (URL) -> Void
    let onNewFolder: () -> Void

    var body: some View {
        if selection.isEmpty {
            emptyAreaMenu
        } else {
            selectionMenu
        }
    }

    @ViewBuilder
    private var emptyAreaMenu: some View {
        Button("New Folder", action: onNewFolder)
        Button("Paste Items", action: paste)
            .disabled(!Pasteboard.hasFiles)
        Divider()
        Button("Reveal Current Folder in Finder") {
            NSWorkspace.shared.activateFileViewerSelecting([tab.currentURL])
        }
        Button("Open in Terminal", action: openInTerminal)
        Button("Copy Path") {
            Pasteboard.copyPath([tab.currentURL])
        }
        Button("Add to Favorites") { favorites.add(tab.currentURL) }
        Divider()
        Menu("Sort By") {
            Picker("Field", selection: $tab.sortField) {
                ForEach(SortField.allCases) { f in
                    Text(f.label).tag(f)
                }
            }
            Divider()
            Picker("Direction", selection: $tab.sortDirection) {
                Text("Ascending").tag(SortDirection.ascending)
                Text("Descending").tag(SortDirection.descending)
            }
        }
        Menu("View As") {
            Picker("View", selection: $tab.viewMode) {
                ForEach(ViewMode.allCases) { m in
                    Label(m.label, systemImage: m.symbol).tag(m)
                }
            }
            Divider()
            Toggle("Show Hidden Files", isOn: $tab.showHidden)
        }
        Divider()
        Button("Refresh", action: tab.reload)
    }

    @ViewBuilder
    private var selectionMenu: some View {
        Button("Open", action: openSelection)
        if selection.count == 1, let url = selection.first {
            Menu("Open With") {
                OpenWithMenu(url: url)
            }
        }
        Button("Open in New Tab") {
            for url in selection {
                if isDirectory(url) {
                    pane.addTab(url: url)
                } else {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        if window.panes.count > 1 {
            Button("Open in Other Pane", action: openInOtherPane)
        }
        Button("Quick Look") {
            QuickLookCoordinator.shared.show(urls: Array(selection))
        }
        Divider()
        Button("Get Info") {
            if let first = selection.first { onGetInfo(first) }
        }
        Button("Reveal in Finder") {
            NSWorkspace.shared.activateFileViewerSelecting(Array(selection))
        }
        Divider()
        Button("Copy") { Pasteboard.copy(Array(selection)) }
        Button("Cut") { Pasteboard.cut(Array(selection)) }
        Button("Duplicate", action: duplicateSelection)
        Divider()
        if selection.count == 1,
           let url = selection.first,
           let item = tab.displayedItems.first(where: { $0.url == url }) {
            Button("Rename…") { onRename(item) }
        }
        Button("Compress", action: compressSelection)
        Button("Copy Path") { Pasteboard.copyPath(Array(selection)) }
        Button("Add to Favorites") {
            for url in selection { favorites.add(url) }
        }
        Divider()
        Menu("Tags") {
            ForEach(FinderTagColor.system) { color in
                Button {
                    for url in selection {
                        try? TagService.toggleTag(color.displayName, for: url)
                    }
                    tab.reload()
                } label: {
                    Label(color.displayName, systemImage: "circle.fill")
                        .foregroundStyle(color.swiftUIColor)
                }
            }
            Divider()
            Button("Clear All Tags") {
                for url in selection {
                    try? TagService.setTags([], for: url)
                }
                tab.reload()
            }
        }
        Divider()
        Button("Move to Trash", role: .destructive, action: trashSelection)
    }

    private func openSelection() {
        guard let first = selection.first else { return }
        if let item = tab.displayedItems.first(where: { $0.url == first }),
           item.isDirectory && !item.isPackage {
            tab.navigate(to: first)
        } else {
            for url in selection { NSWorkspace.shared.open(url) }
        }
    }

    private func openInOtherPane() {
        guard let other = window.panes.first(where: { $0.id != pane.id }) else { return }
        guard let url = selection.first else { return }
        if isDirectory(url) {
            other.activeTab?.navigate(to: url)
            window.activate(paneID: other.id)
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    private func openInTerminal() {
        let terminal = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
        NSWorkspace.shared.open(
            [tab.currentURL],
            withApplicationAt: terminal,
            configuration: NSWorkspace.OpenConfiguration()
        ) { _, _ in }
    }

    private func duplicateSelection() {
        for url in selection {
            _ = FileSystemService.duplicate(url)
        }
        tab.reload()
    }

    private func compressSelection() {
        CompressService.zip(urls: Array(selection), in: tab.currentURL) {
            tab.reload()
        }
    }

    private func paste() {
        let (urls, isCut) = Pasteboard.read()
        guard !urls.isEmpty else { return }
        window.transfers.start(
            kind: isCut ? .move : .copy,
            sources: urls,
            destinationDir: tab.currentURL
        )
    }

    private func trashSelection() {
        let results = FileSystemService.moveToTrash(Array(selection))
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

    private func isDirectory(_ url: URL) -> Bool {
        if let item = tab.displayedItems.first(where: { $0.url == url }) {
            return item.isDirectory && !item.isPackage
        }
        let v = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
        return (v?.isDirectory ?? false) && !(v?.isPackage ?? false)
    }
}

private struct OpenWithMenu: View {
    let url: URL
    @State private var apps: [URL] = []
    @State private var loaded = false

    var body: some View {
        Group {
            if !loaded {
                Button("Loading…") {}.disabled(true)
            } else if apps.isEmpty {
                Button("No applications") {}.disabled(true)
            } else {
                ForEach(apps, id: \.self) { app in
                    Button {
                        NSWorkspace.shared.open(
                            [url],
                            withApplicationAt: app,
                            configuration: NSWorkspace.OpenConfiguration()
                        ) { _, _ in }
                    } label: {
                        Label(appName(for: app), systemImage: "app")
                    }
                }
            }
            Divider()
            Button("Other…") {
                chooseOther()
            }
        }
        .task {
            apps = NSWorkspace.shared.urlsForApplications(toOpen: url)
            loaded = true
        }
    }

    private func appName(for appURL: URL) -> String {
        let bundle = Bundle(url: appURL)
        if let name = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return name
        }
        if let name = bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return name
        }
        return appURL.deletingPathExtension().lastPathComponent
    }

    private func chooseOther() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let app = panel.url {
            NSWorkspace.shared.open(
                [url],
                withApplicationAt: app,
                configuration: NSWorkspace.OpenConfiguration()
            ) { _, _ in }
        }
    }
}
