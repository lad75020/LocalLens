import SwiftUI

struct MenuBarRootView: View {
    @EnvironmentObject private var dependencies: DependencyContainer
    @State private var query = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LocalLens").font(.headline)
            TextField("Search private media", text: $query)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("searchField")
            Text("Local indexing stays on this Mac by default.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Text("Index idle")
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
}
