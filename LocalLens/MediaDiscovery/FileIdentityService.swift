import Foundation

public struct FileIdentityService: Sendable { public init() {}; public func signature(for url: URL) throws -> String { let r = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]); return "\(r.fileSize ?? 0)-\(r.contentModificationDate?.timeIntervalSince1970 ?? 0)" } }
