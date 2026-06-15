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
        "settingsOfficePPTXToggle",
        "settingsOfficeDOCXToggle",
        "settingsOfficeXLSXToggle",
        "settingsHermesProfilePicker",
        "settingsProviderModelPicker_ollama",
        "settingsProviderModelPicker_omlx",
        "settingsStorageRefreshButton",
        "settingsDeleteIndexButton",
        "settingsRebuildIndexButton",
        "settingsDiagnosticsRefreshButton",
        "settingsExportDiagnosticsButton",
        "settingsRetryFailureButton",
        "settingsIgnoreFailureButton",
        "settingsReindexFolderButton",
        "settingsRebuildQueueButton",
        "settingsCleanupCacheButton"
    ]

    @EnvironmentObject private var dependencies: DependencyContainer
    @StateObject private var model = SettingsWindowModel()
    @State private var folderPendingRemoval: WatchedFolder?

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
        .frame(minWidth: LocalLensTheme.Metrics.settingsMinWidth, minHeight: LocalLensTheme.Metrics.settingsMinHeight)
        .confirmationDialog(
            "Remove watched folder?",
            isPresented: Binding(
                get: { folderPendingRemoval != nil },
                set: { isPresented in
                    if !isPresented { folderPendingRemoval = nil }
                }
            ),
            titleVisibility: .visible,
            presenting: folderPendingRemoval
        ) { folder in
            Button("Remove Folder", role: .destructive) {
                model.removeFolder(folder)
                folderPendingRemoval = nil
            }
            Button("Cancel", role: .cancel) { folderPendingRemoval = nil }
        } message: { folder in
            Text("LocalLens removes derived index records for \(folder.displayName) without touching source media files.")
        }
        .task { model.configure(dependencies: dependencies) }
    }

    private var foldersTab: some View {
        SettingsPane(title: "Watched Folders", subtitle: "Manage the folders LocalLens is allowed to read for private indexing.", statusMessage: model.statusMessage) {
            HStack {
                Button("Refresh") { model.refresh() }
                    .accessibilityIdentifier("settingsFoldersRefreshButton")
                Button("Add Folder…") { model.addFolder() }
                    .accessibilityIdentifier("settingsAddFolderButton")
                Spacer()
            }

            Text("Shortcuts: Space preview • ⌘⇧R reveal • ⌘O open • ⌥⌘C path • ⌘⇧C snippet")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(8)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .accessibilityIdentifier("settingsShortcutsSummary")

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
                                if let lastScan = folder.lastScanCompletedAt ?? folder.lastScanStartedAt {
                                    Text("Last scan: \(lastScan.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Last scan: Not yet scanned")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Toggle("Enabled", isOn: Binding(
                                get: { folder.isEnabled },
                                set: { model.setFolder(folder, enabled: $0) }
                            ))
                            .toggleStyle(.switch)
                            Button("Reauthorize") { model.reauthorizeFolder(folder) }
                            Button("Remove", role: .destructive) { folderPendingRemoval = folder }
                                .accessibilityIdentifier("settingsRemoveFolderButton")
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
                MetricCard(title: "Queued Jobs", value: "\(model.storageUsage.queuedJobCount)")
                MetricCard(title: "Storage", value: model.storageUsage.formattedTotal)
                MetricCard(title: "Image/PDF", value: "\(model.imagePDFMetrics.total)")
                MetricCard(title: "Image/PDF Complete", value: "\(model.imagePDFMetrics.complete)")
                MetricCard(title: "Image/PDF Partial", value: "\(model.imagePDFMetrics.partial)")
                MetricCard(title: "Image/PDF Failed", value: "\(model.imagePDFMetrics.failed)")
                MetricCard(title: "Audio/Video", value: "\(model.audioVideoMetrics.total)")
                MetricCard(title: "A/V Complete", value: "\(model.audioVideoMetrics.complete)")
                MetricCard(title: "A/V Partial", value: "\(model.audioVideoMetrics.partial)")
                MetricCard(title: "A/V Failed", value: "\(model.audioVideoMetrics.failed)")
            }
            .accessibilityIdentifier("settingsIndexingMetrics")

            HStack {
                StatusPill(text: model.progress.isPaused ? "Paused" : (model.progress.isRunning ? "Running" : "Idle"))
                if model.audioVideoMetrics.skippedProvider > 0 {
                    StatusPill(text: "A/V provider skipped: \(model.audioVideoMetrics.skippedProvider)")
                        .accessibilityIdentifier("settingsAudioVideoSkippedProviderPill")
                }
                if let lastIndexed = model.progress.lastIndexedAt {
                    Text("Last indexed: \(lastIndexed.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundStyle(.secondary)
                }
                if let lastImagePDFIndexed = model.imagePDFMetrics.lastIndexedAt {
                    Text("Image/PDF last indexed: \(lastImagePDFIndexed.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("settingsImagePDFLastIndexedText")
                }
                if let lastAudioVideoIndexed = model.audioVideoMetrics.lastIndexedAt {
                    Text("A/V last indexed: \(lastAudioVideoIndexed.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("settingsAudioVideoLastIndexedText")
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
                Button("Rebuild Queue") { model.rebuildQueue() }
                    .accessibilityIdentifier("settingsRebuildQueueButton")
                Spacer()
            }

            FailureDashboardView(failures: model.failures) { failure, action in
                model.performFailureAction(failure, action: action)
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

            officeIndexingSection

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
                            StatusPill(text: provider.lastHealthStatus.rawValue)
                            StatusPill(text: provider.credentialState.rawValue)
                            Toggle("Automatic indexing", isOn: Binding(
                                get: { provider.automaticIndexingEnabled },
                                set: { model.setProvider(provider, automaticIndexing: $0) }
                            ))
                            .disabled(provider.locality != .localLoopback)
                            Spacer()
                        }
                        providerSelectionControls(for: provider)

                        if provider.locality != .localLoopback {
                            Text("Remote AI can receive selected file content or derived text when indexing. Keep this off unless you trust the endpoint. LocalLens never enables remote AI automatically.")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .accessibilityIdentifier("settingsRemoteProviderWarning")
                        }
                    }
                    .padding(10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .accessibilityIdentifier("settingsProvidersList")
        }
    }


    private var officeIndexingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Office document indexing", systemImage: "doc.text.magnifyingglass")
                .font(.headline)
            Text("Office indexing uses Hermes Agent only. Enable each type explicitly; LocalLens never routes Office content to Ollama, oMLX, or custom providers.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Toggle("PowerPoint (.pptx)", isOn: Binding(
                    get: { model.officePreferences.pptxEnabled },
                    set: { model.setOfficePreference(kind: .pptx, enabled: $0) }
                ))
                .accessibilityIdentifier("settingsOfficePPTXToggle")
                Toggle("Word (.docx)", isOn: Binding(
                    get: { model.officePreferences.docxEnabled },
                    set: { model.setOfficePreference(kind: .docx, enabled: $0) }
                ))
                .accessibilityIdentifier("settingsOfficeDOCXToggle")
                Toggle("Excel (.xlsx)", isOn: Binding(
                    get: { model.officePreferences.xlsxEnabled },
                    set: { model.setOfficePreference(kind: .xlsx, enabled: $0) }
                ))
                .accessibilityIdentifier("settingsOfficeXLSXToggle")
                Spacer()
            }
            if !model.hermesProfileState.isReadyForOfficeIndexing {
                Text("Hermes Agent profile selection is required before new Office jobs can start.")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("settingsOfficeHermesReadinessWarning")
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("settingsOfficeIndexingSection")
    }

    @ViewBuilder
    private func providerSelectionControls(for provider: ProviderSetting) -> some View {
        if provider.id == "ollama" || provider.id == "omlx" {
            let state = model.providerModelStates[provider.id] ?? ProviderModelSelectionState(providerID: provider.id, selectedModelID: provider.selectedModelID, availableModelIDs: provider.modelIDs)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Selected model").font(.caption).foregroundStyle(.secondary)
                    Picker("Selected model", selection: Binding(
                        get: { state.selectedModelID ?? "" },
                        set: { model.selectProviderModel(provider, modelID: $0.isEmpty ? nil : $0) }
                    )) {
                        Text("Choose model…").tag("")
                        ForEach(state.availableModelIDs, id: \.self) { modelID in
                            Text(modelID).tag(modelID)
                        }
                    }
                    .frame(maxWidth: 240)
                    .accessibilityIdentifier("settingsProviderModelPicker_\(provider.id)")
                    Button("Refresh Models") { model.refreshProviderModels(provider) }
                        .accessibilityIdentifier("settingsProviderModelRefresh_\(provider.id)")
                    Spacer()
                }
                if state.availabilityState == .stale {
                    Text("Selected model is stale. Choose a currently reported model before new provider-backed work starts.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("settingsProviderModelStaleWarning_\(provider.id)")
                }
            }
        }
        if provider.id == "hermes-agent" {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Hermes profile").font(.caption).foregroundStyle(.secondary)
                    Picker("Hermes profile", selection: Binding(
                        get: { model.hermesProfileState.selectedProfileID ?? "" },
                        set: { model.selectHermesProfile(profileID: $0.isEmpty ? nil : $0) }
                    )) {
                        Text("Choose profile…").tag("")
                        ForEach(model.hermesProfileState.availableProfiles) { profile in
                            Text(profile.displayName).tag(profile.id)
                        }
                    }
                    .frame(maxWidth: 240)
                    .accessibilityIdentifier("settingsHermesProfilePicker")
                    Button("Refresh Profiles") { model.refreshHermesProfiles(provider) }
                        .accessibilityIdentifier("settingsHermesProfilesRefreshButton")
                    Spacer()
                }
                Text("Office indexing uses the selected Hermes profile, including its model, provider, and skills.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if model.hermesProfileState.availabilityState == .stale || model.hermesProfileState.availabilityState == .unavailable {
                    Text("Selected Hermes profile is unavailable or stale; Office indexing is blocked until a valid profile is selected.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("settingsHermesProfileStaleWarning")
                }
            }
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
                Text("Local index/cache size: \(model.storageUsage.formattedTotal)")
                    .font(.headline)
                    .accessibilityIdentifier("settingsStorageUsageText")
            }
            .accessibilityIdentifier("settingsPrivacyStorageSummary")

            VStack(alignment: .leading, spacing: 8) {
                Label("Keyboard shortcuts", systemImage: "keyboard")
                    .font(.headline)
                ShortcutRow(title: "Preview selected result", shortcut: "Space")
                ShortcutRow(title: "Reveal in Finder", shortcut: "⌘⇧R")
                ShortcutRow(title: "Open in default app", shortcut: "⌘O")
                ShortcutRow(title: "Copy source path", shortcut: "⌥⌘C")
                ShortcutRow(title: "Copy snippet", shortcut: "⌘⇧C")
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityIdentifier("settingsShortcutsSummary")

            HStack {
                Button("Refresh") { model.refresh() }
                    .accessibilityIdentifier("settingsStorageRefreshButton")
                Button("Delete Local Index", role: .destructive) { model.deleteLocalIndex() }
                    .accessibilityIdentifier("settingsDeleteIndexButton")
                Button("Rebuild Index") { model.rebuildIndex() }
                    .accessibilityIdentifier("settingsRebuildIndexButton")
                Button("Cleanup Cache") { model.cleanupCache() }
                    .accessibilityIdentifier("settingsCleanupCacheButton")
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

            FailureDashboardView(failures: model.failures) { failure, action in
                model.performFailureAction(failure, action: action)
            }
            .accessibilityIdentifier(model.failures.isEmpty ? "settingsDiagnosticsEmptyState" : "settingsFailuresList")
        }
    }
}

