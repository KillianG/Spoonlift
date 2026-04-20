// SPDX-License-Identifier: MIT
import SwiftUI

struct TabBarView: View {
    @ObservedObject var pane: PaneModel

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(pane.tabs) { tab in
                        TabChip(
                            tab: tab,
                            pane: pane,
                            isActive: pane.activeTabID == tab.id,
                            canClose: pane.tabs.count > 1,
                            onActivate: { pane.activate(tabID: tab.id) },
                            onClose: { pane.closeTab(id: tab.id) }
                        )
                    }
                }
                .padding(.horizontal, 6)
            }
            Spacer(minLength: 0)
            Button {
                let url = pane.activeTab?.currentURL ?? FileManager.default.homeDirectoryForCurrentUser
                pane.addTab(url: url)
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 8)
            .help("New Tab")
        }
        .padding(.vertical, 4)
        .background(.windowBackground)
    }
}

private struct TabChip: View {
    @ObservedObject var tab: TabModel
    @ObservedObject var pane: PaneModel
    let isActive: Bool
    let canClose: Bool
    let onActivate: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tab.title)
                .lineLimit(1)
                .truncationMode(.middle)
                .font(.callout)
            if canClose {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").font(.caption2)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .frame(maxWidth: 180)
        .background(
            isActive ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 5)
        )
        .contentShape(Rectangle())
        .onTapGesture { onActivate() }
        .contextMenu {
            Button("Duplicate Tab") {
                pane.addTab(url: tab.currentURL)
            }
            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([tab.currentURL])
            }
            Button("Copy Path") {
                Pasteboard.copyPath([tab.currentURL])
            }
            Divider()
            if canClose {
                Button("Close Tab", action: onClose)
                if pane.tabs.count > 2 {
                    Button("Close Other Tabs") {
                        let keepID = tab.id
                        for other in pane.tabs where other.id != keepID {
                            pane.closeTab(id: other.id)
                        }
                    }
                }
                Button("Close Tabs to the Right") {
                    guard let index = pane.tabs.firstIndex(where: { $0.id == tab.id }) else { return }
                    let toClose = pane.tabs.suffix(from: pane.tabs.index(after: index)).map(\.id)
                    for id in toClose { pane.closeTab(id: id) }
                }
                .disabled(pane.tabs.last?.id == tab.id)
            }
        }
    }
}
