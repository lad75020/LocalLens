import SwiftUI

struct AppCommands: Commands { var body: some Commands { CommandMenu("LocalLens") { Button("Focus Search") {}; Button("Reveal in Finder") {}; Button("Copy Snippet") {} } } }
