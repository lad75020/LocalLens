import Foundation

public actor IndexQueueActor {
    private var jobs: [UUID: IndexJob] = [:]
    private var paused = false

    public init() {}

    public func load(_ durableJobs: [IndexJob]) {
        jobs = Dictionary(uniqueKeysWithValues: durableJobs.map { ($0.id, $0) })
    }

    public func enqueue(_ job: IndexJob) {
        jobs[job.id] = job
    }

    public func allJobs() -> [IndexJob] {
        jobs.values.sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
            return lhs.createdAt < rhs.createdAt
        }
    }

    public func pause() { paused = true }
    public func resume() { paused = false }

    public func cancel(jobID: UUID) {
        guard var job = jobs[jobID] else { return }
        job.status = .cancelled
        job.completedAt = Date()
        jobs[jobID] = job
    }

    public func cancelRunning() {
        for id in jobs.keys {
            guard jobs[id]?.status == .indexing else { continue }
            cancel(jobID: id)
        }
    }

    public func retry(jobID: UUID) {
        guard var job = jobs[jobID] else { return }
        job.status = .queued
        job.attemptCount += 1
        job.lastErrorCategory = nil
        job.startedAt = nil
        job.completedAt = nil
        jobs[jobID] = job
    }

    public func markFailed(_ id: UUID, category: FailureCategory) {
        guard var job = jobs[id] else { return }
        job.status = .failed
        job.lastErrorCategory = category
        job.completedAt = Date()
        jobs[id] = job
    }

    public func markIgnored(_ id: UUID) {
        guard var job = jobs[id] else { return }
        job.status = .failed
        job.lastErrorCategory = .unknownRedacted
        job.completedAt = Date()
        jobs[id] = job
    }

    public func nextJob() -> IndexJob? {
        guard !paused else { return nil }
        return jobs.values
            .filter { $0.status == .queued }
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
                return lhs.createdAt < rhs.createdAt
            }
            .first
    }

    public func markRunning(_ id: UUID) {
        guard var job = jobs[id] else { return }
        job.status = .indexing
        job.startedAt = Date()
        jobs[id] = job
    }

    public func markCompleted(_ id: UUID) {
        guard var job = jobs[id] else { return }
        job.status = .complete
        job.completedAt = Date()
        jobs[id] = job
    }

    public func snapshot(currentSafeLabel: String? = nil) -> IndexProgressSnapshot {
        IndexProgressSnapshot(
            isRunning: jobs.values.contains { $0.status == .indexing },
            isPaused: paused,
            queuedCount: jobs.values.filter { $0.status == .queued }.count,
            runningCount: jobs.values.filter { $0.status == .indexing }.count,
            completedCount: jobs.values.filter { $0.status == .complete }.count,
            failedCount: jobs.values.filter { $0.status == .failed }.count,
            cancelledCount: jobs.values.filter { $0.status == .cancelled }.count,
            currentSafeLabel: currentSafeLabel,
            lastIndexedAt: jobs.values.compactMap(\.completedAt).max()
        )
    }
}
