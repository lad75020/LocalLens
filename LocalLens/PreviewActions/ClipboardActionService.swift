import AppKit
import Foundation

public struct ClipboardActionService: Sendable {
    public typealias ClipboardWriter = @MainActor @Sendable (String) -> Bool

    public static let maxSnippetCharacters = 500

    private let resolver: ResultFileResolver
    private let redactionPolicy: RedactionPolicy
    private let writer: ClipboardWriter

    public init(
        resolver: ResultFileResolver = ResultFileResolver(),
        redactionPolicy: RedactionPolicy = RedactionPolicy(),
        writer: @escaping ClipboardWriter = { text in
            NSPasteboard.general.clearContents()
            return NSPasteboard.general.setString(text, forType: .string)
        }
    ) {
        self.resolver = resolver
        self.redactionPolicy = redactionPolicy
        self.writer = writer
    }

    @MainActor
    public func copy(_ text: String) {
        _ = writer(text)
    }

    @MainActor
    public func copyPath(asset: MediaAsset, folder: WatchedFolder) throws -> String {
        let resolved = try resolver.resolve(asset: asset, folder: folder)
        let path = resolved.fileURL.path
        guard writer(path) else { throw ResultActionError.clipboardUnavailable }
        return path
    }

    @MainActor
    public func copySnippet(_ result: SearchResultDTO) throws -> String {
        let snippet = boundedSnippet(result.snippet ?? result.filename)
        guard !snippet.isEmpty, writer(snippet) else { throw ResultActionError.clipboardUnavailable }
        return snippet
    }

    public func boundedSnippet(_ snippet: String) -> String {
        let collapsed = SnippetBuilder.collapseWhitespace(snippet)
        let redacted = redactionPolicy.safeMessage(collapsed, maxCharacters: Self.maxSnippetCharacters)
        return String(redacted.prefix(Self.maxSnippetCharacters)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
