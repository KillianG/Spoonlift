// SPDX-License-Identifier: MIT
import SwiftUI
import AppKit

struct PathBar: View {
    @ObservedObject var tab: TabModel
    @EnvironmentObject var window: WindowModel
    @EnvironmentObject var favorites: FavoritesStore

    private var components: [(name: String, url: URL)] {
        var out: [(String, URL)] = []
        var current = tab.currentURL
        var guardCount = 0
        while current.path != "/" && !current.path.isEmpty && guardCount < 64 {
            let name = current.lastPathComponent.isEmpty ? current.path : current.lastPathComponent
            out.append((name, current))
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path { break }
            current = parent
            guardCount += 1
        }
        out.append(("/", URL(fileURLWithPath: "/")))
        return out.reversed()
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(components.enumerated()), id: \.offset) { idx, comp in
                    if idx > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Button {
                        tab.navigate(to: comp.url)
                    } label: {
                        Text(comp.name)
                            .font(.callout)
                            .foregroundStyle(idx == components.count - 1 ? Color.primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Open in New Tab") {
                            window.activePane?.addTab(url: comp.url)
                        }
                        if window.panes.count > 1 {
                            Button("Open in Other Pane") {
                                if let other = window.panes.first(where: { $0.id != window.activePaneID }) {
                                    other.activeTab?.navigate(to: comp.url)
                                    window.activate(paneID: other.id)
                                }
                            }
                        }
                        Divider()
                        Button("Reveal in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([comp.url])
                        }
                        Button("Copy Path") {
                            Pasteboard.copyPath([comp.url])
                        }
                        Button("Add to Favorites") {
                            favorites.add(comp.url)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
        }
    }
}
