import AppKit
import Foundation

public struct FinderRevealService: Sendable { public init() {}; @MainActor public func reveal(_ url: URL) { NSWorkspace.shared.activateFileViewerSelecting([url]) } }
