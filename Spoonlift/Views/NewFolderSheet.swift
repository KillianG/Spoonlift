// SPDX-License-Identifier: MIT
import SwiftUI

struct NewFolderSheet: View {
    @Binding var name: String
    var onCommit: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Folder").font(.headline)
            TextField("Folder name", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 320)
                .onSubmit(onCommit)
            HStack {
                Spacer()
                Button("Cancel", action: onCancel).keyboardShortcut(.cancelAction)
                Button("Create", action: onCommit)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(18)
    }
}
