// SPDX-License-Identifier: MIT
import SwiftUI

/// Subscribes a view to every Spoonlift shortcut notification and forwards
/// the notification's name to `handler` — but only when `isActive` is true.
///
/// Lives in its own file because inlining all the `.onReceive` modifiers on
/// `TabContentView.body` trips the Swift type-checker's complexity budget.
struct TabShortcutListener: ViewModifier {
    let isActive: Bool
    let handler: (Notification.Name) -> Void

    private static let names: [Notification.Name] = [
        .spoonliftCopy,
        .spoonliftCut,
        .spoonliftPaste,
        .spoonliftDuplicate,
        .spoonliftCopyPath,
        .spoonliftTrash,
        .spoonliftGetInfo,
        .spoonliftNewFolder,
        .spoonliftQuickLook
    ]

    func body(content: Content) -> some View {
        content.background(
            ForEach(Self.names, id: \.rawValue) { name in
                Color.clear
                    .frame(width: 0, height: 0)
                    .onReceive(NotificationCenter.default.publisher(for: name)) { _ in
                        guard isActive else { return }
                        handler(name)
                    }
            }
        )
    }
}
