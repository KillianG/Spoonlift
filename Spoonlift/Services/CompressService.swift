// SPDX-License-Identifier: MIT
import Foundation

enum CompressService {
    static func zip(urls: [URL], in parentDir: URL, completion: @escaping () -> Void) {
        guard !urls.isEmpty else {
            DispatchQueue.main.async { completion() }
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let fm = FileManager.default
            let baseName: String = urls.count == 1
                ? urls[0].deletingPathExtension().lastPathComponent
                : "Archive"

            var output = parentDir.appendingPathComponent("\(baseName).zip")
            var counter = 2
            while fm.fileExists(atPath: output.path) {
                output = parentDir.appendingPathComponent("\(baseName) \(counter).zip")
                counter += 1
                if counter > 999 { break }
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
            process.currentDirectoryURL = parentDir
            var args = ["-r", "-q", output.path]
            args += urls.map { $0.lastPathComponent }
            process.arguments = args
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                NSLog("Spoonlift: zip failed — %@", error.localizedDescription)
            }
            DispatchQueue.main.async { completion() }
        }
    }
}
