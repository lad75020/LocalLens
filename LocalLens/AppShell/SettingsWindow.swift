import SwiftUI

struct SettingsWindow: View {
    static let requiredControlAccessibilityIdentifiers = [
        "settingsFoldersRefreshButton",
        "settingsAddFolderButton",
        "settingsIndexingRefreshButton",
        "settingsPauseIndexingButton",
        "settingsResumeIndexingButton",
        "settingsCancelIndexingButton",
        "settingsProvidersRefreshButton",
        "settingsStorageRefreshButton",
        "settingsDeleteIndexButton",
        "settingsRebuildIndexButton",
        "settingsDiagnosticsRefreshButton",
        "settingsExportDiagnosticsButton"
    ]

    @EnvironmentObject private var dependencies: DependencyContainer
    @StateObject private var model = SettingsWindowModel()

    var body: some View {
        TabView {
            foldersTab
                .tabItem { Label("Folders", systemImage: "folder") }
                .accessibilityIdentifier("settingsFoldersTab")

            indexingTab
                .tabItem { Label("Indexing", systemImage: "gauge.with.dots.needle.33percent") }
                .accessibilityIdentifier("settingsIndexingTab")

            providersTab
                .tabItem { Label("AI Providers", systemImage: "cpu") }
                .accessibilityIdentifier("settingsProvidersTab")

            privacyStorageTab
                .tabItem { Label("Privacy & Storage", systemImage: "lock.shield") }
                .accessibilityIdentifier("settingsPrivacyStorageTab")

            diagnosticsTab
                .tabItem { Label("Diagnostics", systemImage: "stethoscope") }
                .accessibilityIdentifier("settingsDiagnosticsTab")
        }
        .padding(20)
        .frame(minWidth: 720, minHeight: 520)
        .task { model.configure(dependencies: dependencies) }
    }

    private var foldersTab: some View {
        SettingsPane(title: "Watched Folders", subtitle: "Manage the folders LocalLens is allowed to read for private indexing.", statusMessage: model.statusMessage) {
            HStack {
                Button("Refresh") { model.refresh() }
                    .accessibilityIdentifier("settingsFoldersRefreshButton")
                Button("Add Folder…") { model.noteUnavailable("Folder authorization is not wired yet. Use the upcoming folder onboarding flow to add folders.") }
                    .accessibilityIdentifier("settingsAddFolderButton")
                Spacer()
            }

            if model.folders.isEmpty {
                EmptySettingsState(
                    title: "No watched folders yet",
                    message: "Add a folder to start building a private, searchable media index. Source files are never modified."
                )
                .accessibilityIdentifier("settingsFoldersEmptyState")
            } else {
                VStack(spacing: 10) {
                    ForEach(model.folders) { folder in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(folder.displayName).font(.headline)
                                Text(folder.displayPath).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                Text("Authorization: \(folder.authorizationState.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("Enabled", isOn: Binding(
                                get: { folder.isEnabled },
                                set: { model.setFolder(folder, enabled: $0) }
                            ))
                            .toggleStyle(.switch)
                            Button("Reauthorize") { model.noteUnavailable("Reauthorization will be enabled with the folder authorization service.") }
                            Button("Remove", role: .destructive) { model.removeFolder(folder) }
                        }
                        .padding(10)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .accessibilityIdentifier("settingsFoldersList")
            }
        }
    }

    private var indexingTab: some View {
        SettingsPane(title: "Indexing State", subtitle: "Monitor queue state and control local indexing without exposing file contents.", statusMessage: model.statusMessage) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                MetricCard(title: "Queued", value: "\(model.progress.queuedCount)")
                MetricCard(title: "Running", value: "\(model.progress.runningCount)")
                MetricCard(title: "Completed", value: "\(model.progress.completedCount)")
                MetricCard(title: "Failed", value: "\(model.progress.failedCount)")
                MetricCard(title: "Cancelled", value: "\(model.progress.cancelledCount)")
            }
            .accessibilityIdentifier("settingsIndexingMetrics")

            HStack {
                StatusPill(text: model.progress.isPaused ? "Paused" : (model.progress.isRunning ? "Running" : "Idle"))
                if let lastIndexed = model.progress.lastIndexedAt {
                    Text("Last indexed: \(lastIndexed.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack {
                Button("Refresh") { model.refresh() }
                    .accessibilityIdentifier("settingsIndexingRefreshButton")
                Button("Pause") { model.pauseIndexing() }
                    .accessibilityIdentifier("settingsPauseIndexingButton")
                Button("Resume") { model.resumeIndexing() }
                    .accessibilityIdentifier("settingsResumeIndexingButton")
                Button("Cancel Active Work", role: .destructive) { model.cancelActiveIndexing() }
                    .accessibilityIdentifier("settingsCancelIndexingButton")
                Spacer()
            }
        }
    }

