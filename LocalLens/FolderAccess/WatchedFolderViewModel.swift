import Foundation

@MainActor
public final class WatchedFolderViewModel: ObservableObject {
    @Published public private(set) var folders: [WatchedFolder] = []
    @Published public private(set) var isLoading = false
    @Published public var statusMessage: String?

    private weak var dependencies: DependencyContainer?

    public init() {}

    public func configure(dependencies: DependencyContainer) {
        guard self.dependencies !== dependencies else { return }
        self.dependencies = dependencies
        refresh()
    }

    public func refresh() {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            guard let self else { return }
            await self.loadFolders(from: dependencies)
        }
    }

    public func loadFolders(from dependencies: DependencyContainer) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await dependencies.database.migrate()
            folders = try await dependencies.storage.watchedFolders.list()
            statusMessage = nil
        } catch {
            statusMessage = "Unable to load watched folders: \(error.localizedDescription)"
        }
    }

    @discardableResult
    public func addFolderFromPanel() async throws -> WatchedFolder? {
        guard let dependencies else { return nil }
        guard let selection = try await dependencies.folderAuthorizationService.requestFolderAuthorization() else { return nil }
        try await persist(selection: selection, dependencies: dependencies)
        return selection.folder
    }

    @discardableResult
    public func addFolder(at url: URL, dependencies explicitDependencies: DependencyContainer? = nil) async throws -> WatchedFolder {
        let dependencies = explicitDependencies ?? self.dependencies
        guard let dependencies else { throw WatchedFolderViewModelError.missingDependencies }
        let selection = try dependencies.folderAuthorizationService.authorizeFolder(at: url)
        try await persist(selection: selection, dependencies: dependencies)
        return selection.folder
    }

    public func setFolder(_ folder: WatchedFolder, enabled: Bool) async throws {
        guard let dependencies else { throw WatchedFolderViewModelError.missingDependencies }
        var updated = folder
        updated.isEnabled = enabled
        updated.updatedAt = Date()
        try await dependencies.storage.watchedFolders.save(updated)
        await loadFolders(from: dependencies)
    }

    public func removeFolder(_ folder: WatchedFolder) async throws {
        guard let dependencies else { throw WatchedFolderViewModelError.missingDependencies }
        try await dependencies.folderAuthorizationService.remove(folder: folder, storage: dependencies.storage)
        await loadFolders(from: dependencies)
    }

    public func reauthorize(_ folder: WatchedFolder) async throws -> WatchedFolder? {
        guard let dependencies else { throw WatchedFolderViewModelError.missingDependencies }
        guard let selection = try await dependencies.folderAuthorizationService.reauthorize(folder) else { return nil }
        try await persist(selection: selection, dependencies: dependencies)
        return selection.folder
    }

    public func queueDiscovery(for folder: WatchedFolder, rootURL: URL, dependencies: DependencyContainer) async throws {
        var scanningFolder = folder
        scanningFolder.lastScanStartedAt = Date()
        scanningFolder.updatedAt = Date()
        try await dependencies.storage.watchedFolders.save(scanningFolder)

        let result = try dependencies.mediaDiscoveryService.discover(in: rootURL, watchedFolderID: folder.id)
        for asset in result.assets {
            try await dependencies.storage.assets.save(asset)
        }
        for job in result.jobs {
            try await dependencies.storage.jobs.enqueue(job)
            await dependencies.indexQueue.enqueue(job)
        }

        scanningFolder.lastScanCompletedAt = Date()
        scanningFolder.updatedAt = Date()
        try await dependencies.storage.watchedFolders.save(scanningFolder)
    }

    private func persist(selection: AuthorizedFolderSelection, dependencies: DependencyContainer) async throws {
        try await dependencies.storage.watchedFolders.save(selection.folder)
        try await queueDiscovery(for: selection.folder, rootURL: selection.url, dependencies: dependencies)
        await loadFolders(from: dependencies)
        statusMessage = "Added \(selection.folder.displayName). Source files were not modified."
    }
}

public enum WatchedFolderViewModelError: Error, Equatable, Sendable {
    case missingDependencies
}
