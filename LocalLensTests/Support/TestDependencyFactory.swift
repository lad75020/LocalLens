import Foundation
@testable import LocalLens

final class TestDependencyFactory {
    static func temporaryDatabase() throws -> LocalLensDatabase {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return try LocalLensDatabase(databaseURL: root.appendingPathComponent("test.sqlite"), cacheRootURL: root.appendingPathComponent("cache", isDirectory: true))
    }
}
