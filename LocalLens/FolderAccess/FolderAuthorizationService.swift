import AppKit
import CryptoKit
import Foundation

public struct AuthorizedFolderSelection: Equatable, Sendable {
    public let folder: WatchedFolder
    public let url: URL

    public init(folder: WatchedFolder, url: URL) {
        self.folder = folder
        self.url = url
    }
}

public enum FolderAuthorizationError: Error, Equatable, Sendable {
    case notDirectory(String)
    case missingFolder(String)
}

@MainActor
public final class FolderAuthorizationService {
    public typealias FolderPanelRunner = @MainActor @Sendable () async -> URL?

    private let bookmarkStore: SecurityScopedBookmarkStore
    private let panelRunner: FolderPanelRunner

    public init(
        bookmarkStore: SecurityScopedBookmarkStore = SecurityScopedBookmarkStore(),
        panelRunner: @escaping FolderPanelRunner = FolderAuthorizationService.defaultFolderPanel
    ) {
        self.bookmarkStore = bookmarkStore
        self.panelRunner = panelRunner
    }

    public func requestFolderAuthorization() async throws -> AuthorizedFolderSelection? {
        guard let url = await panelRunner() else { return nil }
        return try authorizeFolder(at: url)
    }

    public func authorizeFolder(at url: URL) throws -> AuthorizedFolderSelection {
        let standardizedURL = url.standardizedFileURL
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: standardizedURL.path, isDirectory: &isDirectory) else {
            throw FolderAuthorizationError.missingFolder(standardizedURL.path)
        }
        guard isDirectory.boolValue else {
            throw FolderAuthorizationError.notDirectory(standardizedURL.path)
        }

        let bookmark = try bookmarkStore.makeBookmark(for: standardizedURL)
        let now = Date()
        let folder = WatchedFolder(
            displayName: standardizedURL.lastPathComponent.isEmpty ? standardizedURL.path : standardizedURL.lastPathComponent,
            bookmarkData: bookmark,
            originalPathHash: Self.hashPath(standardizedURL.path),
            displayPath: standardizedURL.path,
            isEnabled: true,
            authorizationState: .authorized,
            createdAt: now,
            updatedAt: now
        )
        return AuthorizedFolderSelection(folder: folder, url: standardizedURL)
    }

    public func restoreAccess(for folder: WatchedFolder) throws -> SecurityScopedAccessToken {
        try bookmarkStore.accessToken(for: folder.bookmarkData)
    }

    public func resolveURL(for folder: WatchedFolder) throws -> SecurityScopedBookmarkResolution {
        try bookmarkStore.resolve(folder.bookmarkData)
    }

    public func reauthorize(_ folder: WatchedFolder) async throws -> AuthorizedFolderSelection? {
        guard let selection = try await requestFolderAuthorization() else { return nil }
        var updated = selection.folder
        updated.id = folder.id
        updated.createdAt = folder.createdAt
        updated.updatedAt = Date()
        return AuthorizedFolderSelection(folder: updated, url: selection.url)
    }

    public func remove(folder: WatchedFolder, storage: StorageRepositories) async throws {
        try await storage.assets.removeByWatchedFolder(id: folder.id)
        try await storage.watchedFolders.remove(id: folder.id)
    }

    public static func defaultFolderPanel() async -> URL? {
        if let testPath = ProcessInfo.processInfo.environment["LOCALLENS_UI_TEST_FOLDER"], !testPath.isEmpty {
            return URL(fileURLWithPath: testPath, isDirectory: true)
        }

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = "Add Folder"
        panel.message = "Choose a folder LocalLens may read for private local indexing. Source files are never modified."
        let response = panel.runModal()
        return response == .OK ? panel.url : nil
    }

    private static func hashPath(_ path: String) -> String {
        SHA256.hash(data: Data(path.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
