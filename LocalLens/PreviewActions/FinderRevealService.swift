import AppKit
import Foundation

public struct FinderRevealService: Sendable {
    public typealias RevealHandler = @MainActor @Sendable (URL) -> Void
    public typealias OpenHandler = @MainActor @Sendable (URL) -> Bool

    private let resolver: ResultFileResolver
    private let revealHandler: RevealHandler
    private let openHandler: OpenHandler

    public init(
        resolver: ResultFileResolver = ResultFileResolver(),
        revealHandler: @escaping RevealHandler = { url in
            if !CommandLine.arguments.contains("--ui-testing") {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        },
        openHandler: @escaping OpenHandler = { url in
            if CommandLine.arguments.contains("--ui-testing") { return true }
            return NSWorkspace.shared.open(url)
        }
    ) {
        self.resolver = resolver
        self.revealHandler = revealHandler
        self.openHandler = openHandler
    }

    @MainActor
    public func reveal(asset: MediaAsset, folder: WatchedFolder) throws -> URL {
        let resolved = try resolver.resolve(asset: asset, folder: folder)
        revealHandler(resolved.fileURL)
        return resolved.fileURL
    }

    @MainActor
    public func open(asset: MediaAsset, folder: WatchedFolder) throws -> URL {
        let resolved = try resolver.resolve(asset: asset, folder: folder)
        guard openHandler(resolved.fileURL) else { throw ResultActionError.openFailed }
        return resolved.fileURL
    }

    @MainActor
    public func reveal(_ url: URL) {
        revealHandler(url)
    }
}
