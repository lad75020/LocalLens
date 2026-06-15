import Foundation

@MainActor public final class SearchResultViewModel: ObservableObject { @Published public var query = ""; @Published public var results: [SearchResultDTO] = []; public init() {} }
