import SwiftUI

struct SearchPopoverView: View {
    @ObservedObject var viewModel: SearchResultViewModel
    let watchedFolderCount: Int
    let statusMessage: String?
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void

    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            searchField
            statusStrip
            Divider().opacity(0.4)
            resultsContent
            if let toast = viewModel.actionToast {
                ActionToast(message: toast) { viewModel.dismissActionToast() }
                    .accessibilityIdentifier("resultActionToast")
            }
        }
        .padding(18)
        .frame(width: 520)
        .frame(minHeight: 420, maxHeight: 680)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 0.5)
        )
        .onAppear { searchFocused = true }
        .onExitCommand { onDismiss() }
        .onMoveCommand { direction in
            switch direction {
            case .down:
                searchFocused = false
                viewModel.moveSelectionDown()
            case .up:
                searchFocused = false
                viewModel.moveSelectionUp()
            default: break
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text("LocalLens")
                    .font(.title3.weight(.semibold))
                Text("Search your private media library")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Settings") { onOpenSettings() }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("settingsButton")
                .keyboardShortcut(",", modifiers: .command)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search filenames, OCR, PDFs, labels, transcripts…", text: Binding(
                get: { viewModel.query },
                set: { viewModel.updateQuery($0) }
            ))
            .textFieldStyle(.plain)
            .focused($searchFocused)
            .accessibilityIdentifier("searchField")
            .onSubmit { Task { await viewModel.runSearchImmediately() } }

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.clear()
                    searchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(searchFocused ? Color.accentColor.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 0.5)
        )
    }

    private var statusStrip: some View {
        HStack(spacing: 8) {
            Label("\(watchedFolderCount) folder\(watchedFolderCount == 1 ? "" : "s") watched", systemImage: "folder")
                .accessibilityIdentifier("watchedFolderSummary")
            Label(viewModel.indexingStatusSummary, systemImage: "lock.shield")
                .lineLimit(1)
            Spacer(minLength: 0)
            if viewModel.isSearching {
                ProgressView()
                    .scaleEffect(0.65)
                    .accessibilityIdentifier("searchProgress")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 2)
        .accessibilityIdentifier("indexingStatusSummary")
    }

    @ViewBuilder
    private var resultsContent: some View {
        if let statusMessage, !statusMessage.isEmpty {
            Text(statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)
        }

        switch viewModel.emptyState {
        case .noQuery:
            emptyState(icon: "sparkle.magnifyingglass", title: "Type to search locally", message: "Search runs on this Mac. Query text is kept out of diagnostics.")
        case .searching:
            emptyState(icon: "magnifyingglass", title: "Searching…", message: "Showing lexical matches first, with semantic refinement when a local model is available.")
        case .noResults:
            emptyState(icon: "tray", title: "No results", message: "Try a filename, visible text, PDF phrase, object label, or transcript fragment.")
                .accessibilityIdentifier("searchEmptyState")
        case .error(let message):
            emptyState(icon: "exclamationmark.triangle", title: "Search unavailable", message: message)
        case .ready:
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.results.enumerated()), id: \.element.id) { index, result in
                        SearchResultRow(
                            result: result,
                            isSelected: index == viewModel.selectedIndex,
                            canPerform: { viewModel.canPerformAction($0) },
                            onSelect: { viewModel.selectResult(at: index) },
                            onAction: { viewModel.performSelectedAction($0) }
                        )
                        .accessibilityIdentifier("searchResultRow")
                    }
                }
                .padding(.vertical, 2)
            }
            .accessibilityIdentifier("searchResultsList")
        }
    }

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
        }
        .frame(maxWidth: .infinity, minHeight: 230)
    }
}

