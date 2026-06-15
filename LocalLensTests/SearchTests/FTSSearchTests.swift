import XCTest
@testable import LocalLens

final class FTSSearchTests: XCTestCase {
    func testSearchServiceFindsFilenameOCRPDFTranscriptAndVisualLabels() async throws {
        let db = try TestDependencyFactory.temporaryDatabase()
        try await db.migrate()
        let storage = SearchTestSupport.storage(database: db)
        let folder = SearchTestSupport.folder()
        try await storage.watchedFolders.save(folder)

        let image = SearchTestSupport.asset(folderID: folder.id, filename: "sunset-beach.png", mediaType: .image)
        let ocr = SearchTestSupport.asset(folderID: folder.id, filename: "scan.png", mediaType: .image)
        let pdf = SearchTestSupport.asset(folderID: folder.id, filename: "invoice.pdf", mediaType: .pdf)
        let audio = SearchTestSupport.asset(folderID: folder.id, filename: "interview.m4a", mediaType: .audio)
        let label = SearchTestSupport.asset(folderID: folder.id, filename: "objects.jpg", mediaType: .image)
        for asset in [image, ocr, pdf, audio, label] { try await storage.assets.save(asset) }

        try await storage.chunks.save(SearchTestSupport.chunk(assetID: image.id, type: .filename, text: image.filename))
        try await storage.chunks.save(SearchTestSupport.chunk(assetID: ocr.id, type: .visibleText, text: "visible sign says espresso bar"))
        try await storage.chunks.save(SearchTestSupport.chunk(assetID: pdf.id, type: .pdfText, text: "quarterly tax receipt page", pageNumber: 2))
        try await storage.chunks.save(SearchTestSupport.chunk(assetID: audio.id, type: .transcript, text: "speaker mentions private local search", timestampStart: 12, timestampEnd: 17))
        try await storage.chunks.save(SearchTestSupport.chunk(assetID: label.id, type: .visualLabel, text: "red bicycle, helmet, city street"))

        let service = SearchService()
        let filenameResults = await service.search(SearchRequest(query: "sunset"), storage: storage, providers: [])
        let ocrResults = await service.search(SearchRequest(query: "espresso"), storage: storage, providers: [])
        let pdfResults = await service.search(SearchRequest(query: "tax receipt"), storage: storage, providers: [])
        let transcriptResults = await service.search(SearchRequest(query: "private local"), storage: storage, providers: [])
        let labelResults = await service.search(SearchRequest(query: "bicycle"), storage: storage, providers: [])

        XCTAssertEqual(filenameResults.first?.assetID, image.id)
        XCTAssertTrue(ocrResults.first?.matchReasons.contains(.visibleText) == true)
        XCTAssertEqual(pdfResults.first?.pageNumber, 2)
        XCTAssertEqual(transcriptResults.first?.timestampStart, 12)
        XCTAssertTrue(labelResults.first?.matchReasons.contains(.visualLabel) == true)
    }
}
