import AppKit
import Foundation

public struct ClipboardActionService: Sendable { public init() {}; @MainActor public func copy(_ text: String) { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string) } }
