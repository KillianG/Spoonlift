// SPDX-License-Identifier: MIT
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    let favorites: FavoritesStore
    private var windows: [WindowModel] = []
    private let sessionStore = SessionStore()
    private var hasConsumedSnapshot = false
    private var pendingSnapshots: [WindowState] = []

    init() {
        self.favorites = FavoritesStore()
        if let snap = sessionStore.load() {
            pendingSnapshots = snap.windows
        }
    }

    func register(_ window: WindowModel) {
        windows.append(window)
        if !pendingSnapshots.isEmpty {
            let state = pendingSnapshots.removeFirst()
            window.restore(from: state)
        } else if !hasConsumedSnapshot {
            hasConsumedSnapshot = true
            window.restore(from: .defaultDual)
        } else {
            window.restore(from: .defaultDual)
        }
        if !pendingSnapshots.isEmpty { hasConsumedSnapshot = true }
    }

    func unregister(_ window: WindowModel) {
        windows.removeAll { $0.id == window.id }
    }

    func saveSession() {
        let snap = AppSnapshot(
            windows: windows.map { $0.snapshot() },
            favorites: favorites.favorites
        )
        sessionStore.save(snap)
    }
}