@MainActor
private final class SettingsWindowModel: ObservableObject {
    @Published var folders: [WatchedFolder] = []
    @Published var providers: [ProviderSetting] = []
    @Published var officePreferences = OfficeIndexingPreferences()
    @Published var providerModelStates: [String: ProviderModelSelectionState] = [:]
    @Published var hermesProfileState = HermesProfileSelectionState()
    @Published var failures: [IndexFailure] = []
    @Published var progress = IndexProgressSnapshot()
    @Published var imagePDFMetrics = MediaIndexingMetrics()
    @Published var audioVideoMetrics = MediaIndexingMetrics()
    @Published var indexedAssetCount = 0
    @Published var storageUsage = StorageUsageSnapshot(databaseBytes: 0, cacheBytes: 0, indexedAssetCount: 0, queuedJobCount: 0)
    @Published var diagnosticSummary = "Diagnostics redact full paths, transcripts, extracted text, credentials, thumbnails, prompts, and raw provider bodies."
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
                self.officePreferences = try await dependencies.storage.officePreferences.load()
                self.providerModelStates = Dictionary(uniqueKeysWithValues: (try await dependencies.storage.providerModelSelections.list()).map { ($0.providerID, $0) })
                self.hermesProfileState = try await dependencies.storage.hermesProfileSelection.load()
                self.failures = try await dependencies.storage.failures.unresolved()
                self.progress = await dependencies.indexQueue.snapshot()
                self.imagePDFMetrics = try await Self.loadMetrics(from: dependencies.storage.assets, mediaTypes: [.image, .pdf])
                self.audioVideoMetrics = try await Self.loadMetrics(from: dependencies.storage.assets, mediaTypes: [.audio, .video])
                self.indexedAssetCount = try await dependencies.storage.maintenance.indexedAssetCount()
                self.storageUsage = try await dependencies.storage.maintenance.storageUsage()
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

