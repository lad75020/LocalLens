import XCTest
@testable import LocalLens

final class GeneratedContentFTSSearchTests: XCTestCase {
    func testGeneratedImagePDFAndOfficeTextAreSearchableByUniqueTokens() async throws {
        let database = try TestDependencyFactory.temporaryDatabase()
        try await database.migrate()
        let storage = SearchTestSupport.storage(database: database)
        let folder = SearchTestSupport.folder(displayName: "Generated", displayPath: "/redacted/Generated")
        try await storage.watchedFolders.save(folder)

        let image = SearchTestSupport.asset(folderID: folder.id, filename: "image.png", mediaType: .image)
        let pdf = SearchTestSupport.asset(folderID: folder.id, filename: "summary.pdf", mediaType: .pdf)
        let office = SearchTestSupport.asset(folderID: folder.id, filename: "deck.pptx", mediaType: .office)
        try await storage.assets.save(image)
        try await storage.assets.save(pdf)
        try await storage.assets.save(office)

        try await storage.chunks.save(SearchTestSupport.chunk(assetID: image.id, type: .imageDescription, text: "generated image token LL_IMAGE_UNIQUE_TOKEN"))
        try await storage.chunks.save(SearchTestSupport.chunk(assetID: pdf.id, type: .pdfSummary, text: "generated pdf token LL_PDF_UNIQUE_TOKEN"))
        try await storage.chunks.save(SearchTestSupport.chunk(assetID: office.id, type: .officeSummary, text: "generated office token LL_OFFICE_UNIQUE_TOKEN"))

        let search = SearchService()
        let imageResults = await search.search(SearchRequest(query: "LL_IMAGE_UNIQUE_TOKEN"), storage: storage)
        let pdfResults = await search.search(SearchRequest(query: "LL_PDF_UNIQUE_TOKEN"), storage: storage)
        let officeResults = await search.search(SearchRequest(query: "LL_OFFICE_UNIQUE_TOKEN"), storage: storage)

        XCTAssertTrue(imageResults.contains { $0.assetID == image.id && $0.matchReasons.contains(.imageDescription) })
        XCTAssertTrue(pdfResults.contains { $0.assetID == pdf.id && $0.matchReasons.contains(.pdfSummary) })
        XCTAssertTrue(officeResults.contains { $0.assetID == office.id && $0.matchReasons.contains(.officeSummary) })
    }
}
