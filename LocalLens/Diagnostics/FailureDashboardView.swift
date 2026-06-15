import SwiftUI

public struct FailureDashboardItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let category: FailureCategory
    public let retryability: Retryability
    public let safeMessage: String
    public let action: FailureRecoveryAction

    public init(failure: IndexFailure) {
        self.id = failure.id
        self.category = failure.category
        self.retryability = failure.retryability
        self.safeMessage = String(failure.safeMessage.prefix(180))
        self.action = FailureRecoveryAction(retryability: failure.retryability)
    }
}

public enum FailureRecoveryAction: String, CaseIterable, Equatable, Sendable {
    case retry
    case ignore
    case reauthorize
    case rebuildIndex
    case none

    public init(retryability: Retryability) {
        switch retryability {
        case .retry: self = .retry
        case .ignore: self = .ignore
        case .reauthorize: self = .reauthorize
        case .rebuildIndex: self = .rebuildIndex
        case .notRetryable: self = .none
        }
    }

    public var label: String {
        switch self {
        case .retry: "Retry"
        case .ignore: "Ignore"
        case .reauthorize: "Reauthorize"
        case .rebuildIndex: "Rebuild Index"
        case .none: "No Action"
        }
    }
}

@MainActor
public final class FailureDashboardModel: ObservableObject {
    @Published public private(set) var items: [FailureDashboardItem] = []
    @Published public private(set) var unresolvedCount = 0
    @Published public private(set) var lastMessage: String?

    private var failures: [IndexFailure] = []

    public init() {}

    public func load(_ failures: [IndexFailure]) {
        self.failures = failures.filter { $0.resolvedAt == nil }
        self.items = self.failures.map(FailureDashboardItem.init)
        self.unresolvedCount = items.count
    }

    public func refresh(storage: StorageRepositories) async {
        do {
            load(try await storage.failures.unresolved())
            lastMessage = nil
        } catch {
            lastMessage = "Failures are unavailable."
        }
    }

    public func perform(_ action: FailureRecoveryAction, for item: FailureDashboardItem, coordinator: IndexCoordinator, storage: StorageRepositories, queue: IndexQueueActor) async {
        guard let failure = failures.first(where: { $0.id == item.id }) else { return }
        do {
            switch action {
            case .retry:
                try await coordinator.retryFailure(failure, storage: storage, queue: queue)
                lastMessage = "Retry queued."
            case .ignore:
                try await coordinator.ignoreFailure(failure, storage: storage)
                lastMessage = "Failure ignored."
            case .reauthorize:
                lastMessage = "Open Folders to reauthorize access."
            case .rebuildIndex:
                try await coordinator.rebuildQueue(storage: storage, queue: queue)
                lastMessage = "Rebuild queued."
            case .none:
                lastMessage = "No recovery action is available."
            }
            await refresh(storage: storage)
        } catch {
            lastMessage = "Recovery action failed safely."
        }
    }
}

struct FailureDashboardView: View {
    let failures: [IndexFailure]
    let onAction: (IndexFailure, FailureRecoveryAction) -> Void

    init(failures: [IndexFailure] = [], onAction: @escaping (IndexFailure, FailureRecoveryAction) -> Void = { _, _ in }) {
        self.failures = failures
        self.onAction = onAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if failures.isEmpty {
                Label("No unresolved failures", systemImage: "checkmark.seal")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("failureDashboardEmptyState")
            } else {
                ForEach(failures) { failure in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(failure.category.rawValue).font(.headline)
                            Text(String(failure.safeMessage.prefix(180))).foregroundStyle(.secondary)
                            Text("Retryability: \(failure.retryability.rawValue)").font(.caption).foregroundStyle(.tertiary)
                        }
                        Spacer()
                        let action = FailureRecoveryAction(retryability: failure.retryability)
                        if action != .none {
                            Button(action.label) { onAction(failure, action) }
                                .accessibilityIdentifier("failureRecovery_\(action.rawValue)")
                        }
                    }
                    .padding(10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .accessibilityIdentifier("failureDashboard")
    }
}
