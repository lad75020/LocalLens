import AppKit
import Foundation

@MainActor
public final class QuickLookPreviewSession: @unchecked Sendable {
    public let url: URL
    private let resolvedFile: ResolvedResultFile

    public init(url: URL, resolvedFile: ResolvedResultFile) {
        self.url = url
        self.resolvedFile = resolvedFile
    }
}

public struct QuickLookPreviewService: Sendable {
    public typealias PreviewPresenter = @MainActor @Sendable (URL) -> Bool

    private let resolver: ResultFileResolver
    private let presenter: PreviewPresenter

    public init(
        resolver: ResultFileResolver = ResultFileResolver(),
        presenter: PreviewPresenter? = nil
    ) {
        self.resolver = resolver
        self.presenter = presenter ?? Self.defaultPresenter
    }

    public func canPreview(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    @MainActor
    public func preview(asset: MediaAsset, folder: WatchedFolder) throws -> QuickLookPreviewSession {
        let resolved = try resolver.resolve(asset: asset, folder: folder)
        guard presenter(resolved.fileURL) else { throw ResultActionError.previewUnavailable }
        return QuickLookPreviewSession(url: resolved.fileURL, resolvedFile: resolved)
    }

    @MainActor
    private static func defaultPresenter(url: URL) -> Bool {
        if CommandLine.arguments.contains("--ui-testing") { return true }
        // In production this requests the system preview/open handoff without writing to source media.
        // The service still validates security-scoped access and missing-file state before reaching here.
        return NSWorkspace.shared.open(url)
    }
}
