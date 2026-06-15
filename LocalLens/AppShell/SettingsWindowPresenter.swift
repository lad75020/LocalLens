import AppKit
import SwiftUI

@MainActor
public final class SettingsWindowPresenter: NSObject, ObservableObject, NSWindowDelegate {
    private var window: NSWindow?

    var windowForTesting: NSWindow? { window }

    public func show(dependencies: DependencyContainer) {
        let settingsWindow: NSWindow
        if let existingWindow = window {
            settingsWindow = existingWindow
        } else {
            let hostingController = NSHostingController(rootView: SettingsWindow().environmentObject(dependencies))
            let newWindow = NSWindow(contentViewController: hostingController)
            newWindow.title = "LocalLens Settings"
            newWindow.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            newWindow.isReleasedWhenClosed = false
            newWindow.delegate = self
            newWindow.setContentSize(NSSize(width: 640, height: 420))
            newWindow.center()
            window = newWindow
            settingsWindow = newWindow
        }

        NSApp.activate(ignoringOtherApps: true)
        settingsWindow.makeKeyAndOrderFront(nil)
    }

    public func close() {
        window?.close()
    }

    public func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow, closingWindow === window else { return }
        closingWindow.delegate = nil
        window = nil
    }
}
