import Foundation
import XCTest
@testable import LocalLens

final class HermesProfileSelectionTests: XCTestCase {
    func testSelectedHermesProfileReadinessAndStaleState() {
        let ready = HermesProfileSelectionState(selectedProfileID: "office", selectedProfileDisplayName: "Office", availableProfiles: [HermesProfileSummary(id: "office", displayName: "Office")], availabilityState: .available)
        XCTAssertTrue(ready.isReadyForOfficeIndexing)
        let stale = HermesProfileSelectionState(selectedProfileID: "missing", selectedProfileDisplayName: "Missing", availableProfiles: [HermesProfileSummary(id: "office", displayName: "Office")], availabilityState: .stale)
        XCTAssertFalse(stale.isReadyForOfficeIndexing)
    }
}
