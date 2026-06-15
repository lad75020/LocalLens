import Foundation

public actor IndexingPipelineRunner {
    private var isDraining = false

    public init() {}

    public nonisolated func start(
        storage: StorageRepositories,
        queue: IndexQueueActor,
        progressStore: IndexProgressStore,
        coordinator: IndexCoordinator,
        cachePaths: CachePaths,
        bookmarkStore: SecurityScopedBookmarkStore,
        cancellation: IndexCancellation
    ) {
        Task(priority: .background) {
            _ = await self.drainQueuedJobs(
                storage: storage,
                queue: queue,
                progressStore: progressStore,
                coordinator: coordinator,
                cachePaths: cachePaths,
                bookmarkStore: bookmarkStore,
                cancellation: cancellation
            )
        }
    }

    @discardableResult
    public func drainQueuedJobs(
        storage: StorageRepositories,
        queue: IndexQueueActor,
        progressStore: IndexProgressStore,
        coordinator: IndexCoordinator,
        cachePaths: CachePaths,
        bookmarkStore: SecurityScopedBookmarkStore,
        cancellation: IndexCancellation
    ) async -> Int {
        guard !isDraining else { return 0 }
        isDraining = true
        defer { isDraining = false }

        cancellation.reset()
        var processedCount = 0
        await publishSnapshot(queue: queue, progressStore: progressStore)

        while let job = await queue.nextJob() {
            do {
                try cancellation.checkCancellation()
                await queue.markRunning(job.id)
                try await storage.jobs.update(running(job))
                await publishSnapshot(queue: queue, progressStore: progressStore, label: safeLabel(for: job))

                switch job.jobType {
                case .discoverFolder:
                    break
                case .reindexFolder:
                    try await enqueueAssetsForFolder(job.watchedFolderID, storage: storage, queue: queue)
                case .cleanupMissing:
                    _ = try await coordinator.cleanupMissing(storage: storage)
                case .indexAsset, .reindexAsset, .extractThumbnail, .extractText, .transcribe, .sampleVideo, .embedChunks:
                    try await processAssetJob(
                        job,
                        storage: storage,
                        coordinator: coordinator,
                        cachePaths: cachePaths,
                        bookmarkStore: bookmarkStore,
                        cancellation: cancellation
                    )
                }

                await queue.markCompleted(job.id)
                try await storage.jobs.update(completed(job))
                processedCount += 1
                await publishSnapshot(queue: queue, progressStore: progressStore)
            } catch is CancellationError {
                await queue.cancel(jobID: job.id)
                try? await storage.jobs.update(cancelled(job))
                await publishSnapshot(queue: queue, progressStore: progressStore)
                break
            } catch {
                let failure = ExtractionFailure.map(error, defaultCategory: .unknownRedacted)
                await queue.markFailed(job.id, category: failure.category)
                try? await storage.jobs.update(failed(job, category: failure.category))
                try? await storage.failures.save(IndexFailure(
                    id: UUID(),
                    assetID: job.assetID,
                    watchedFolderID: job.watchedFolderID,
                    stage: job.jobType.rawValue,
                    category: failure.category,
                    retryability: failure.retryability,
                    safeMessage: failure.localizedDescription,
                    rawDebugReference: nil,
                    createdAt: Date(),
                    resolvedAt: nil
                ))
                await publishSnapshot(queue: queue, progressStore: progressStore)
            }
        }

        await publishSnapshot(queue: queue, progressStore: progressStore)
        return processedCount
    }

    private func processAssetJob(
        _ job: IndexJob,
        storage: StorageRepositories,
        coordinator: IndexCoordinator,
        cachePaths: CachePaths,
        bookmarkStore: SecurityScopedBookmarkStore,
        cancellation: IndexCancellation
    ) async throws {
        guard let assetID = job.assetID, let asset = try await storage.assets.get(id: assetID) else {
            throw ExtractionFailure.failed(category: .missingFile, retryability: .notRetryable, safeMessage: "Queued asset is no longer available.")
        }
        guard let folder = try await storage.watchedFolders.get(id: asset.watchedFolderID), folder.isEnabled else {
            throw ExtractionFailure.failed(category: .permissionDenied, retryability: .reauthorize, safeMessage: "Watched folder is disabled or unavailable.")
        }

        let scopedAccess = try? bookmarkStore.accessToken(for: folder.bookmarkData)
        let rootURL = scopedAccess?.url ?? URL(fileURLWithPath: folder.displayPath, isDirectory: true)
        defer { scopedAccess?.stop() }
        let sourceURL = rootURL.appendingPathComponent(asset.pathRelativeToFolder)
        let providers = try await storage.providers.list()

        switch asset.mediaType {
        case .image, .pdf:
            _ = await coordinator.indexImageOrPDF(
                asset: asset,
                sourceURL: sourceURL,
                storage: storage,
                cachePaths: cachePaths,
                providers: providers,
                cancellation: cancellation
            )
        case .audio, .video:
            _ = await coordinator.indexAudioVideo(
                asset: asset,
                sourceURL: sourceURL,
                storage: storage,
                providers: providers,
                cancellation: cancellation
            )
        case .office:
            let hermesProfile = try await storage.hermesProfileSelection.load()
            guard hermesProfile.isReadyForOfficeIndexing else {
                throw ExtractionFailure.failed(category: .modelUnavailable, retryability: .retry, safeMessage: "Select an available Hermes Agent profile before indexing Office documents.")
            }
            _ = await coordinator.indexOfficeDocument(
                asset: asset,
                sourceURL: sourceURL,
                storage: storage,
                providers: providers,
                hermesProfile: hermesProfile,
                cancellation: cancellation
            )
        }
    }

    private func enqueueAssetsForFolder(_ folderID: UUID?, storage: StorageRepositories, queue: IndexQueueActor) async throws {
        guard let folderID else { return }
        let assets = try await storage.assets.list(watchedFolderID: folderID)
        for asset in assets where asset.indexState == .queued || asset.indexState == .failed || asset.indexState == .partial || asset.indexState == .cancelled {
            let job = IndexJob(jobType: .reindexAsset, watchedFolderID: folderID, assetID: asset.id, priority: 50, status: .queued)
            try await storage.jobs.enqueue(job)
            await queue.enqueue(job)
        }
    }

    private func publishSnapshot(queue: IndexQueueActor, progressStore: IndexProgressStore, label: String? = nil) async {
        await progressStore.publish(await queue.snapshot(currentSafeLabel: label))
    }

    private func running(_ job: IndexJob) -> IndexJob {
        var updated = job
        updated.status = .indexing
        updated.startedAt = Date()
        return updated
    }

    private func completed(_ job: IndexJob) -> IndexJob {
        var updated = job
        updated.status = .complete
        updated.completedAt = Date()
        return updated
    }

    private func cancelled(_ job: IndexJob) -> IndexJob {
        var updated = job
        updated.status = .cancelled
        updated.completedAt = Date()
        return updated
    }

    private func failed(_ job: IndexJob, category: FailureCategory) -> IndexJob {
        var updated = job
        updated.status = .failed
        updated.lastErrorCategory = category
        updated.completedAt = Date()
        return updated
    }

    private func safeLabel(for job: IndexJob) -> String? {
        switch job.jobType {
        case .discoverFolder:
            return "Discovering folder"
        case .reindexFolder:
            return "Reindexing folder"
        case .cleanupMissing:
            return "Cleaning missing files"
        case .indexAsset, .reindexAsset, .extractThumbnail, .extractText, .transcribe, .sampleVideo, .embedChunks:
            return job.assetID?.uuidString
        }
    }
}
