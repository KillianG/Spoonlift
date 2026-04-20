// SPDX-License-Identifier: MIT
import SwiftUI

struct PaneContainerView: View {
    @ObservedObject var pane: PaneModel
    @EnvironmentObject var window: WindowModel

    private var isActive: Bool { window.activePaneID == pane.id }

    var body: some View {
        VStack(spacing: 0) {
            if pane.tabs.count > 1 {
                TabBarView(pane: pane)
                Divider()
            }
            if let tab = pane.activeTab {
                TabContentView(pane: pane, tab: tab)
            } else {
                ContentUnavailableView("No tab", systemImage: "rectangle.dashed")
            }
        }
        .background(isActive ? Color.accentColor.opacity(0.04) : Color.clear)
        .overlay(
            Rectangle()
                .strokeBorder(isActive ? Color.accentColor.opacity(0.35) : Color.clear, lineWidth: 1)
                .allowsHitTesting(false)
        )
        .onTapGesture {
            window.activate(paneID: pane.id)
        }
    }
}
