import SwiftUI

@main
struct LocalLensApp: App {
    @StateObject private var dependencies: DependencyContainer

    init() {
        if CommandLine.arguments.contains("--ui-testing-fresh-state") {
            Self.resetUITestingState()
        }
        let container = (try? DependencyContainer()) ?? fallbackContainer()
        _dependencies = StateObject(wrappedValue: container)
        UITestingWindowPresenter.showIfRequested(dependencies: container)
    }

    var body: some Scene {
        MenuBarExtra("LocalLens", systemImage: "magnifyingglass.circle") {
            MenuBarRootView()
                .environmentObject(dependencies)
        }
        .menuBarExtraStyle(.window)
        .commands {
            AppCommands(viewModel: dependencies.searchResultViewModel)
        }
    }

    private static func resetUITestingState() {
        if let support = try? LocalLensDatabase.defaultApplicationSupportURL() {
            try? FileManager.default.removeItem(at: support)
        }
    }
}

@MainActor private func fallbackContainer() -> DependencyContainer {
    do { return try DependencyContainer() } catch { fatalError("Unable to initialize LocalLens dependencies: \(error)") }
}
