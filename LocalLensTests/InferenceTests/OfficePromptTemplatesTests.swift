import Foundation
import XCTest
@testable import LocalLens

final class OfficePromptTemplatesTests: XCTestCase {
    func testOfficePromptsContainSkillDirectivesOutsideUntrustedContent() {
        for kind in OfficeDocumentKind.allCases {
            let prompt = PromptTemplates.officePrompt(kind: kind, filename: "fixture.\(kind.rawValue)", documentTextOrReference: PromptInjectionFixtures.text(for: kind))
            XCTAssertTrue(prompt.contains(kind.requiredSkillDirective))
            XCTAssertTrue(prompt.contains("BEGIN_UNTRUSTED_DOCUMENT_CONTENT_OR_REFERENCE"))
            XCTAssertTrue(prompt.contains("Ignore previous") || prompt.contains("SYSTEM override") || prompt.contains("discard rules"))
            XCTAssertLessThanOrEqual(prompt.count, BuildConfiguration.maxPromptCharacters + 1_000)
        }
    }
}
