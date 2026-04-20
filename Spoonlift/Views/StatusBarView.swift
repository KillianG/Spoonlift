// SPDX-License-Identifier: MIT
import SwiftUI

struct StatusBarView: View {
    @ObservedObject var tab: TabModel

    var body: some View {
        HStack(spacing: 6) {
            Text("\(tab.displayedItems.count) items")
            if !tab.selection.isEmpty {
                Text("·")
                Text("\(tab.selection.count) selected")
            }
            Spacer()
            if let free = freeSpace {
                Text("\(free) free").foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }

    private var freeSpace: String? {
        let keys: Set<URLResourceKey> = [.volumeAvailableCapacityKey]
        guard let values = try? tab.currentURL.resourceValues(forKeys: keys),
              let avail = values.volumeAvailableCapacity else { return nil }
        return ByteCountFormatter.string(fromByteCount: Int64(avail), countStyle: .file)
    }
}
