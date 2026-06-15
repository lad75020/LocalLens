import XCTest
@testable import LocalLens

final class DiagnosticExporterTests: XCTestCase {
    func testRedactedExportOmitsSensitiveContentAndHashesPaths() async throws {
        let database = try TestDependencyFactory.temporaryDatabase()
        try await database.migrate()
        let storage = SearchTestSupport.storage(database: database)
        let folder = SearchTestSupport.folder(displayPath: "/Users/laurent/Secret/Family")
        try await storage.watchedFolders.save(folder)
        let asset = SearchTestSupport.asset(folderID: folder.id, filename: "private.pdf", mediaType: .pdf)
        try await storage.assets.save(asset)
        try await storage.failures.save(IndexFailure(id: UUID(), assetID: asset.id, watchedFolderID: folder.id, stage: "pdfText", category: .passwordProtectedPDF, retryability: .ignore, safeMessage: "Password-protected PDF.", rawDebugReference: "debug-ref", createdAt: Date(), resolvedAt: nil))

        let providers = ProviderRegistry().defaultProviders()
        let data = try await DiagnosticExporter().exportRedactedJSON(storage: storage, providers: providers)
        let text = String(data: data, encoding: .utf8) ?? ""

        XCTAssertTrue(text.contains("hashed"))
        XCTAssertTrue(text.contains("omitted"))
        XCTAssertFalse(text.contains("/Users/laurent/Secret/Family"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("transcript body"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("api_key"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("rawProviderBodies" ) == false)
    }
}
