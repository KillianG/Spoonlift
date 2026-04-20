// SPDX-License-Identifier: MIT
import Foundation

enum FileOperationKind: Sendable {
    case copy, move
}

enum FileOperationEvent: Sendable {
    case started(totalItems: Int)
    case itemBegan(source: URL, destination: URL)
    case itemCompleted(source: URL, destination: URL)
    case itemFailed(source: URL, error: String)
    case finished
    case cancelled
}

enum ConflictResolution: Sendable {
    case replace, skip, keepBoth
    case replaceAll, skipAll, keepBothAll
    case cancel
}

struct ConflictContext: Sendable {
    let source: URL
    let destination: URL
}

typealias ConflictHandler = @Sendable (ConflictContext) async -> ConflictResolution

enum FileOperationService {
    static func run(
        kind: FileOperationKind,
        sources: [URL],
        destinationDir: URL,
        handleConflict: @escaping ConflictHandler
    ) -> AsyncStream<FileOperationEvent> {
        AsyncStream { continuation in
            let task = Task.detached(priority: .userInitiated) {
                await execute(
                    kind: kind,
                    sources: sources,
                    destinationDir: destinationDir,
                    handleConflict: handleConflict,
                    yield: { continuation.yield($0) }
                )
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func execute(
        kind: FileOperationKind,
        sources: [URL],
        destinationDir: URL,
        handleConflict: @escaping ConflictHandler,
        yield: @Sendable (FileOperationEvent) -> Void
    ) async {
        let fm = FileManager.default
        yield(.started(totalItems: sources.count))

        var globalPolicy: ConflictResolution?

        for src in sources {
            if Task.isCancelled {
                yield(.cancelled)
                return
            }

            var dst = destinationDir.appendingPathComponent(src.lastPathComponent)

            if src.standardizedFileURL == dst.standardizedFileURL {
                yield(.itemFailed(source: src, error: "Source and destination are the same"))
                continue
            }

            if fm.fileExists(atPath: dst.path) {
                let action: ConflictResolution
                if let g = globalPolicy {
                    action = g
                } else {
                    action = await handleConflict(ConflictContext(source: src, destination: dst))
                }

                let normalized: ConflictResolution
                switch action {
                case .cancel:
                    yield(.cancelled)
                    return
                case .skipAll:
                    globalPolicy = .skipAll
                    normalized = .skip
                case .replaceAll:
                    globalPolicy = .replaceAll
                    normalized = .replace
                case .keepBothAll:
                    globalPolicy = .keepBothAll
                    normalized = .keepBoth
                default:
                    normalized = action
                }

                switch normalized {
                case .skip:
                    yield(.itemCompleted(source: src, destination: dst))
                    continue
                case .replace:
                    try? fm.removeItem(at: dst)
                case .keepBoth:
                    dst = uniqueURL(for: dst)
                default:
                    break
                }
            }

            yield(.itemBegan(source: src, destination: dst))

            do {
                switch kind {
                case .copy:
                    try fm.copyItem(at: src, to: dst)
                case .move:
                    try fm.moveItem(at: src, to: dst)
                }
                yield(.itemCompleted(source: src, destination: dst))
            } catch {
                yield(.itemFailed(source: src, error: error.localizedDescription))
            }
        }

        yield(.finished)
    }

    private static func uniqueURL(for url: URL) -> URL {
        let fm = FileManager.default
        let dir = url.deletingLastPathComponent()
        let ext = url.pathExtension
        let base = url.deletingPathExtension().lastPathComponent
        var i = 2
        while true {
            let name = ext.isEmpty ? "\(base) \(i)" : "\(base) \(i).\(ext)"
            let candidate = dir.appendingPathComponent(name)
            if !fm.fileExists(atPath: candidate.path) { return candidate }
            i += 1
            if i > 9999 { return candidate }
        }
    }
}
