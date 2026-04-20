// SPDX-License-Identifier: MIT
import SwiftUI
import AppKit

struct SidebarView: View {
    @EnvironmentObject var window: WindowModel
    @EnvironmentObject var favorites: FavoritesStore
    @State private var volumes: [URL] = []

    var body: some View {
        List {
            Section("Favorites") {
                ForEach(favorites.favorites) { fav in
                    SidebarLocationRow(
                        label: fav.name,
                        systemImage: iconName(forPath: fav.path),
                        url: fav.url,
                        favorite: fav
                    )
                }
            }

            Section("Locations") {
                ForEach(FileSystemService.standardLocations(), id: \.url) { loc in
                    SidebarLocationRow(
                        label: loc.name,
                        systemImage: loc.symbol,
                        url: loc.url,
                        favorite: nil
                    )
                }
            }

            Section("Devices") {
                if volumes.isEmpty {
                    Text("No external volumes")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(volumes, id: \.self) { url in
                        DeviceRow(
                            url: url,
                            onOpen: { window.activeTab?.navigate(to: url) },
                            onEject: {
                                FileSystemService.eject(url)
                                refreshVolumes()
                            }
                        )
                    }
                }
            }

            Section("Tags") {
                ForEach(FinderTagColor.system) { tag in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(tag.swiftUIColor)
                            .frame(width: 10, height: 10)
                        Text(tag.displayName)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .onAppear { refreshVolumes() }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didMountNotification)) { _ in
            refreshVolumes()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didUnmountNotification)) { _ in
            refreshVolumes()
        }
    }

    private func iconName(forPath path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path == home { return "house" }
        if path.hasSuffix("/Desktop") { return "menubar.dock.rectangle" }
        if path.hasSuffix("/Documents") { return "doc" }
        if path.hasSuffix("/Downloads") { return "arrow.down.circle" }
        if path.hasSuffix("/Pictures") { return "photo" }
        if path.hasSuffix("/Movies") { return "film" }
        if path.hasSuffix("/Music") { return "music.note" }
        return "star"
    }

    private func refreshVolumes() {
        volumes = FileSystemService.listVolumes()
    }
}

private struct SidebarLocationRow: View {
    let label: String
    let systemImage: String
    let url: URL
    let favorite: Favorite?

    @EnvironmentObject var window: WindowModel
    @EnvironmentObject var favorites: FavoritesStore

    var body: some View {
        Label(label, systemImage: systemImage)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                window.activeTab?.navigate(to: url)
            }
            .contextMenu {
                Button("Open") {
                    window.activeTab?.navigate(to: url)
                }
                Button("Open in New Tab") {
                    window.activePane?.addTab(url: url)
                }
                if window.panes.count > 1 {
                    Button("Open in Other Pane") {
                        if let other = window.panes.first(where: { $0.id != window.activePaneID }) {
                            other.activeTab?.navigate(to: url)
                            window.activate(paneID: other.id)
                        }
                    }
                }
                Divider()
                Button("Reveal in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
                Button("Copy Path") {
                    Pasteboard.copyPath([url])
                }
                Divider()
                if let fav = favorite {
                    Button("Remove from Favorites") {
                        favorites.remove(fav)
                    }
                } else {
                    Button("Add to Favorites") {
                        favorites.add(url)
                    }
                }
            }
    }
}

private struct DeviceRow: View {
    let url: URL
    let onOpen: () -> Void
    let onEject: () -> Void

    @EnvironmentObject var window: WindowModel
    @EnvironmentObject var favorites: FavoritesStore

    var body: some View {
        HStack(spacing: 6) {
            Label(FileSystemService.volumeName(url), systemImage: "externaldrive")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { onOpen() }
            if FileSystemService.canEject(url) {
                Button(action: onEject) {
                    Image(systemName: "eject.fill")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Eject \(FileSystemService.volumeName(url))")
            }
        }
        .contextMenu {
            Button("Open", action: onOpen)
            Button("Open in New Tab") {
                window.activePane?.addTab(url: url)
            }
            if window.panes.count > 1 {
                Button("Open in Other Pane") {
                    if let other = window.panes.first(where: { $0.id != window.activePaneID }) {
                        other.activeTab?.navigate(to: url)
                        window.activate(paneID: other.id)
                    }
                }
            }
            Divider()
            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
            Button("Copy Path") {
                Pasteboard.copyPath([url])
            }
            Button("Add to Favorites") {
                favorites.add(url)
            }
            if FileSystemService.canEject(url) {
                Divider()
                Button("Eject", action: onEject)
            }
        }
    }
}
