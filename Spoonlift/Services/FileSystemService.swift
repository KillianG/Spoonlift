// SPDX-License-Identifier: MIT
import Foundation
import AppKit

enum FileSystemService {
    static func listDirectory(_ url: URL, showHidden: Bool = false) -> [FileItem] {
        var options: FileManager.DirectoryEnumerationOptions = [.skipsSubdirectoryDescendants]
        if !showHidden { options.insert(.skipsHiddenFiles) }
        let keys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey]
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: keys,
            options: options
        ) else { return [] }
        return contents.compactMap(FileItem.load)
    }

    static func listVolumes() -> [URL] {
        let keys: [URLResourceKey] = [.volumeURLKey, .volumeIsBrowsableKey, .volumeNameKey]
        let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) ?? []
        let browsable: Set<URLResourceKey> = [.volumeIsBrowsableKey]
        return urls.filter { url in
            let values = try? url.resourceValues(forKeys: browsable)
            return values?.volumeIsBrowsable ?? true
        }
    }

    static func canEject(_ url: URL) -> Bool {
        let keys: Set<URLResourceKey> = [.volumeIsEjectableKey, .volumeIsRemovableKey]
        guard let v = try? url.resourceValues(forKeys: keys) else { return false }
        return (v.volumeIsEjectable ?? false) || (v.volumeIsRemovable ?? false)
    }

    @discardableResult
    static func eject(_ url: URL) -> Bool {
        do {
            try NSWorkspace.shared.unmountAndEjectDevice(at: url)
            return true
        } catch {
            NSLog("Spoonlift: eject failed for %@ — %@", url.path, error.localizedDescription)
            return false
        }
    }

    static func volumeName(_ url: URL) -> String {
        if let v = try? url.resourceValues(forKeys: [.volumeNameKey]),
           let name = v.volumeName, !name.isEmpty {
            return name
        }
        return url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
    }

    @discardableResult
    static func moveToTrash(_ urls: [URL]) -> [URL: URL?] {
        var results: [URL: URL?] = [:]
        for url in urls {
            var resulting: NSURL?
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: &resulting)
                results[url] = (resulting as URL?)
            } catch {
                results[url] = nil
            }
        }
        return results
    }

    static func rename(_ url: URL, to newName: String) -> URL? {
        guard !newName.isEmpty, newName != url.lastPathComponent else { return nil }
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try FileManager.default.moveItem(at: url, to: newURL)
            return newURL
        } catch {
            return nil
        }
    }

    @discardableResult
    static func duplicate(_ url: URL) -> URL? {
        let fm = FileManager.default
        let parent = url.deletingLastPathComponent()
        let ext = url.pathExtension
        let base = url.deletingPathExtension().lastPathComponent

        func build(_ suffix: String) -> URL {
            let name = ext.isEmpty ? "\(base) \(suffix)" : "\(base) \(suffix).\(ext)"
            return parent.appendingPathComponent(name)
        }

        var candidate = build("copy")
        var i = 2
        while fm.fileExists(atPath: candidate.path) {
            candidate = build("copy \(i)")
            i += 1
            if i > 999 { return nil }
        }
        do {
            try fm.copyItem(at: url, to: candidate)
            return candidate
        } catch {
            return nil
        }
    }

    static func makeDirectory(in parent: URL, named name: String) -> URL? {
        let target = parent.appendingPathComponent(name)
        do {
            try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)
            return target
        } catch {
            return nil
        }
    }

    static func standardLocations() -> [(name: String, symbol: String, url: URL)] {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        var items: [(String, String, URL)] = [
            ("Home", "house", home),
            ("Desktop", "menubar.dock.rectangle", home.appendingPathComponent("Desktop")),
            ("Documents", "doc", home.appendingPathComponent("Documents")),
            ("Downloads", "arrow.down.circle", home.appendingPathComponent("Downloads")),
            ("Pictures", "photo", home.appendingPathComponent("Pictures")),
            ("Music", "music.note", home.appendingPathComponent("Music")),
            ("Movies", "film", home.appendingPathComponent("Movies")),
            ("Applications", "app", URL(fileURLWithPath: "/Applications"))
        ]
        let icloud = home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")
        if fm.fileExists(atPath: icloud.path) {
            items.append(("iCloud Drive", "icloud", icloud))
        }
        return items
    }
}
