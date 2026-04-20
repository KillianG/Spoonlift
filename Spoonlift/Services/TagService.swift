// SPDX-License-Identifier: MIT
import Foundation

enum TagService {
    static func tags(of url: URL) -> [String] {
        guard let v = try? url.resourceValues(forKeys: [.tagNamesKey]) else { return [] }
        return v.tagNames ?? []
    }

    static func setTags(_ tags: [String], for url: URL) throws {
        try (url as NSURL).setResourceValue(tags as NSArray, forKey: .tagNamesKey)
    }

    static func addTag(_ tag: String, to url: URL) throws {
        var current = tags(of: url)
        guard !current.contains(tag) else { return }
        current.append(tag)
        try setTags(current, for: url)
    }

    static func removeTag(_ tag: String, from url: URL) throws {
        let current = tags(of: url).filter { $0 != tag }
        try setTags(current, for: url)
    }

    static func toggleTag(_ tag: String, for url: URL) throws {
        var current = tags(of: url)
        if let idx = current.firstIndex(of: tag) {
            current.remove(at: idx)
        } else {
            current.append(tag)
        }
        try setTags(current, for: url)
    }
}
