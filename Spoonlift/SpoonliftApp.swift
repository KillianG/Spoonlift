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
            Button("New Tab") { post(.spoonliftNewTab) }
                .keyboardShortcut("t", modifiers: [.command])
            Button("New Pane") { post(.spoonliftNewPane) }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            Divider()
            Button("Close Tab or Pane") { post(.spoonliftCloseTab) }
                .keyboardShortcut("w", modifiers: [.command])
        }

        CommandGroup(replacing: .pasteboard) {
            Button("Copy") { post(.spoonliftCopy) }
                .keyboardShortcut("c", modifiers: [.command])
            Button("Cut") { post(.spoonliftCut) }
                .keyboardShortcut("x", modifiers: [.command])
            Button("Paste Items") { post(.spoonliftPaste) }
                .keyboardShortcut("v", modifiers: [.command])
            Divider()
            Button("Duplicate") { post(.spoonliftDuplicate) }
                .keyboardShortcut("d", modifiers: [.command])
            Button("Copy Path") { post(.spoonliftCopyPath) }
                .keyboardShortcut("c", modifiers: [.command, .option])
        }

        CommandMenu("Action") {
            Button("Get Info") { post(.spoonliftGetInfo) }
                .keyboardShortcut("i", modifiers: [.command])
            Button("New Folder") { post(.spoonliftNewFolder) }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            Divider()
            Button("Move to Trash") { post(.spoonliftTrash) }
                .keyboardShortcut(.delete, modifiers: [.command])
            Divider()
            Button("Quick Look") { post(.spoonliftQuickLook) }
                .keyboardShortcut(.space, modifiers: [])
        }

        CommandGroup(after: .sidebar) {
            Button("Toggle Hidden Files") { post(.spoonliftToggleHidden) }
                .keyboardShortcut(".", modifiers: [.command, .shift])
            Button("Toggle Preview Pane") { post(.spoonliftTogglePreview) }
                .keyboardShortcut("i", modifiers: [.command, .option])
        }
    }

    private func post(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
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

    static let spoonliftCopy = Notification.Name("spoonlift.copy")
    static let spoonliftCut = Notification.Name("spoonlift.cut")
    static let spoonliftPaste = Notification.Name("spoonlift.paste")
    static let spoonliftDuplicate = Notification.Name("spoonlift.duplicate")
    static let spoonliftCopyPath = Notification.Name("spoonlift.copyPath")
    static let spoonliftTrash = Notification.Name("spoonlift.trash")
    static let spoonliftGetInfo = Notification.Name("spoonlift.getInfo")
    static let spoonliftNewFolder = Notification.Name("spoonlift.newFolder")
    static let spoonliftQuickLook = Notification.Name("spoonlift.quickLook")
}
