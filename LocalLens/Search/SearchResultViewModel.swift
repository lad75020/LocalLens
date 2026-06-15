import Foundation

@MainActor
public final class SearchResultViewModel: ObservableObject {
    public enum EmptyState: Equatable, Sendable {
        case ready
        case noQuery
        case noResults
        case searching
        case error(String)
    }

    @Published public var query = ""
    @Published public private(set) var results: [SearchResultDTO] = []
    @Published public private(set) var selectedIndex: Int? = nil
    @Published public private(set) var emptyState: EmptyState = .noQuery
    @Published public private(set) var isSearching = false
    @Published public private(set) var indexingStatusSummary = "Indexing stays local on this Mac."

    private weak var dependencies: DependencyContainer?
    private var searchTask: Task<Void, Never>?
    private let debounceNanoseconds: UInt64

    public init(debounceNanoseconds: UInt64 = 250_000_000) {
        self.debounceNanoseconds = debounceNanoseconds
    }

    deinit { searchTask?.cancel() }

    public func configure(dependencies: DependencyContainer) {
        guard self.dependencies !== dependencies else { return }
        self.dependencies = dependencies
        refreshIndexingStatus()
    }

    public func updateQuery(_ value: String) {
        query = value
        scheduleSearch()
    }

    public func clear() {
        searchTask?.cancel()
        query = ""
        results = []
        selectedIndex = nil
        emptyState = .noQuery
        isSearching = false
    }

    public func scheduleSearch() {
        searchTask?.cancel()
        let request = SearchRequest(query: query)
        guard !request.isEmpty else {
            results = []
            selectedIndex = nil
            emptyState = .noQuery
            isSearching = false
            return
        }

        emptyState = .searching
        isSearching = true
        searchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: debounceNanoseconds)
                await self.runSearch(request)
            } catch is CancellationError {
                self.isSearching = false
            } catch {
                self.results = []
                self.selectedIndex = nil
                self.emptyState = .error("Search was interrupted.")
                self.isSearching = false
            }
        }
    }

    public func runSearchImmediately() async {
        searchTask?.cancel()
        await runSearch(SearchRequest(query: query))
    }

    public func moveSelectionDown() {
        guard !results.isEmpty else { selectedIndex = nil; return }
        selectedIndex = min((selectedIndex ?? -1) + 1, results.count - 1)
    }

    public func moveSelectionUp() {
        guard !results.isEmpty else { selectedIndex = nil; return }
        selectedIndex = max((selectedIndex ?? results.count) - 1, 0)
    }

    public var selectedResult: SearchResultDTO? {
        guard let selectedIndex, results.indices.contains(selectedIndex) else { return nil }
        return results[selectedIndex]
    }

    public func refreshIndexingStatus() {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            do {
                let assetCount = try await dependencies.storage.maintenance.indexedAssetCount()
                self?.indexingStatusSummary = assetCount == 0
                    ? "No indexed assets yet. Add a folder to begin."
                    : "\(assetCount) asset\(assetCount == 1 ? "" : "s") indexed locally."
            } catch {
                self?.indexingStatusSummary = "Index status unavailable."
            }
        }
    }

    private func runSearch(_ request: SearchRequest) async {
        guard !request.isEmpty else {
            results = []
            selectedIndex = nil
            emptyState = .noQuery
            isSearching = false
            return
        }
        guard let dependencies else {
            results = []
            selectedIndex = nil
            emptyState = .error("Search is not ready yet.")
            isSearching = false
            return
        }

        isSearching = true
        emptyState = .searching
        let found = await dependencies.searchService.search(request, storage: dependencies.storage)
        results = found
        selectedIndex = found.isEmpty ? nil : 0
        emptyState = found.isEmpty ? .noResults : .ready
        isSearching = false
        refreshIndexingStatus()
    }
}
