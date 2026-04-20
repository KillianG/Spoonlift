// SPDX-License-Identifier: MIT
import AppKit

enum Pasteboard {
    private static let cutFlagType = NSPasteboard.PasteboardType("com.spoonlift.cut")

    static func copy(_ urls: [URL]) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects(urls as [NSURL])
    }

    static func cut(_ urls: [URL]) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects(urls as [NSURL])
        pb.setString("1", forType: cutFlagType)
    }

    static func copyPath(_ urls: [URL]) {
        let pb = NSPasteboard.general
        pb.clearContents()
        let joined = urls.map(\.path).joined(separator: "\n")
        pb.setString(joined, forType: .string)
    }

    static func read() -> (urls: [URL], isCut: Bool) {
        let pb = NSPasteboard.general
        let urls = (pb.readObjects(forClasses: [NSURL.self]) as? [URL]) ?? []
        let isCut = pb.string(forType: cutFlagType) == "1"
        return (urls, isCut)
    }

    static var hasFiles: Bool {
        let objects = NSPasteboard.general.readObjects(forClasses: [NSURL.self]) as? [URL]
        return !(objects ?? []).isEmpty
    }
}
