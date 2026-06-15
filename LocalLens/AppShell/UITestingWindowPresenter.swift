import AppKit
import SwiftUI

@MainActor
enum UITestingWindowPresenter {
    private static var window: NSWindow?

    static func showIfRequested(dependencies: DependencyContainer) {
        guard CommandLine.arguments.contains("--ui-testing-window") else { return }
        Task { @MainActor in
            open(dependencies: dependencies)
        }
    }

    private static func open(dependencies: DependencyContainer) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let rootView = MenuBarRootView()
            .environmentObject(dependencies)
        let hostingController = NSHostingController(rootView: rootView)
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "LocalLens UI Testing"
        newWindow.setContentSize(NSSize(width: 520, height: 520))
        newWindow.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        newWindow.isReleasedWhenClosed = false
        newWindow.center()
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = newWindow
    }
}
