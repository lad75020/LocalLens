import Foundation

public enum ResultActionKind: String, CaseIterable, Sendable, Equatable {
    case quickLook
    case revealInFinder
    case openDefault
    case copyPath
    case copySnippet

    public var label: String {
        switch self {
        case .quickLook: "Preview"
        case .revealInFinder: "Reveal"
        case .openDefault: "Open"
        case .copyPath: "Copy Path"
        case .copySnippet: "Copy Snippet"
        }
    }

    public var systemImage: String {
        switch self {
        case .quickLook: "eye"
        case .revealInFinder: "folder"
        case .openDefault: "arrow.up.right.square"
        case .copyPath: "doc.on.doc"
        case .copySnippet: "quote.bubble"
        }
    }
}

public enum ResultActionError: Error, Equatable, Sendable, LocalizedError {
    case noSelection
    case assetNotFound
    case folderNotFound
    case invalidRelativePath
    case missingFile
    case accessDenied
    case staleBookmark
    case invalidBookmark
    case previewUnavailable
    case openFailed
    case clipboardUnavailable

    public var errorDescription: String? {
        switch self {
        case .noSelection: "Select a result first."
        case .assetNotFound: "The indexed asset could not be found."
        case .folderNotFound: "The watched folder could not be found."
        case .invalidRelativePath: "The indexed file path is invalid."
        case .missingFile: "The source file is missing."
        case .accessDenied: "LocalLens needs folder access before opening this file."
        case .staleBookmark: "Folder access is stale. Reauthorize the watched folder in Settings."
        case .invalidBookmark: "Folder access could not be restored. Reauthorize the watched folder in Settings."
        case .previewUnavailable: "Quick Look preview is unavailable for this file."
        case .openFailed: "The file could not be opened."
        case .clipboardUnavailable: "The clipboard could not be updated."
        }
    }
}

public struct ResultActionOutcome: Equatable, Sendable {
    public let action: ResultActionKind
    public let safeMessage: String

    public init(action: ResultActionKind, safeMessage: String) {
        self.action = action
        self.safeMessage = safeMessage
    }
}

public final class ResolvedResultFile: @unchecked Sendable {
    public let asset: MediaAsset
    public let folder: WatchedFolder
    public let fileURL: URL
    private let accessToken: SecurityScopedAccessToken

    public init(asset: MediaAsset, folder: WatchedFolder, fileURL: URL, accessToken: SecurityScopedAccessToken) {
        self.asset = asset
        self.folder = folder
        self.fileURL = fileURL
        self.accessToken = accessToken
    }

    deinit { accessToken.stop() }
}

public struct ResultFileResolver: Sendable {
    private let bookmarkStore: SecurityScopedBookmarkStore

    public init(bookmarkStore: SecurityScopedBookmarkStore = SecurityScopedBookmarkStore()) {
        self.bookmarkStore = bookmarkStore
    }

    public func resolve(asset: MediaAsset, folder: WatchedFolder) throws -> ResolvedResultFile {
        do {
            let token = try bookmarkStore.accessToken(for: folder.bookmarkData)
            let rootURL = token.url.standardizedFileURL
            let relativePath = asset.pathRelativeToFolder
            guard !relativePath.isEmpty, !relativePath.hasPrefix("/"), !relativePath.split(separator: "/").contains("..") else {
                token.stop()
                throw ResultActionError.invalidRelativePath
            }
            let fileURL = rootURL.appendingPathComponent(relativePath).standardizedFileURL
            guard Self.isContained(fileURL, in: rootURL) else {
                token.stop()
                throw ResultActionError.invalidRelativePath
            }
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                token.stop()
                throw ResultActionError.missingFile
            }
            return ResolvedResultFile(asset: asset, folder: folder, fileURL: fileURL, accessToken: token)
        } catch let error as ResultActionError {
            throw error
        } catch let error as SecurityScopedBookmarkError {
            throw Self.map(error)
        }
    }

    private static func isContained(_ child: URL, in root: URL) -> Bool {
        let rootPath = root.standardizedFileURL.path
        let childPath = child.standardizedFileURL.path
        return childPath == rootPath || childPath.hasPrefix(rootPath.hasSuffix("/") ? rootPath : rootPath + "/")
    }

    private static func map(_ error: SecurityScopedBookmarkError) -> ResultActionError {
        switch error {
        case .accessDenied: .accessDenied
        case .staleBookmark: .staleBookmark
        case .invalidBookmark: .invalidBookmark
        }
    }
}
