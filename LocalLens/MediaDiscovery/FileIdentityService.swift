import CryptoKit
import Foundation

public struct FileIdentity: Equatable, Sendable {
    public let fileIdentity: String
    public let pathHash: String
    public let signature: String
    public let sizeBytes: Int64
    public let createdAtFile: Date?
    public let modifiedAtFile: Date?

    public init(fileIdentity: String, pathHash: String, signature: String, sizeBytes: Int64, createdAtFile: Date?, modifiedAtFile: Date?) {
        self.fileIdentity = fileIdentity
        self.pathHash = pathHash
        self.signature = signature
        self.sizeBytes = sizeBytes
        self.createdAtFile = createdAtFile
        self.modifiedAtFile = modifiedAtFile
    }
}

public struct FileIdentityService: Sendable {
    public init() {}

    public func identity(for url: URL) throws -> FileIdentity {
        let values = try url.resourceValues(forKeys: [
            .fileResourceIdentifierKey,
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey
        ])
        let size = Int64(values.fileSize ?? 0)
        let modified = values.contentModificationDate
        let created = values.creationDate
        let resourceIdentifier = values.fileResourceIdentifier.map { String(describing: $0) }
        let fallbackIdentifier = Self.sha256(url.standardizedFileURL.path)
        let fileIdentity = resourceIdentifier ?? fallbackIdentifier
        let signature = [
            fileIdentity,
            String(size),
            String(modified?.timeIntervalSince1970 ?? 0)
        ].joined(separator: ":")
        return FileIdentity(
            fileIdentity: fileIdentity,
            pathHash: Self.sha256(url.standardizedFileURL.path),
            signature: signature,
            sizeBytes: size,
            createdAtFile: created,
            modifiedAtFile: modified
        )
    }

    public func signature(for url: URL) throws -> String {
        try identity(for: url).signature
    }

    private static func sha256(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
