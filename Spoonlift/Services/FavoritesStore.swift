// SPDX-License-Identifier: MIT
import Foundation
import SwiftUI

@MainActor
final class FavoritesStore: ObservableObject {
    @Published var favorites: [Favorite] {
        didSet { persist() }
    }

    private let key = "spoonlift.favorites.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Favorite].self, from: data) {
            self.favorites = decoded
            return
        }
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.favorites = [
            Favorite(name: "Home", path: home.path),
            Favorite(name: "Downloads", path: home.appendingPathComponent("Downloads").path),
            Favorite(name: "Documents", path: home.appendingPathComponent("Documents").path)
        ]
    }

    func add(_ url: URL) {
        guard !favorites.contains(where: { $0.path == url.path }) else { return }
        let name = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
        favorites.append(Favorite(name: name, path: url.path))
    }

    func remove(_ favorite: Favorite) {
        favorites.removeAll { $0.id == favorite.id }
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        favorites.move(fromOffsets: source, toOffset: destination)
    }

    func replaceAll(_ favorites: [Favorite]) {
        self.favorites = favorites
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
