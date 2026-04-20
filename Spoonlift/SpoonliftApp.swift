// SPDX-License-Identifier: MIT
import SwiftUI

@main
struct SpoonliftApp: App {
    @StateObject private var appModel = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup(id: "spoonlift.window") {
            WindowRoot()
                .environmentObject(appModel)
                .environmentObject(appModel.favorites)
                .frame(minWidth: 960, minHeight: 600)
        }
        .commands {
            AppCommands()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background { appModel.saveSession() }
        }
    }
}

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            NewWindowButton()
            Button("New Tab") {
                NotificationCenter.default.post(name: .spoonliftNewTab, object: nil)
            }
            .keyboardShortcut("t", modifiers: [.command])
            Button("New Pane") {
                NotificationCenter.default.post(name: .spoonliftNewPane, object: nil)
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
            Divider()
            Button("Close Tab or Pane") {
                NotificationCenter.default.post(name: .spoonliftCloseTab, object: nil)
            }
            .keyboardShortcut("w", modifiers: [.command])
        }
        CommandGroup(after: .sidebar) {
            Button("Toggle Hidden Files") {
                NotificationCenter.default.post(name: .spoonliftToggleHidden, object: nil)
            }
            .keyboardShortcut(".", modifiers: [.command, .shift])
            Button("Toggle Preview Pane") {
                NotificationCenter.default.post(name: .spoonliftTogglePreview, object: nil)
            }
            .keyboardShortcut("i", modifiers: [.command, .option])
        }
    }
}

private struct NewWindowButton: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("New Window") {
            openWindow(id: "spoonlift.window")
        }
        .keyboardShortcut("n", modifiers: [.command])
    }
}

extension Notification.Name {
    static let spoonliftNewTab = Notification.Name("spoonlift.newTab")
    static let spoonliftNewPane = Notification.Name("spoonlift.newPane")
    static let spoonliftCloseTab = Notification.Name("spoonlift.closeTab")
    static let spoonliftToggleHidden = Notification.Name("spoonlift.toggleHidden")
    static let spoonliftTogglePreview = Notification.Name("spoonlift.togglePreview")
}
