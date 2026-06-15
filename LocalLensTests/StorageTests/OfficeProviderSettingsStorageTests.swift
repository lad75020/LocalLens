import Foundation
import XCTest
@testable import LocalLens

final class OfficeProviderSettingsStorageTests: XCTestCase {
    func testOfficePreferencesProviderModelHermesProfileAndMetadataPersist() async throws {
        let database = try TestDependencyFactory.temporaryDatabase()
        try await database.migrate()
        let officePreferences = SQLiteOfficePreferencesRepository(database: database)
        let models = SQLiteProviderModelSelectionRepository(database: database)
        let profiles = SQLiteHermesProfileSelectionRepository(database: database)
        let metadata = SQLiteOfficeExtractionMetadataRepository(database: database)

        try await officePreferences.save(OfficeIndexingPreferences(pptxEnabled: true, docxEnabled: false, xlsxEnabled: true))
        let loadedPreferences = try await officePreferences.load()
        XCTAssertEqual(loadedPreferences, OfficeIndexingPreferences(pptxEnabled: true, docxEnabled: false, xlsxEnabled: true))

        let modelState = ProviderModelSelectionState(providerID: "ollama", selectedModelID: "llama3", availableModelIDs: ["llama3"], availabilityState: .available, lastRefreshedAt: Date(), lastSafeError: nil)
        try await models.save(modelState)
        let loadedModel = try await models.get(providerID: "ollama")
        XCTAssertEqual(loadedModel?.selectedModelID, "llama3")

        let profileState = HermesProfileSelectionState(selectedProfileID: "office", selectedProfileDisplayName: "Office", availableProfiles: [HermesProfileSummary(id: "office", displayName: "Office")], availabilityState: .available, lastRefreshedAt: Date(), lastSafeError: nil)
        try await profiles.save(profileState)
        let loadedProfile = try await profiles.load()
        XCTAssertTrue(loadedProfile.isReadyForOfficeIndexing)

        let assetID = UUID()
        try await metadata.save(OfficeExtractionMetadata(assetID: assetID, officeKind: .pptx, providerID: "hermes-agent", hermesProfileID: "office", safeSummary: "summary", safeSnippet: "snippet"))
        let rows = try await metadata.list(assetID: assetID)
        XCTAssertEqual(rows.first?.officeKind, .pptx)
        XCTAssertEqual(rows.first?.hermesProfileID, "office")
    }
}
