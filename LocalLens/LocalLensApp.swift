import SwiftUI

@main
struct LocalLensApp: App {
    @StateObject private var dependencies: DependencyContainer
    init() { _dependencies = StateObject(wrappedValue: (try? DependencyContainer()) ?? fallbackContainer()) }
    var body: some Scene {
        MenuBarExtra("LocalLens", systemImage: "magnifyingglass.circle") { MenuBarRootView().environmentObject(dependencies) }.menuBarExtraStyle(.window)
        Settings { SettingsWindow().environmentObject(dependencies) }
    }
}

@MainActor private func fallbackContainer() -> DependencyContainer {
    do { return try DependencyContainer() } catch { fatalError("Unable to initialize LocalLens dependencies: \(error)") }
}
