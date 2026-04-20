// SPDX-License-Identifier: MIT
import SwiftUI
import AppKit

struct GetInfoSheet: View {
    let url: URL
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text(url.lastPathComponent)
                        .font(.headline)
                        .textSelection(.enabled)
                    Text(kindText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            Divider()
            row("Where", url.deletingLastPathComponent().path)
            row("Size", sizeText)
            row("Created", formattedDate(creationDate))
            row("Modified", formattedDate(modifiedDate))
            if !tagList.isEmpty {
                row("Tags", tagList.joined(separator: ", "))
            }
            HStack {
                Button("Reveal in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
                Spacer()
                Button("Done", action: onDismiss).keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(minWidth: 440)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label + ":")
                .frame(width: 90, alignment: .trailing)
                .foregroundStyle(.secondary)
            Text(value)
                .textSelection(.enabled)
                .lineLimit(3)
                .truncationMode(.middle)
            Spacer(minLength: 0)
        }
        .font(.callout)
    }

    private var kindText: String {
        let keys: Set<URLResourceKey> = [.localizedTypeDescriptionKey, .isDirectoryKey]
        guard let v = try? url.resourceValues(forKeys: keys) else { return "Item" }
        return v.localizedTypeDescription ?? (v.isDirectory == true ? "Folder" : "File")
    }

    private var sizeText: String {
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey, .totalFileAllocatedSizeKey]
        guard let v = try? url.resourceValues(forKeys: keys) else { return "—" }
        if v.isDirectory == true { return "—" }
        let size = Int64(v.fileSize ?? v.totalFileAllocatedSize ?? 0)
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    private var creationDate: Date? {
        (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate
    }

    private var modifiedDate: Date? {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }

    private var tagList: [String] {
        TagService.tags(of: url)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
