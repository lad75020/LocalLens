import Foundation

public protocol ExtractorService: Sendable { associatedtype Output: Sendable; func extract(from url: URL) async throws -> Output }
