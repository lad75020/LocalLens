import Foundation

public enum SecurityScopedBookmarkError: Error, Equatable, Sendable {
    case accessDenied(String)
    case staleBookmark(String)
    case invalidBookmark(String)
}

public struct SecurityScopedBookmarkResolution: Equatable, Sendable {
    public let url: URL
    public let isStale: Bool

    public init(url: URL, isStale: Bool) {
        self.url = url
        self.isStale = isStale
    }
}

public final class SecurityScopedAccessToken: @unchecked Sendable {
    public let url: URL
    public let isStale: Bool

    private let stopHandler: @Sendable (URL) -> Void
    private let lock = NSLock()
    private var stopped = false

    public init(url: URL, isStale: Bool, stopHandler: @escaping @Sendable (URL) -> Void) {
        self.url = url
        self.isStale = isStale
        self.stopHandler = stopHandler
    }

    deinit {
        stop()
    }

    public func stop() {
        lock.lock()
        let shouldStop = !stopped
        stopped = true
        lock.unlock()

        if shouldStop {
            stopHandler(url)
        }
    }
}

public struct SecurityScopedBookmarkStore: Sendable {
    public typealias BookmarkCreator = @Sendable (URL) throws -> Data
    public typealias BookmarkResolver = @Sendable (Data) throws -> SecurityScopedBookmarkResolution
    public typealias AccessStarter = @Sendable (URL) -> Bool
    public typealias AccessStopper = @Sendable (URL) -> Void

    private let createBookmarkData: BookmarkCreator
    private let resolveBookmarkData: BookmarkResolver
    private let startAccessing: AccessStarter
    private let stopAccessing: AccessStopper

    public init(
        createBookmarkData: @escaping BookmarkCreator = SecurityScopedBookmarkStore.defaultCreateBookmarkData,
        resolveBookmarkData: @escaping BookmarkResolver = SecurityScopedBookmarkStore.defaultResolveBookmarkData,
        startAccessing: @escaping AccessStarter = { $0.startAccessingSecurityScopedResource() },
        stopAccessing: @escaping AccessStopper = { $0.stopAccessingSecurityScopedResource() }
    ) {
        self.createBookmarkData = createBookmarkData
        self.resolveBookmarkData = resolveBookmarkData
        self.startAccessing = startAccessing
        self.stopAccessing = stopAccessing
    }

    public func makeBookmark(for folderURL: URL) throws -> Data {
        try createBookmarkData(folderURL)
    }

    public func resolve(_ bookmarkData: Data) throws -> SecurityScopedBookmarkResolution {
        try resolveBookmarkData(bookmarkData)
    }

    public func accessToken(for bookmarkData: Data) throws -> SecurityScopedAccessToken {
        let resolution = try resolve(bookmarkData)
        if resolution.isStale {
            throw SecurityScopedBookmarkError.staleBookmark(resolution.url.path)
        }
        guard startAccessing(resolution.url) else {
            throw SecurityScopedBookmarkError.accessDenied(resolution.url.path)
        }
        return SecurityScopedAccessToken(url: resolution.url, isStale: resolution.isStale, stopHandler: stopAccessing)
    }

    public static func defaultCreateBookmarkData(for folderURL: URL) throws -> Data {
        try folderURL.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    public static func defaultResolveBookmarkData(_ data: Data) throws -> SecurityScopedBookmarkResolution {
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            return SecurityScopedBookmarkResolution(url: url, isStale: isStale)
        } catch {
            throw SecurityScopedBookmarkError.invalidBookmark(error.localizedDescription)
        }
    }
}
