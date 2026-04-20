// SPDX-License-Identifier: MIT
import SwiftUI

struct TransferProgressWindow: View {
    @EnvironmentObject var transfers: TransferCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(transfers.transfers) { transfer in
                transferRow(transfer)
                if transfer.id != transfers.transfers.last?.id {
                    Divider()
                }
            }
        }
        .padding(12)
        .frame(maxWidth: 420)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }

    private func transferRow(_ t: TransferCoordinator.Transfer) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: t.kind == .copy ? "doc.on.doc" : "arrow.right.doc.on.clipboard")
                Text(t.kind == .copy ? "Copying" : "Moving")
                    .font(.headline)
                Spacer()
                Text("\(t.completedItems) / \(t.totalItems)")
                    .monospacedDigit()
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: t.progress)
                .progressViewStyle(.linear)
            if let src = t.currentSource {
                Text(src.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            if !t.errors.isEmpty {
                Text("\(t.errors.count) error\(t.errors.count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }
}
