import Foundation

public struct QuickLookPreviewService: Sendable { public init() {}; public func canPreview(_ url: URL) -> Bool { FileManager.default.fileExists(atPath: url.path) } }
