import SwiftUI

struct SettingsWindow: View {
    var body: some View { TabView { Text("Watched folders, authorization, and reindex controls").tabItem { Text("Folders") }; Text("Local providers are default. Remote providers require opt-in.").tabItem { Text("AI Providers") }; Text("Delete or rebuild local index data without touching source files.").tabItem { Text("Privacy & Storage") }; Text("Failures and redacted diagnostics").tabItem { Text("Diagnostics") } }.padding().frame(width: 640, height: 420) }
}
