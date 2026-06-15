import SwiftUI

struct MenuBarRootView: View {
    @EnvironmentObject private var dependencies: DependencyContainer
    @StateObject private var folderModel = WatchedFolderViewModel()
    @State private var query = ""

    var body: some View {
        Group {
            if folderModel.folders.isEmpty {
                OnboardingView(
                    statusMessage: folderModel.statusMessage,
                    onAddFolder: { addFolder() },
                    onOpenSettings: { dependencies.settingsWindowPresenter.show(dependencies: dependencies) }
                )
            } else {
                searchPopover
            }
        }
        .task { folderModel.configure(dependencies: dependencies) }
    }

    private var searchPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LocalLens").font(.headline)
            TextField("Search private media", text: $query)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("searchField")
            Text("Local indexing stays on this Mac by default.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Text("\(folderModel.folders.count) folder\(folderModel.folders.count == 1 ? "" : "s") watched")
                    .font(.caption)
                    .padding(6)
                    .background(.thinMaterial, in: Capsule())
                Spacer()
                Button("Settings") {
                    dependencies.settingsWindowPresenter.show(dependencies: dependencies)
                }
                .accessibilityIdentifier("settingsButton")
            }
        }
        .padding()
        .frame(width: 420)
    }

    private func addFolder() {
        Task { @MainActor in
            do {
                _ = try await folderModel.addFolderFromPanel()
            } catch {
                folderModel.statusMessage = "Unable to add folder: \(error.localizedDescription)"
            }
        }
    }
}
