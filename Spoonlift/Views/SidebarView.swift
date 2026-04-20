// SPDX-License-Identifier: MIT
import SwiftUI
import AppKit

struct SidebarView: View {
    @EnvironmentObject var window: WindowModel

    var body: some View {
        Group {
            if let tab = window.activeTab {
                SidebarContent(activeTab: tab)
            } else {
                Text("No active tab")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }
}

private struct SidebarContent: View {
    @ObservedObject var activeTab: TabModel
    @EnvironmentObject var window: WindowModel
    @EnvironmentObject var favorites: FavoritesStore
    @State private var volumes: [URL] = []

    private var activeURL: URL { activeTab.currentURL }

    var body: some View {
        List {
            Section("Favorites") {
                ForEach(favorites.favorites) { fav in
                    SidebarLocationRow(
                        label: fav.name,
                        systemImage: iconName(forPath: fav.path),
                        url: fav.url,
                        favorite: fav,
                        activeURL: activeURL
                    )
                }
            }

            Section("Locations") {
                ForEach(FileSystemService.standardLocations(), id: \.url) { loc in
                    SidebarLocationRow(
                        label: loc.name,
                        systemImage: loc.symbol,
                        url: loc.url,
                        favorite: nil,
                        activeURL: activeURL
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
                            activeURL: activeURL,
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

private func sameLocation(_ a: URL, _ b: URL) -> Bool {
    a.standardizedFileURL.path == b.standardizedFileURL.path
}

private struct SidebarLocationRow: View {
    let label: String
    let systemImage: String
    let url: URL
    let favorite: Favorite?
    let activeURL: URL

    @EnvironmentObject var window: WindowModel
    @EnvironmentObject var favorites: FavoritesStore

    private var isActive: Bool { sameLocation(url, activeURL) }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .frame(width: 16)
                .foregroundStyle(isActive ? Color.accentColor : .secondary)
            Text(label)
                .foregroundStyle(isActive ? Color.accentColor : .primary)
                .fontWeight(isActive ? .semibold : .regular)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
            isActive ? Color.accentColor.opacity(0.15) : Color.clear,
            in: RoundedRectangle(cornerRadius: 4)
        )
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
    let activeURL: URL
    let onOpen: () -> Void
    let onEject: () -> Void

    @EnvironmentObject var window: WindowModel
    @EnvironmentObject var favorites: FavoritesStore

    private var isActive: Bool { sameLocation(url, activeURL) }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "externaldrive")
                .frame(width: 16)
                .foregroundStyle(isActive ? Color.accentColor : .secondary)
            Text(FileSystemService.volumeName(url))
                .foregroundStyle(isActive ? Color.accentColor : .primary)
                .fontWeight(isActive ? .semibold : .regular)
            Spacer(minLength: 0)
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
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
            isActive ? Color.accentColor.opacity(0.15) : Color.clear,
            in: RoundedRectangle(cornerRadius: 4)
        )
        .contentShape(Rectangle())
        .onTapGesture { onOpen() }
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
