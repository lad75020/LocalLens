import Foundation
import XCTest
@testable import LocalLens

final class OfficeProviderPerformanceTests: XCTestCase {
    func testOfficePolicyAndPromptConstructionAreResponsive() throws {
        measure {
            for _ in 0..<100 {
                _ = OfficeDiscoveryPolicy(pptxEnabled: true, docxEnabled: true, xlsxEnabled: true, hermesReadyForOfficeIndexing: true).allows(.pptx)
                _ = PromptTemplates.officePrompt(kind: .xlsx, filename: "sheet.xlsx", documentTextOrReference: "hello")
            }
        }
    }
}
