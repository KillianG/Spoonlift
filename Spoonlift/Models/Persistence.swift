// SPDX-License-Identifier: MIT
import Foundation

struct TabState: Codable, Hashable {
    var path: String
    var viewMode: ViewMode
    var sortField: SortField
    var sortDirection: SortDirection
    var showHidden: Bool
    var previewPaneOpen: Bool

    static let defaultHome = TabState(
        path: FileManager.default.homeDirectoryForCurrentUser.path,
        viewMode: .list,
        sortField: .name,
        sortDirection: .ascending,
        showHidden: false,
        previewPaneOpen: false
    )
}

struct PaneState: Codable, Hashable {
    var tabs: [TabState]
    var activeTabIndex: Int

    static var defaultHome: PaneState {
        PaneState(tabs: [.defaultHome], activeTabIndex: 0)
    }
}

struct WindowState: Codable, Hashable {
    var panes: [PaneState]
    var activePaneIndex: Int

    static var defaultDual: WindowState {
        WindowState(panes: [.defaultHome, .defaultHome], activePaneIndex: 0)
    }
}

struct AppSnapshot: Codable {
    var windows: [WindowState]
    var favorites: [Favorite]
}