    private var providersTab: some View {
        SettingsPane(title: "AI Providers", subtitle: "Local providers are enabled by default. Remote providers require explicit opt-in before transmitting data.", statusMessage: model.statusMessage) {
            HStack {
                Button("Refresh") { model.refresh() }
                    .accessibilityIdentifier("settingsProvidersRefreshButton")
                Spacer()
            }

            VStack(spacing: 10) {
                ForEach(model.providers) { provider in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(provider.displayName).font(.headline)
                                Text(provider.baseURL.absoluteString).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("Enabled", isOn: Binding(
                                get: { provider.isEnabled },
                                set: { model.setProvider(provider, enabled: $0) }
                            ))
                            .toggleStyle(.switch)
                        }
                        HStack {
                            StatusPill(text: provider.locality.rawValue)
                            StatusPill(text: provider.transportState.rawValue)
                            Toggle("Automatic indexing", isOn: Binding(
                                get: { provider.automaticIndexingEnabled },
                                set: { model.setProvider(provider, automaticIndexing: $0) }
                            ))
                            .disabled(provider.locality == .remote)
                            Spacer()
                        }
                    }
                    .padding(10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .accessibilityIdentifier("settingsProvidersList")
        }
    }

    private var privacyStorageTab: some View {
        SettingsPane(title: "Privacy & Storage", subtitle: "Review where local index data is retained and remove derived index data without touching source media.", statusMessage: model.statusMessage) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Default processing is local-first. Remote providers cannot transmit file bytes, extracted text, transcripts, filenames, prompts, embeddings, or metadata without explicit opt-in.", systemImage: "hand.raised")
                Text("Index database: \(dependencies.database.databaseURL.path)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Text("Cache root: \(dependencies.database.cacheRootURL.path)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Text("Indexed assets: \(model.indexedAssetCount)")
                    .font(.headline)
            }
            .accessibilityIdentifier("settingsPrivacyStorageSummary")

            HStack {
                Button("Refresh") { model.refresh() }
                    .accessibilityIdentifier("settingsStorageRefreshButton")
                Button("Delete Local Index", role: .destructive) { model.deleteLocalIndex() }
                    .accessibilityIdentifier("settingsDeleteIndexButton")
                Button("Rebuild Index") { model.noteUnavailable("Rebuild index will be enabled when folder discovery and indexing orchestration are wired.") }
                    .accessibilityIdentifier("settingsRebuildIndexButton")
                Spacer()
            }
        }
    }

    private var diagnosticsTab: some View {
        SettingsPane(title: "Diagnostics", subtitle: "Failures and diagnostics are summarized without exposing raw file contents, transcripts, credentials, or full paths by default.", statusMessage: model.statusMessage) {
            HStack {
                Button("Refresh") { model.refresh() }
                    .accessibilityIdentifier("settingsDiagnosticsRefreshButton")
                Button("Export Redacted Diagnostics") { model.exportDiagnosticsSummary() }
                    .accessibilityIdentifier("settingsExportDiagnosticsButton")
                Spacer()
            }

            Text(model.diagnosticSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .accessibilityIdentifier("settingsDiagnosticsRedactionSummary")

            if model.failures.isEmpty {
                EmptySettingsState(title: "No unresolved failures", message: "Failures will appear here with safe categories, retryability, and recovery actions.")
                    .accessibilityIdentifier("settingsDiagnosticsEmptyState")
            } else {
                VStack(spacing: 10) {
                    ForEach(model.failures) { failure in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(failure.category.rawValue).font(.headline)
                                Text(failure.safeMessage).foregroundStyle(.secondary)
                                Text("Retryability: \(failure.retryability.rawValue)").font(.caption)
                            }
                            Spacer()
                            Button("Mark Resolved") { model.resolveFailure(failure) }
                        }
                        .padding(10)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .accessibilityIdentifier("settingsFailuresList")
            }
        }
    }
}

@MainActor
private final class SettingsWindowModel: ObservableObject {
    @Published var folders: [WatchedFolder] = []
    @Published var providers: [ProviderSetting] = []
    @Published var failures: [IndexFailure] = []
    @Published var progress = IndexProgressSnapshot()
    @Published var indexedAssetCount = 0
    @Published var diagnosticSummary = "Diagnostics redact full paths, transcripts, extracted text, credentials, thumbnails, and raw provider bodies."
    @Published var statusMessage: String?

    private weak var dependencies: DependencyContainer?

    func configure(dependencies: DependencyContainer) {
        guard self.dependencies !== dependencies else { return }
        self.dependencies = dependencies
        refresh()
    }

