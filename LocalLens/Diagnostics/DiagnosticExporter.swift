import CryptoKit
import Foundation

public struct DiagnosticExport: Codable, Equatable, Sendable {
    public var appVersion: String
    public var schemaVersion: Int
    public var createdAt: Date
    public var counts: DiagnosticCounts
    public var providerHealth: [DiagnosticProviderHealth]
    public var failureCategories: [DiagnosticFailureCategory]
    public var pathHashes: [String]
    public var redaction: DiagnosticRedaction
}

public struct DiagnosticCounts: Codable, Equatable, Sendable {
    public var watchedFolders: Int
    public var assets: Int
    public var failures: Int
}

public struct DiagnosticProviderHealth: Codable, Equatable, Sendable {
    public var id: String
    public var locality: ProviderLocality
    public var status: ProviderHealthStatus
}

public struct DiagnosticFailureCategory: Codable, Equatable, Sendable {
    public var category: FailureCategory
    public var count: Int
}

public struct DiagnosticRedaction: Codable, Equatable, Sendable {
    public var fullPaths = "hashed"
    public var transcripts = "omitted"
    public var extractedText = "omitted"
    public var credentials = "omitted"
    public var thumbnails = "omitted"
    public var prompts = "omitted"
    public var rawProviderBodies = "omitted"
}

public struct DiagnosticExporter: Sendable {
    public let redaction = RedactionPolicy()

    public init() {}

    public func exportSummary() -> [String: String] {
        [
            "redaction": "fullPaths hashed; transcripts/extractedText/credentials/prompts/thumbnails/rawProviderBodies omitted",
            "sourceFiles": "read-only; no source bytes included"
        ]
    }

    public func export(storage: StorageRepositories, providers: [ProviderSetting], createdAt: Date = Date()) async throws -> DiagnosticExport {
        let folders = try await storage.watchedFolders.list()
        let assets = try await storage.assets.list(watchedFolderID: nil)
        let failures = try await storage.failures.unresolved()
        let categoryCounts = Dictionary(grouping: failures, by: \.category)
            .map { DiagnosticFailureCategory(category: $0.key, count: $0.value.count) }
            .sorted { $0.category.rawValue < $1.category.rawValue }

        return DiagnosticExport(
            appVersion: "LocalLens 0.1",
            schemaVersion: 1,
            createdAt: createdAt,
            counts: DiagnosticCounts(watchedFolders: folders.count, assets: assets.count, failures: failures.count),
            providerHealth: providers.map { DiagnosticProviderHealth(id: $0.id, locality: $0.locality, status: $0.lastHealthStatus) },
            failureCategories: categoryCounts,
            pathHashes: folders.map { Self.hashPath($0.displayPath) }.sorted(),
            redaction: DiagnosticRedaction()
        )
    }

    public func exportRedactedJSON(storage: StorageRepositories, providers: [ProviderSetting]) async throws -> Data {
        let export = try await export(storage: storage, providers: providers)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(export)
    }

    public func writeRedactedExport(storage: StorageRepositories, providers: [ProviderSetting], cachePaths: CachePaths) async throws -> URL {
        let data = try await exportRedactedJSON(storage: storage, providers: providers)
        try cachePaths.ensureDirectories()
        let url = cachePaths.diagnostics(named: "locallens-diagnostics-\(Int(Date().timeIntervalSince1970))")
        try data.write(to: url, options: [.atomic])
        return url
    }

    public static func hashPath(_ path: String) -> String {
        let digest = SHA256.hash(data: Data(path.utf8))
        return digest.prefix(12).map { String(format: "%02x", $0) }.joined()
    }
}
