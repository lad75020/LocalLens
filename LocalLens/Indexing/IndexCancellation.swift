import Foundation

public final class IndexCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    public init() {}
    public func cancel() { lock.withLock { cancelled = true } }
    public func reset() { lock.withLock { cancelled = false } }
    public func checkCancellation() throws { if isCancelled { throw CancellationError() } }
    public var isCancelled: Bool { lock.withLock { cancelled } }
}

public struct IndexProgressSnapshot: Equatable, Sendable {
    public var isRunning: Bool = false
    public var isPaused: Bool = false
    public var queuedCount: Int = 0
    public var runningCount: Int = 0
    public var completedCount: Int = 0
    public var failedCount: Int = 0
    public var cancelledCount: Int = 0
    public var currentSafeLabel: String?
    public var lastIndexedAt: Date?
}

public actor ProgressSink {
    public private(set) var snapshot = IndexProgressSnapshot()
    public init() {}
    public func publish(_ update: IndexProgressSnapshot) { snapshot = update }
}

extension NSLock { func withLock<T>(_ body: () throws -> T) rethrows -> T { lock(); defer { unlock() }; return try body() } }
