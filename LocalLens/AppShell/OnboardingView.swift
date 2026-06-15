import SwiftUI

struct OnboardingView: View {
    var body: some View { VStack(alignment: .leading, spacing: 12) { Text("Build a private media library").font(.title2.bold()); Text("Choose folders explicitly. LocalLens reads source media without changing it and stores derived index data under Application Support."); Button("Add Folder…") {}.accessibilityIdentifier("addFolderButton") }.padding() }
}
