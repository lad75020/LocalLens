import Foundation

public struct SnippetBuilder: Sendable {
    public init() {}

    public func snippet(text: String, around query: String, limit: Int = 180) -> String {
        let boundedLimit = max(40, min(limit, 400))
        let collapsed = Self.collapseWhitespace(text)
        guard !collapsed.isEmpty else { return "" }
        guard collapsed.count > boundedLimit else { return collapsed }

        let terms = Self.queryTerms(query)
        let lower = collapsed.lowercased()
        let matchRange = terms.compactMap { lower.range(of: $0) }.min { lhs, rhs in
            lhs.lowerBound < rhs.lowerBound
        }

        guard let matchRange else {
            return String(collapsed.prefix(boundedLimit)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
        }

        let matchOffset = collapsed.distance(from: collapsed.startIndex, to: matchRange.lowerBound)
        let prefixBudget = boundedLimit / 3
        let startOffset = max(0, matchOffset - prefixBudget)
        let start = collapsed.index(collapsed.startIndex, offsetBy: startOffset)
        let end = collapsed.index(start, offsetBy: min(boundedLimit, collapsed.distance(from: start, to: collapsed.endIndex)))
        var snippet = String(collapsed[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
        if startOffset > 0 { snippet = "…" + snippet }
        if end < collapsed.endIndex { snippet += "…" }
        return snippet
    }

    public static func collapseWhitespace(_ text: String) -> String {
        text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    public static func queryTerms(_ query: String) -> [String] {
        let normalized = query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let terms = normalized
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { !$0.isEmpty }
        return terms.isEmpty ? [normalized.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()].filter { !$0.isEmpty } : terms
    }
}
