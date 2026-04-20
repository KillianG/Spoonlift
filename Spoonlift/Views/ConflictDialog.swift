// SPDX-License-Identifier: MIT
import SwiftUI

struct ConflictDialog: View {
    let context: ConflictContext
    var resolve: (ConflictResolution) -> Void
    @State private var applyToAll: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("An item with the same name already exists", systemImage: "exclamationmark.triangle")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                row("Source", context.source.path)
                row("Destination", context.destination.path)
            }

            Toggle("Apply to all remaining conflicts", isOn: $applyToAll)

            HStack {
                Button("Cancel") { resolve(.cancel) }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Skip") {
                    resolve(applyToAll ? .skipAll : .skip)
                }
                Button("Keep Both") {
                    resolve(applyToAll ? .keepBothAll : .keepBoth)
                }
                Button("Replace") {
                    resolve(applyToAll ? .replaceAll : .replace)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 520)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label + ":").foregroundStyle(.secondary).frame(width: 90, alignment: .trailing)
            Text(value).lineLimit(2).truncationMode(.middle)
        }
        .font(.callout)
    }
}
