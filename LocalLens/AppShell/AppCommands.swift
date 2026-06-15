import SwiftUI

struct AppCommands: Commands {
    @ObservedObject var viewModel: SearchResultViewModel

    var body: some Commands {
        CommandMenu("LocalLens") {
            Button("Focus Search") {
                NSApp.sendAction(#selector(NSTextField.selectText(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("f", modifiers: .command)

            Divider()

            Button("Preview Result") { viewModel.performSelectedAction(.quickLook) }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(!viewModel.canPerformAction(.quickLook))
                .accessibilityIdentifier("commandPreviewResult")

            Button("Reveal in Finder") { viewModel.performSelectedAction(.revealInFinder) }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(!viewModel.canPerformAction(.revealInFinder))
                .accessibilityIdentifier("commandRevealInFinder")

            Button("Open in Default App") { viewModel.performSelectedAction(.openDefault) }
                .keyboardShortcut("o", modifiers: .command)
                .disabled(!viewModel.canPerformAction(.openDefault))
                .accessibilityIdentifier("commandOpenDefault")

            Divider()

            Button("Copy Source Path") { viewModel.performSelectedAction(.copyPath) }
                .keyboardShortcut("c", modifiers: [.command, .option])
                .disabled(!viewModel.canPerformAction(.copyPath))
                .accessibilityIdentifier("commandCopySourcePath")

            Button("Copy Snippet") { viewModel.performSelectedAction(.copySnippet) }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(!viewModel.canPerformAction(.copySnippet))
                .accessibilityIdentifier("commandCopySnippet")
        }
    }
}
