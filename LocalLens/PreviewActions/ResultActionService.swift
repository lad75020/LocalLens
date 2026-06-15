import Foundation

public final class ResultActionService: @unchecked Sendable {
    private let quickLookPreviewService: QuickLookPreviewService
    private let finderRevealService: FinderRevealService
    private let clipboardActionService: ClipboardActionService
    @MainActor private var previewSession: QuickLookPreviewSession?

    public init(
        quickLookPreviewService: QuickLookPreviewService = QuickLookPreviewService(),
        finderRevealService: FinderRevealService = FinderRevealService(),
        clipboardActionService: ClipboardActionService = ClipboardActionService()
    ) {
        self.quickLookPreviewService = quickLookPreviewService
        self.finderRevealService = finderRevealService
        self.clipboardActionService = clipboardActionService
    }

    @MainActor
    public func perform(
        _ action: ResultActionKind,
        result: SearchResultDTO,
        storage: StorageRepositories
    ) async -> ResultActionOutcome {
        do {
            let asset = try await requireAsset(result.assetID, storage: storage)
            let folder = try await requireFolder(asset.watchedFolderID, storage: storage)
            switch action {
            case .quickLook:
                previewSession = try quickLookPreviewService.preview(asset: asset, folder: folder)
                return ResultActionOutcome(action: action, safeMessage: "Preview opened.")
            case .revealInFinder:
                _ = try finderRevealService.reveal(asset: asset, folder: folder)
                return ResultActionOutcome(action: action, safeMessage: "Revealed in Finder.")
            case .openDefault:
                _ = try finderRevealService.open(asset: asset, folder: folder)
                return ResultActionOutcome(action: action, safeMessage: "Opened in the default app.")
            case .copyPath:
                _ = try clipboardActionService.copyPath(asset: asset, folder: folder)
                return ResultActionOutcome(action: action, safeMessage: "Source path copied.")
            case .copySnippet:
                _ = try clipboardActionService.copySnippet(result)
                return ResultActionOutcome(action: action, safeMessage: "Snippet copied.")
            }
        } catch {
            return ResultActionOutcome(
                action: action,
                safeMessage: (error as? LocalizedError)?.errorDescription ?? "Action failed with a redacted local error."
            )
        }
    }

    private func requireAsset(_ id: UUID, storage: StorageRepositories) async throws -> MediaAsset {
        guard let asset = try await storage.assets.get(id: id) else { throw ResultActionError.assetNotFound }
        return asset
    }

    private func requireFolder(_ id: UUID, storage: StorageRepositories) async throws -> WatchedFolder {
        guard let folder = try await storage.watchedFolders.get(id: id) else { throw ResultActionError.folderNotFound }
        return folder
    }
}
