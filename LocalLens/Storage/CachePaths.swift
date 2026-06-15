import Foundation

public struct CachePaths: Sendable {
    public let root: URL
    public init(root: URL) { self.root = root }
    public func thumbnails(for assetID: UUID) -> URL { root.appendingPathComponent("Thumbnails", isDirectory: true).appendingPathComponent(assetID.uuidString).appendingPathExtension("png") }
    public func transcripts(for assetID: UUID) -> URL { root.appendingPathComponent("Transcripts", isDirectory: true).appendingPathComponent(assetID.uuidString).appendingPathExtension("txt") }
    public func keyframes(for assetID: UUID) -> URL { root.appendingPathComponent("Keyframes", isDirectory: true).appendingPathComponent(assetID.uuidString, isDirectory: true) }
    public func diagnostics(named name: String) -> URL { root.appendingPathComponent("Diagnostics", isDirectory: true).appendingPathComponent(name).appendingPathExtension("json") }
    public func temporary(_ name: String = UUID().uuidString) -> URL { root.appendingPathComponent("Temporary", isDirectory: true).appendingPathComponent(name) }
    public func ensureDirectories() throws { for url in [root.appendingPathComponent("Thumbnails", isDirectory: true), root.appendingPathComponent("Transcripts", isDirectory: true), root.appendingPathComponent("Keyframes", isDirectory: true), root.appendingPathComponent("Diagnostics", isDirectory: true), root.appendingPathComponent("Temporary", isDirectory: true)] { try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true) } }
}