    func addFolder() {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            guard let self else { return }
            do {
                guard let selection = try await dependencies.folderAuthorizationService.requestFolderAuthorization() else { return }
                try await dependencies.storage.watchedFolders.save(selection.folder)
                try await dependencies.watchedFolderViewModel.queueDiscovery(for: selection.folder, rootURL: selection.url, dependencies: dependencies)
                self.refresh()
            } catch {
                self.statusMessage = "Unable to add folder: \(error.localizedDescription)"
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
                try await dependencies.folderAuthorizationService.remove(folder: folder, storage: dependencies.storage)
                self.refresh()
            } catch {
                self.statusMessage = "Unable to remove folder: \(error.localizedDescription)"
            }
        }
    }

    func reauthorizeFolder(_ folder: WatchedFolder) {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            guard let self else { return }
            do {
                guard let selection = try await dependencies.folderAuthorizationService.reauthorize(folder) else { return }
                try await dependencies.storage.watchedFolders.save(selection.folder)
                try await dependencies.watchedFolderViewModel.queueDiscovery(for: selection.folder, rootURL: selection.url, dependencies: dependencies)
                self.refresh()
            } catch {
                self.statusMessage = "Unable to reauthorize folder: \(error.localizedDescription)"
            }
        }
    }


    func setOfficePreference(kind: OfficeDocumentKind, enabled: Bool) {
        guard let dependencies else { return }
        var updated = officePreferences
        switch kind {
        case .pptx: updated.pptxEnabled = enabled
        case .docx: updated.docxEnabled = enabled
        case .xlsx: updated.xlsxEnabled = enabled
        }
        officePreferences = updated
        Task { @MainActor [weak self, dependencies, updated] in
            guard let self else { return }
            do {
                try await dependencies.storage.officePreferences.save(updated)
                self.statusMessage = "Office indexing preference updated. Rebuild the queue to apply it to existing folders."
            } catch {
                self.statusMessage = "Unable to update Office preference: \(error.localizedDescription)"
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


    func selectProviderModel(_ provider: ProviderSetting, modelID: String?) {
        guard let dependencies else { return }
        var updatedProvider = provider
        updatedProvider.selectedModelID = modelID
        let state = ProviderModelSelectionState(
            providerID: provider.id,
            selectedModelID: modelID,
            availableModelIDs: providerModelStates[provider.id]?.availableModelIDs ?? provider.modelIDs,
            availabilityState: modelID == nil ? .unknown : .available,
            lastRefreshedAt: Date(),
            lastSafeError: nil
        )
        providerModelStates[provider.id] = state
        Task { @MainActor [weak self, dependencies, updatedProvider, state] in
            guard let self else { return }
            do {
                try await dependencies.storage.providers.save(updatedProvider)
                try await dependencies.storage.providerModelSelections.save(state)
                self.refresh()
            } catch {
                self.statusMessage = "Unable to update selected model: \(error.localizedDescription)"
            }
        }
    }

    func refreshProviderModels(_ provider: ProviderSetting) {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies, provider] in
            guard let self else { return }
            let previous = self.providerModelStates[provider.id]
            let state = await dependencies.providerSelectionService.refreshModelSelection(for: provider, previous: previous)
            var updatedProvider = ProviderSelectionService.apply(state, to: provider)
            if updatedProvider.selectedModelID == nil, state.availableModelIDs.count == 1 {
                updatedProvider.selectedModelID = state.availableModelIDs.first
            }
            do {
                try await dependencies.storage.providerModelSelections.save(state)
                try await dependencies.storage.providers.save(updatedProvider)
                self.refresh()
            } catch {
                self.statusMessage = "Unable to refresh models: \(error.localizedDescription)"
            }
        }
    }

    func selectHermesProfile(profileID: String?) {
        guard let dependencies else { return }
        var updated = hermesProfileState
        updated.selectedProfileID = profileID
        updated.selectedProfileDisplayName = profileID.flatMap { id in updated.availableProfiles.first { $0.id == id }?.displayName }
        updated.availabilityState = profileID == nil ? .unknown : (updated.availableProfiles.contains { $0.id == profileID } ? .available : .stale)
        hermesProfileState = updated
        Task { @MainActor [weak self, dependencies, updated] in
            guard let self else { return }
            do {
                try await dependencies.storage.hermesProfileSelection.save(updated)
                self.refresh()
            } catch {
                self.statusMessage = "Unable to update Hermes profile: \(error.localizedDescription)"
            }
        }
    }

    func refreshHermesProfiles(_ provider: ProviderSetting) {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies, provider] in
            guard let self else { return }
            let refreshed = await dependencies.providerSelectionService.refreshHermesProfiles(provider: provider, previous: self.hermesProfileState)
            do {
                try await dependencies.storage.hermesProfileSelection.save(refreshed)
                self.refresh()
            } catch {
                self.statusMessage = "Unable to refresh Hermes profiles: \(error.localizedDescription)"
            }
        }
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

    func rebuildIndex() {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            guard let self else { return }
            do {
                try await dependencies.storage.maintenance.rebuildIndexData()
                self.statusMessage = "Rebuild index queued from watched folders."
                self.refresh()
            } catch {
                self.statusMessage = "Unable to rebuild index: \(error.localizedDescription)"
            }
        }
    }

    func rebuildQueue() {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            guard let self else { return }
            do {
                try await dependencies.indexCoordinator.rebuildQueue(storage: dependencies.storage, queue: dependencies.indexQueue)
                self.statusMessage = "Indexing queue rebuilt from watched folders."
                self.refresh()
            } catch {
                self.statusMessage = "Unable to rebuild queue: \(error.localizedDescription)"
            }
        }
    }

    func cleanupCache() {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            guard let self else { return }
            do {
                try await dependencies.storage.maintenance.cleanupCacheData()
                self.statusMessage = "Derived cache cleaned. Source media files were not modified."
                self.refresh()
            } catch {
                self.statusMessage = "Unable to cleanup cache: \(error.localizedDescription)"
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

    func performFailureAction(_ failure: IndexFailure, action: FailureRecoveryAction) {
        guard let dependencies else { return }
        Task { @MainActor [weak self, dependencies] in
            guard let self else { return }
            do {
                switch action {
                case .retry:
                    try await dependencies.indexCoordinator.retryFailure(failure, storage: dependencies.storage, queue: dependencies.indexQueue)
                    self.statusMessage = "Retry queued for failed item."
                case .ignore:
                    try await dependencies.indexCoordinator.ignoreFailure(failure, storage: dependencies.storage)
                    self.statusMessage = "Failure ignored."
                case .reauthorize:
                    self.statusMessage = "Open Folders and use Reauthorize for the affected folder."
                case .rebuildIndex:
                    try await dependencies.indexCoordinator.rebuildQueue(storage: dependencies.storage, queue: dependencies.indexQueue)
                    self.statusMessage = "Rebuild queued."
                case .none:
                    self.statusMessage = "No recovery action is available for this failure."
                }
                self.refresh()
            } catch {
                self.statusMessage = "Unable to perform recovery action: \(error.localizedDescription)"
            }
        }
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

    private static func loadMetrics(from assetsRepository: any MediaAssetRepository, mediaTypes: Set<MediaType>) async throws -> MediaIndexingMetrics {
        let assets = try await assetsRepository.list(watchedFolderID: nil)
            .filter { mediaTypes.contains($0.mediaType) }
        return MediaIndexingMetrics(
            total: assets.count,
            complete: assets.filter { $0.indexState == .complete }.count,
            partial: assets.filter { $0.indexState == .partial }.count,
            failed: assets.filter { $0.indexState == .failed }.count,
            skippedProvider: assets.filter { $0.indexState == .partial }.count,
            lastIndexedAt: assets.compactMap(\.lastIndexedAt).max()
        )
    }
}

private struct MediaIndexingMetrics: Equatable {
    var total: Int = 0
    var complete: Int = 0
    var partial: Int = 0
    var failed: Int = 0
    var skippedProvider: Int = 0
    var lastIndexedAt: Date?
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

private struct ShortcutRow: View {
    let title: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(shortcut)
                .font(.caption.monospaced())
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 5))
        }
        .font(.caption)
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

