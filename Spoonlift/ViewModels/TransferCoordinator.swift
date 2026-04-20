// SPDX-License-Identifier: MIT
import Foundation
import SwiftUI

@MainActor
final class TransferCoordinator: ObservableObject {
    struct Transfer: Identifiable {
        let id = UUID()
        let kind: FileOperationKind
        let totalItems: Int
        var completedItems: Int = 0
        var currentSource: URL?
        var currentDestination: URL?
        var errors: [(URL, String)] = []
        var finished: Bool = false

        var progress: Double {
            totalItems == 0 ? 0 : Double(completedItems) / Double(totalItems)
        }
    }

    struct PendingConflict: Identifiable {
        let id = UUID()
        let context: ConflictContext
        let resume: (ConflictResolution) -> Void
    }

    @Published var transfers: [Transfer] = []
    @Published var pendingConflict: PendingConflict?

    var isActive: Bool {
        transfers.contains { !$0.finished }
    }

    func start(kind: FileOperationKind, sources: [URL], destinationDir: URL) {
        let transfer = Transfer(kind: kind, totalItems: sources.count)
        transfers.append(transfer)
        let transferID = transfer.id

        let handler: ConflictHandler = { [weak self] ctx in
            guard let self else { return .skip }
            return await withCheckedContinuation { cont in
                Task { @MainActor in
                    self.pendingConflict = PendingConflict(context: ctx) { resolution in
                        self.pendingConflict = nil
                        cont.resume(returning: resolution)
                    }
                }
            }
        }

        Task { [weak self] in
            let stream = FileOperationService.run(
                kind: kind,
                sources: sources,
                destinationDir: destinationDir,
                handleConflict: handler
            )
            for await event in stream {
                await MainActor.run {
                    self?.ingest(event, for: transferID)
                }
            }
        }
    }

    private func ingest(_ event: FileOperationEvent, for transferID: UUID) {
        guard let idx = transfers.firstIndex(where: { $0.id == transferID }) else { return }
        switch event {
        case .started:
            break
        case .itemBegan(let source, let destination):
            transfers[idx].currentSource = source
            transfers[idx].currentDestination = destination
        case .itemCompleted:
            transfers[idx].completedItems += 1
        case .itemFailed(let source, let error):
            transfers[idx].errors.append((source, error))
            transfers[idx].completedItems += 1
        case .finished, .cancelled:
            transfers[idx].finished = true
            scheduleCleanup(id: transferID)
        }
    }

    private func scheduleCleanup(id: UUID) {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard let self else { return }
            self.transfers.removeAll { $0.id == id && $0.finished }
        }
    }

    func resolve(_ resolution: ConflictResolution) {
        pendingConflict?.resume(resolution)
    }
}
