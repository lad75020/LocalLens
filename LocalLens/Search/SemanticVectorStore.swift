import Foundation

public struct SemanticVectorStore: Sendable { public init() {}; public func cosine(_ a: [Float], _ b: [Float]) -> Float { guard a.count == b.count, !a.isEmpty else { return 0 }; let dot = zip(a,b).map(*).reduce(0,+); let na = sqrt(a.map { $0*$0 }.reduce(0,+)); let nb = sqrt(b.map { $0*$0 }.reduce(0,+)); return na == 0 || nb == 0 ? 0 : dot/(na*nb) } }
