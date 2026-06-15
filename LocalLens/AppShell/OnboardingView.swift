import SwiftUI

struct OnboardingView: View {
    var statusMessage: String? = nil
    var onAddFolder: () -> Void = {}
    var onOpenSettings: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Build a private media library")
                .font(.title2.bold())
            Text("Choose folders explicitly. LocalLens reads source media without changing it and stores derived index data under Application Support on this Mac.")
                .foregroundStyle(.secondary)
            Label("Your source files are read-only for the MVP: no rename, move, delete, transcode, or metadata edits.", systemImage: "lock.shield")
                .font(.callout)
            Label("Local AI is the default. Remote providers stay disabled until you opt in from Settings.", systemImage: "cpu")
                .font(.callout)

            HStack {
                Button("Add Folder…", action: onAddFolder)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("onboardingAddFolderButton")
                Button("Settings", action: onOpenSettings)
                    .accessibilityIdentifier("onboardingSettingsButton")
                Spacer()
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("onboardingStatusMessage")
            }
        }
        .padding()
        .frame(width: 460, alignment: .leading)
        .accessibilityIdentifier("onboardingView")
    }
}
