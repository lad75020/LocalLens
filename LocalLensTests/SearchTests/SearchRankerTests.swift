import XCTest
@testable import LocalLens

final class SearchRankerTests: XCTestCase {
    func testRankingReasonsSnippetsAndHintsAreDeterministic() {
        let folder = SearchTestSupport.folder(displayName: "Research")
        let asset = SearchTestSupport.asset(folderID: folder.id, filename: "report.pdf", mediaType: .pdf)
        let chunk = SearchTestSupport.chunk(assetID: asset.id, type: .pdfText, text: "Before text. LocalLens found the annual budget phrase on this page. After text.", pageNumber: 3)
        let semantic = SearchTestSupport.chunk(assetID: asset.id, type: .semantic, text: "financial report", embedding: [1, 0], embeddingModel: "local")
        let candidate = SearchCandidate(asset: asset, folder: folder, chunks: [chunk, semantic], lexicalScore: 6, semanticScore: 4, semanticChunkIDs: [semantic.id])

        let dto = SearchRanker().resultDTO(for: candidate, request: SearchRequest(query: "annual budget"))

        XCTAssertEqual(dto.assetID, asset.id)
        XCTAssertTrue(dto.matchReasons.contains(.pdfText))
        XCTAssertTrue(dto.matchReasons.contains(.semantic))
        XCTAssertEqual(dto.pageNumber, 3)
        XCTAssertTrue(dto.snippet?.contains("annual budget") == true)
    }

    func testMissingAssetsArePenalizedAndCanBeExcludedByService() async throws {
        let db = try TestDependencyFactory.temporaryDatabase()
        try await db.migrate()
        let storage = SearchTestSupport.storage(database: db)
        let folder = SearchTestSupport.folder()
        try await storage.watchedFolders.save(folder)
        let present = SearchTestSupport.asset(folderID: folder.id, filename: "present-sunset.jpg", indexState: .complete)
        let missing = SearchTestSupport.asset(folderID: folder.id, filename: "missing-sunset.jpg", indexState: .missing)
        try await storage.assets.save(present)
        try await storage.assets.save(missing)

        let service = SearchService()
        let hiddenMissing = await service.search(SearchRequest(query: "sunset", includeMissing: false), storage: storage, providers: [])
        let shownMissing = await service.search(SearchRequest(query: "sunset", includeMissing: true), storage: storage, providers: [])

        XCTAssertEqual(hiddenMissing.map(\.assetID), [present.id])
        XCTAssertTrue(shownMissing.contains { $0.assetID == missing.id && $0.isMissing })
        XCTAssertLessThan(shownMissing.first { $0.assetID == missing.id }?.score ?? 0, shownMissing.first { $0.assetID == present.id }?.score ?? 0)
    }

    func testTimestampHintIsMappedIntoDTO() {
        let folder = SearchTestSupport.folder(displayName: "Audio")
        let asset = SearchTestSupport.asset(folderID: folder.id, filename: "meeting.m4a", mediaType: .audio)
        let transcript = SearchTestSupport.chunk(assetID: asset.id, type: .transcript, text: "discussion about semantic search", timestampStart: 42, timestampEnd: 47)
        let candidate = SearchCandidate(asset: asset, folder: folder, chunks: [transcript], lexicalScore: 5)

        let dto = SearchRanker().resultDTO(for: candidate, request: SearchRequest(query: "semantic search"))
        XCTAssertEqual(dto.timestampStart, 42)
        XCTAssertEqual(dto.timestampEnd, 47)
        XCTAssertTrue(dto.matchReasons.contains(.transcript))
    }
}
