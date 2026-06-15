import Foundation

public struct MediaDiscoveryService: Sendable { public let resolver = MediaTypeResolver(); public init() {}; public func supportedFiles(in folder: URL) -> [URL] { (FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil)?.compactMap { $0 as? URL }.filter { resolver.mediaType(for: $0) != nil }) ?? [] } }
