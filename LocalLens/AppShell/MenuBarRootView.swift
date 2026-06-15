import SwiftUI

struct MenuBarRootView: View {
    @EnvironmentObject private var dependencies: DependencyContainer
    @Environment(\.dismiss) private var dismiss
    @StateObject private var folderModel = WatchedFolderViewModel()

    var body: some View {
        Group {
            if folderModel.folders.isEmpty {
                OnboardingView(
                    statusMessage: folderModel.statusMessage,
                    onAddFolder: { addFolder() },
                    onOpenSettings: { dependencies.settingsWindowPresenter.show(dependencies: dependencies) }
                )
            } else {
                SearchPopoverView(
                    viewModel: dependencies.searchResultViewModel,
                    watchedFolderCount: folderModel.folders.count,
                    statusMessage: folderModel.statusMessage,
                    onOpenSettings: { dependencies.settingsWindowPresenter.show(dependencies: dependencies) },
                    onDismiss: { dismiss() }
                )
            }
        }
        .task {
            folderModel.configure(dependencies: dependencies)
            dependencies.searchResultViewModel.configure(dependencies: dependencies)
        }
        .keyboardShortcut("f", modifiers: .command)
    }

    private func addFolder() {
        Task { @MainActor in
            do {
                _ = try await folderModel.addFolderFromPanel()
                dependencies.searchResultViewModel.refreshIndexingStatus()
            } catch {
                folderModel.statusMessage = "Unable to add folder: \(error.localizedDescription)"
            }
        }
    }
}
