import Foundation

@MainActor public final class WatchedFolderViewModel: ObservableObject { @Published public var folders: [WatchedFolder] = []; public init() {} }
