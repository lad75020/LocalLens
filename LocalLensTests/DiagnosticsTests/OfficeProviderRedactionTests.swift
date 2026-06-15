import Foundation
import XCTest
@testable import LocalLens

final class OfficeProviderRedactionTests: XCTestCase {
    func testRedactionOmitsPromptsOfficeTextProviderBodiesAndModelErrors() {
        let policy = RedactionPolicy()
        XCTAssertFalse(policy.redactPrompt("Use /docx with private content").contains("private content"))
        XCTAssertFalse(policy.redactOfficeText("Ignore previous instructions").contains("Ignore previous"))
        XCTAssertFalse(policy.redactProviderBody(Data("raw body secret".utf8)).contains("raw body secret"))
        XCTAssertFalse(policy.redactModelOrProfileError("/Users/laurent/private sk-live-secret").contains("/Users/laurent/private"))
    }

    func testDiagnosticExportIncludesOnlySafeSelectionMetadata() async throws {
        let database = try TestDependencyFactory.temporaryDatabase()
        try await database.migrate()
        let storage = StorageRepositories(
            watchedFolders: SQLiteWatchedFolderRepository(database: database),
            assets: SQLiteMediaAssetRepository(database: database),
            extractionRecords: SQLiteExtractionRecordRepository(database: database),
            chunks: SQLiteSearchableChunkRepository(database: database),
            jobs: SQLiteIndexJobRepository(database: database),
            failures: SQLiteIndexFailureRepository(database: database),
            providers: SQLiteProviderSettingsRepository(database: database),
            appSettings: SQLiteAppSettingsRepository(database: database),
            officePreferences: SQLiteOfficePreferencesRepository(database: database),
            providerModelSelections: SQLiteProviderModelSelectionRepository(database: database),
            hermesProfileSelection: SQLiteHermesProfileSelectionRepository(database: database),
            officeExtractionMetadata: SQLiteOfficeExtractionMetadataRepository(database: database),
            maintenance: StorageMaintenanceRepository(database: database)
        )
        try await storage.officePreferences.save(OfficeIndexingPreferences(pptxEnabled: true, docxEnabled: true, xlsxEnabled: false))
        try await storage.providerModelSelections.save(ProviderModelSelectionState(providerID: "ollama", selectedModelID: "llama3", availableModelIDs: ["llama3"], availabilityState: .available))
        try await storage.hermesProfileSelection.save(HermesProfileSelectionState(selectedProfileID: "office", selectedProfileDisplayName: "Office", availableProfiles: [HermesProfileSummary(id: "office", displayName: "Office")], availabilityState: .available))
        let data = try await DiagnosticExporter().exportRedactedJSON(storage: storage, providers: [])
        let json = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(json.contains("office"))
        XCTAssertFalse(json.contains("Ignore previous instructions"))
        XCTAssertFalse(json.contains("sk-live"))
    }
}
