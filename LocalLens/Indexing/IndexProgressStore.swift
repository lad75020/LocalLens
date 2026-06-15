import Foundation

public actor IndexProgressStore {
    private var latestSnapshot = IndexProgressSnapshot()
    private var continuations: [UUID: AsyncStream<IndexProgressSnapshot>.Continuation] = [:]

    public init() {}

    public var snapshot: IndexProgressSnapshot { latestSnapshot }

    public func publish(_ snapshot: IndexProgressSnapshot) {
        let sanitized = Self.redacted(snapshot)
        latestSnapshot = sanitized
        for continuation in continuations.values {
            continuation.yield(sanitized)
        }
    }

    public func loadPersistedSnapshot(_ snapshot: IndexProgressSnapshot) {
        publish(snapshot)
    }

    public func updates(bufferingPolicy: AsyncStream<IndexProgressSnapshot>.Continuation.BufferingPolicy = .bufferingNewest(16)) -> AsyncStream<IndexProgressSnapshot> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            let id = UUID()
            Task { await self.addContinuation(continuation, id: id) }
            continuation.onTermination = { @Sendable _ in
                Task { await self.removeContinuation(id: id) }
            }
        }
    }

    public func makePersistableSummary() -> [String: String] {
        [
            "isRunning": latestSnapshot.isRunning ? "true" : "false",
            "isPaused": latestSnapshot.isPaused ? "true" : "false",
            "queuedCount": "\(latestSnapshot.queuedCount)",
            "runningCount": "\(latestSnapshot.runningCount)",
            "completedCount": "\(latestSnapshot.completedCount)",
            "failedCount": "\(latestSnapshot.failedCount)",
            "cancelledCount": "\(latestSnapshot.cancelledCount)",
            "currentSafeLabel": latestSnapshot.currentSafeLabel ?? "",
            "lastIndexedAt": latestSnapshot.lastIndexedAt.map { ISO8601DateFormatter().string(from: $0) } ?? ""
        ]
    }

    private func addContinuation(_ continuation: AsyncStream<IndexProgressSnapshot>.Continuation, id: UUID) {
        continuations[id] = continuation
        continuation.yield(latestSnapshot)
    }

    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }

    private static func redacted(_ snapshot: IndexProgressSnapshot) -> IndexProgressSnapshot {
        var sanitized = snapshot
        if let label = snapshot.currentSafeLabel {
            let filenameOnly = label
                .replacingOccurrences(of: "\\", with: "/")
                .split(separator: "/")
                .last
                .map(String.init) ?? label
            sanitized.currentSafeLabel = String(filenameOnly.prefix(80))
        }
        return sanitized
    }
}
