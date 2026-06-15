import Foundation

public struct SnippetBuilder: Sendable { public init() {}; public func snippet(text: String, around query: String, limit: Int = 180) -> String { String(text.prefix(limit)) } }
