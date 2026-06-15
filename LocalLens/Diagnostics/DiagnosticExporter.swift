import Foundation

public struct DiagnosticExporter: Sendable { public let redaction = RedactionPolicy(); public init() {}; public func exportSummary() -> [String: String] { ["redaction":"fullPaths hashed; transcripts/extractedText/credentials/rawProviderBodies omitted"] } }