private struct SearchResultRow: View {
    let result: SearchResultDTO
    let isSelected: Bool
    let canPerform: (ResultActionKind) -> Bool
    let onSelect: () -> Void
    let onAction: (ResultActionKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.thinMaterial)
                    Image(systemName: iconName)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(result.filename)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        if result.isMissing {
                            Text("Missing")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(.orange.opacity(0.18), in: Capsule())
                        }
                    }

                    Text(matchReasonText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityIdentifier("matchReasons")

                    if let snippet = result.snippet, !snippet.isEmpty {
                        Text(snippet)
                            .font(.caption)
                            .foregroundStyle(.primary.opacity(0.8))
                            .lineLimit(2)
                            .accessibilityIdentifier("resultSnippet")
                    }

                    HStack(spacing: 8) {
                        if let pageNumber = result.pageNumber {
                            Label("Page \(pageNumber)", systemImage: "doc.text")
                                .accessibilityIdentifier("pageHint")
                        }
                        if let timestampStart = result.timestampStart {
                            Label("Jump \(Self.timestamp(timestampStart))", systemImage: "play.circle")
                                .accessibilityIdentifier("timestampHint")
                        }
                        if let duration = result.durationSeconds, result.mediaType == .audio || result.mediaType == .video {
                            Label(Self.duration(duration), systemImage: "clock")
                                .accessibilityIdentifier("durationHint")
                        }
                        Text(result.folderContext)
                            .lineLimit(1)
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
                ResultActionMenu(canPerform: canPerform, onAction: onAction)
            }

            if isSelected {
                ResultActionBar(canPerform: canPerform, onAction: onAction)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .accessibilityIdentifier("resultActionBar")
            }
        }
        .padding(10)
        .background(isSelected ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture(perform: onSelect)
    }

    private var iconName: String {
        switch result.mediaType {
        case .image: "photo"
        case .pdf: "doc.richtext"
        case .audio: "waveform"
        case .video: "film"
        case .office: "doc.text"
        }
    }

    private var matchReasonText: String {
        let labels = result.matchReasons.map { reason in
            switch reason {
            case .filename: "Filename"
            case .visibleText: "Visible text"
            case .pdfText: "PDF text"
            case .imageDescription: "Image description"
            case .pdfSummary: "PDF summary"
            case .transcript: "Transcript"
            case .visualLabel: "Visual label"
            case .officeText: "Office text"
            case .officeSummary: "Office summary"
            case .semantic: "Semantic match"
            }
        }
        return labels.isEmpty ? "Filename" : labels.joined(separator: " • ")
    }

    private static func timestamp(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private static func duration(_ seconds: Double) -> String {
        "Duration \(timestamp(seconds))"
    }
}

private struct ResultActionMenu: View {
    let canPerform: (ResultActionKind) -> Bool
    let onAction: (ResultActionKind) -> Void

    var body: some View {
        Menu {
            ForEach(ResultActionKind.allCases, id: \.self) { action in
                Button(action.label) { onAction(action) }
                    .disabled(!canPerform(action))
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .accessibilityLabel("Result Actions")
        .accessibilityIdentifier("resultActionMenu")
    }
}

private struct ResultActionBar: View {
    let canPerform: (ResultActionKind) -> Bool
    let onAction: (ResultActionKind) -> Void

    var body: some View {
        HStack(spacing: 6) {
            actionButton(.quickLook, shortcut: .space, modifiers: [])
            actionButton(.revealInFinder, shortcut: "r", modifiers: [.command, .shift])
            actionButton(.openDefault, shortcut: "o", modifiers: .command)
            actionButton(.copyPath, shortcut: "c", modifiers: [.command, .option])
            actionButton(.copySnippet, shortcut: "c", modifiers: [.command, .shift])
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .liquidGlassCapsule()
    }

    private func actionButton(_ action: ResultActionKind, shortcut: KeyEquivalent, modifiers: EventModifiers) -> some View {
        Button {
            onAction(action)
        } label: {
            Label(action.label, systemImage: action.systemImage)
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.borderless)
        .font(.caption)
        .disabled(!canPerform(action))
        .keyboardShortcut(shortcut, modifiers: modifiers)
        .accessibilityIdentifier("resultAction_\(action.rawValue)")
    }
}

private struct ActionToast: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(message)
                .font(.caption)
                .lineLimit(2)
            Spacer()
            Button("Dismiss") { onDismiss() }
                .buttonStyle(.borderless)
                .font(.caption)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private extension View {
    @ViewBuilder
    func liquidGlassCapsule() -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: .capsule)
        } else {
            self.background(.thinMaterial, in: Capsule())
        }
    }
}
