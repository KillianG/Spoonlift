// SPDX-License-Identifier: MIT
import SwiftUI

struct PaneToolbar: View {
    @ObservedObject var pane: PaneModel
    @ObservedObject var tab: TabModel
    var onAddFavorite: () -> Void
    var onAddPane: () -> Void
    var onClosePane: () -> Void
    var canClosePane: Bool
    var onNewFolder: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button { tab.goBack() } label: { Image(systemName: "chevron.left") }
                .disabled(!tab.canGoBack)
                .help("Back")

            Button { tab.goForward() } label: { Image(systemName: "chevron.right") }
                .disabled(!tab.canGoForward)
                .help("Forward")

            Button { tab.goUp() } label: { Image(systemName: "arrow.up") }
                .help("Up one level")

            Button { tab.reload() } label: { Image(systemName: "arrow.clockwise") }
                .help("Reload")

            Divider().frame(height: 16)

            viewModePicker

            Menu {
                Picker("Sort by", selection: $tab.sortField) {
                    ForEach(SortField.allCases) { f in
                        Text(f.label).tag(f)
                    }
                }
                Divider()
                Button {
                    tab.sortDirection = .ascending
                } label: {
                    HStack {
                        if tab.sortDirection == .ascending { Image(systemName: "checkmark") }
                        Text("Ascending")
                    }
                }
                Button {
                    tab.sortDirection = .descending
                } label: {
                    HStack {
                        if tab.sortDirection == .descending { Image(systemName: "checkmark") }
                        Text("Descending")
                    }
                }
                Divider()
                Toggle("Show Hidden Files", isOn: $tab.showHidden)
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Sort & display")

            TextField("Search", text: $tab.searchText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 160)

            Spacer()

            Button(action: onNewFolder) { Image(systemName: "folder.badge.plus") }
                .help("New Folder (⇧⌘N)")

            Button { tab.previewPaneOpen.toggle() } label: {
                Image(systemName: "sidebar.right")
                    .foregroundStyle(tab.previewPaneOpen ? Color.accentColor : .secondary)
            }
            .help("Toggle Preview Pane (⌥⌘I)")

            Button(action: onAddFavorite) { Image(systemName: "star") }
                .help("Add current folder to Favorites")

            Button(action: onAddPane) { Image(systemName: "plus.rectangle.on.rectangle") }
                .help("New Pane (⇧⌘T)")

            if canClosePane {
                Button(action: onClosePane) { Image(systemName: "xmark") }
                    .help("Close Pane")
            }
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private var viewModePicker: some View {
        Picker("", selection: $tab.viewMode) {
            ForEach(ViewMode.allCases) { mode in
                Image(systemName: mode.symbol)
                    .tag(mode)
                    .help(helpText(for: mode))
            }
        }
        .pickerStyle(.segmented)
        .fixedSize()
        .help(helpText(for: tab.viewMode))
    }

    private func helpText(for mode: ViewMode) -> String {
        switch mode {
        case .list: return "List view — detailed rows with name, size, kind, date"
        case .icons: return "Icons view — thumbnail grid"
        case .columns: return "Columns view — Finder-style miller columns; click a folder to add a column to its right"
        case .brief: return "Brief view — narrow single-column list"
        }
    }
}
