// SPDX-License-Identifier: MIT
import SwiftUI

struct RenameSheet: View {
    let originalName: String
    @Binding var text: String
    var onCommit: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rename").font(.headline)
            Text("Current: \(originalName)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("New name", text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 340)
                .onSubmit(onCommit)
            HStack {
                Spacer()
                Button("Cancel", action: onCancel).keyboardShortcut(.cancelAction)
                Button("Rename", action: onCommit)
                    .keyboardShortcut(.defaultAction)
                    .disabled(text.isEmpty || text == originalName)
            }
        }
        .padding(18)
    }
}
