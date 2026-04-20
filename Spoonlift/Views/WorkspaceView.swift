// SPDX-License-Identifier: MIT
import SwiftUI

struct WorkspaceView: View {
    @EnvironmentObject var window: WindowModel

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(window.panes.enumerated()), id: \.element.id) { index, pane in
                PaneContainerView(pane: pane)
                if index < window.panes.count - 1 {
                    Divider()
                }
            }
        }
    }
}
