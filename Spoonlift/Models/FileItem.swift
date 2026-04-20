// SPDX-License-Identifier: MIT
import Foundation
import AppKit

struct FileItem: Identifiable, Hashable {
    var id: URL { url }
    let url: URL
    let name: String
    let isDirectory: Bool
    let isPackage: Bool
    let isSymlink: Bool
    let isHidden: Bool
    let size: Int64
    let modified: Date
    let created: Date
    let kind: String
    let tagNames: [String]

    static func load(_ url: URL) -> FileItem? {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey, .isPackageKey, .isSymbolicLinkKey, .isHiddenKey,
            .fileSizeKey, .totalFileAllocatedSizeKey,
            .contentModificationDateKey, .creationDateKey,
            .localizedTypeDescriptionKey, .tagNamesKey
        ]
        guard let v = try? url.resourceValues(forKeys: keys) else { return nil }
        let isDir = v.isDirectory ?? false
        let size = Int64(v.fileSize ?? v.totalFileAllocatedSize ?? 0)
        return FileItem(
            url: url,
            name: url.lastPathComponent,
            isDirectory: isDir,
            isPackage: v.isPackage ?? false,
            isSymlink: v.isSymbolicLink ?? false,
            isHidden: v.isHidden ?? false,
            size: size,
            modified: v.contentModificationDate ?? .distantPast,
            created: v.creationDate ?? .distantPast,
            kind: v.localizedTypeDescription ?? (isDir ? "Folder" : "File"),
            tagNames: v.tagNames ?? []
        )
    }

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}