    func refresh() {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            guard let self else { return }
            do {
                try await dependencies.database.migrate()
                self.folders = try await dependencies.storage.watchedFolders.list()
                self.providers = try await self.loadProviders(from: dependencies)
                self.failures = try await dependencies.storage.failures.unresolved()
                self.progress = await dependencies.indexQueue.snapshot()
                self.indexedAssetCount = try await dependencies.storage.maintenance.indexedAssetCount()
                self.diagnosticSummary = dependencies.diagnosticExporter.exportSummary()
                    .map { "\($0.key): \($0.value)" }
                    .sorted()
                    .joined(separator: "\n")
                self.statusMessage = nil
            } catch {
                self.statusMessage = "Unable to refresh Settings: \(error.localizedDescription)"
            }
        }
    }

    func setFolder(_ folder: WatchedFolder, enabled: Bool) {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            guard let self else { return }
            do {
                var updated = folder
                updated.isEnabled = enabled
                updated.updatedAt = Date()
                try await dependencies.storage.watchedFolders.save(updated)
                self.refresh()
            } catch {
                self.statusMessage = "Unable to update folder: \(error.localizedDescription)"
            }
        }
    }

    func removeFolder(_ folder: WatchedFolder) {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            guard let self else { return }
            do {
                try await dependencies.storage.watchedFolders.remove(id: folder.id)
                self.refresh()
            } catch {
                self.statusMessage = "Unable to remove folder: \(error.localizedDescription)"
            }
        }
    }

    func setProvider(_ provider: ProviderSetting, enabled: Bool) {
        var updated = provider
        updated.isEnabled = enabled
        saveProvider(updated)
    }

    func setProvider(_ provider: ProviderSetting, automaticIndexing: Bool) {
        var updated = provider
        updated.automaticIndexingEnabled = automaticIndexing
        if updated.locality == .remote, automaticIndexing {
            updated.automaticIndexingEnabled = false
            statusMessage = "Remote providers cannot be enabled for automatic indexing without explicit opt-in."
        }
        saveProvider(updated)
    }

    func pauseIndexing() {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            guard let self else { return }
            await dependencies.indexQueue.pause()
            self.refresh()
        }
    }

    func resumeIndexing() {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            guard let self else { return }
            await dependencies.indexQueue.resume()
            self.refresh()
        }
    }

    func cancelActiveIndexing() {
        dependencies?.indexCancellation.cancel()
        statusMessage = "Active indexing cancellation requested."
        refresh()
    }

    func deleteLocalIndex() {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            guard let self else { return }
            do {
                try await dependencies.storage.maintenance.deleteIndexData()
                self.statusMessage = "Local index data deleted. Source media files were not modified."
                self.refresh()
            } catch {
                self.statusMessage = "Unable to delete local index: \(error.localizedDescription)"
            }
        }
    }

    func exportDiagnosticsSummary() {
        guard let dependencies else { return }
        diagnosticSummary = dependencies.diagnosticExporter.exportSummary()
            .map { "\($0.key): \($0.value)" }
            .sorted()
            .joined(separator: "\n")
        statusMessage = "Redacted diagnostic summary prepared."
    }

    func resolveFailure(_ failure: IndexFailure) {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            guard let self else { return }
            do {
                try await dependencies.storage.failures.resolve(id: failure.id, at: Date())
                self.refresh()
            } catch {
                self.statusMessage = "Unable to resolve failure: \(error.localizedDescription)"
            }
        }
    }

    func noteUnavailable(_ message: String) {
        statusMessage = message
    }

    private func saveProvider(_ provider: ProviderSetting) {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            guard let self else { return }
            do {
                try await dependencies.storage.providers.save(provider)
                self.refresh()
            } catch {
                self.statusMessage = "Unable to update provider: \(error.localizedDescription)"
            }
        }
    }

    private func loadProviders(from dependencies: DependencyContainer) async throws -> [ProviderSetting] {
        let persistedProviders = try await dependencies.storage.providers.list()
        if !persistedProviders.isEmpty { return persistedProviders }

        let defaults = dependencies.providerRegistry.defaultProviders()
        for provider in defaults {
            try await dependencies.storage.providers.save(provider)
        }
        return defaults
    }
}

private struct SettingsPane<Content: View>: View {
    let title: String
    let subtitle: String
    let statusMessage: String?
    let content: Content

    init(
        title: String,
        subtitle: String,
        statusMessage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.statusMessage = statusMessage
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.title2.bold())
                    Text(subtitle).foregroundStyle(.secondary)
                }
                content
                if let message = statusMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .accessibilityIdentifier("settingsStatusMessage")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title3.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct StatusPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
    }
}

private struct EmptySettingsState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(message).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
