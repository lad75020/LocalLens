import Foundation

public struct SearchRanker: Sendable { public init() {}; public func score(lexical: Double, semantic: Double) -> Double { lexical + semantic } }
