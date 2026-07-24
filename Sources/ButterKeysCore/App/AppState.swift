import AppKit
import Foundation
import Observation

public struct LastCorrectionDisplay: Sendable, Equatable {
    public let source: String
    public let replacement: String

    public init(source: String, replacement: String) {
        self.source = source
        self.replacement = replacement
    }
}

@MainActor
@Observable
public final class AppState {
    public var settings: AppSettings
    public private(set) var status: MonitoringStatus = .needsPermission
    public private(set) var smoothedToday: Int = 0
    public private(set) var lastCorrection: LastCorrectionDisplay?
    public private(set) var rules: [CorrectionRuleRecord] = []
    public private(set) var history: [CorrectionHistoryRecord] = []
    public private(set) var applicationPolicies: [ApplicationPolicyRecord] = []
    public private(set) var pendingSuggestions: [LearnedPatternSuggestion] = []
    public private(set) var customWords: [CustomWordRecord] = []
    public private(set) var inputMonitoringGranted = false
    public private(set) var accessibilityGranted = false
    public private(set) var isPaused = false
    public private(set) var pauseUntil: Date?

    public var permissionsGranted: Bool {
        inputMonitoringGranted && accessibilityGranted
    }

    /// Redacted diagnostics for support — never includes buffer text or sentences.
    public var diagnosticsSummary: String {
        let tap: String = {
            guard let engineController else { return "unattached" }
            switch engineController.eventTapState {
            case .running: return "running"
            case .paused: return "paused"
            case .stopped: return "stopped"
            }
        }()
        let last: String = {
            guard let correction = lastCorrection else { return "none" }
            return "\(correction.source) → \(correction.replacement)"
        }()
        let front = engineController?.currentBundleIdentifier ?? "—"
        let mode = engineController.map { String(describing: $0.applicationMode) } ?? "—"
        return """
        ButterKeys diagnostics (redacted)
        Version: see About
        Status: \(copy.monitoringStatus(status))
        Event tap: \(tap)
        Frontmost app: \(front)
        App mode: \(mode)
        Last correction: \(last)
        Smoothed today: \(smoothedToday)
        Input Monitoring: \(inputMonitoringGranted ? "granted" : "missing")
        Accessibility: \(accessibilityGranted ? "granted" : "missing")
        """
    }

    public func copyDiagnosticsToPasteboard() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(diagnosticsSummary, forType: .string)
    }

    public var copy: CopyProvider {
        CopyProvider(butterLevel: settings.butterLevel)
    }

    private let database: DatabaseManager
    private let settingsRepository: SettingsRepository
    private let ruleRepository: CorrectionRuleRepository
    private let historyRepository: CorrectionHistoryRepository
    private let applicationPolicyRepository: ApplicationPolicyRepository
    private let suggestionCoordinator: SuggestionCoordinator
    private weak var engineController: EngineController?

    public init(database: DatabaseManager) {
        self.database = database
        settingsRepository = SettingsRepository(dbQueue: database.dbQueue)
        ruleRepository = CorrectionRuleRepository(dbQueue: database.dbQueue)
        historyRepository = CorrectionHistoryRepository(dbQueue: database.dbQueue)
        applicationPolicyRepository = ApplicationPolicyRepository(dbQueue: database.dbQueue)

        var loaded = (try? settingsRepository.load()) ?? AppSettings()
        let didMigrate = loaded.migrateIfNeeded()

        let learnedRepository = LearnedPatternRepository(dbQueue: database.dbQueue)
        let rejectionTracker = UserRejectionTracker()
        let learner = TypoPatternLearner(
            repository: learnedRepository,
            rejectionTracker: rejectionTracker,
            suggestionThreshold: loaded.learningRepetitionThreshold
        )
        suggestionCoordinator = SuggestionCoordinator(
            learner: learner,
            rejectionTracker: rejectionTracker,
            repository: learnedRepository
        )
        settings = loaded
        if didMigrate {
            try? settingsRepository.save(settings)
        }
    }

    public func attachEngine(_ engine: EngineController) {
        engineController = engine
    }

    public var engineEventTapState: KeyboardEventMonitor.State? {
        engineController?.eventTapState
    }

    public var engineFrontmostBundleID: String {
        engineController?.currentBundleIdentifier ?? "—"
    }

    public var engineApplicationModeLabel: String {
        guard let mode = engineController?.applicationMode else { return "—" }
        return mode.displayName
    }

    public func reload() {
        do {
            settings = try settingsRepository.load()
            if settings.migrateIfNeeded() {
                try settingsRepository.save(settings)
            }
            rules = try ruleRepository.fetchAll()
            history = try historyRepository.fetchRecent(limit: 200)
            applicationPolicies = try applicationPolicyRepository.fetchAll()
            customWords = try CustomWordRepository(dbQueue: database.dbQueue).fetchAll()
            try suggestionCoordinator.refresh()
            pendingSuggestions = suggestionCoordinator.pendingSuggestions
            smoothedToday = countSmoothedToday(from: history)
            lastCorrection = history.first(where: { !$0.wasUndone }).map {
                LastCorrectionDisplay(source: $0.source, replacement: $0.replacement)
            }
            refreshPauseState()
            refreshStatus()
        } catch {
            // Keep running with in-memory state if reload fails.
        }
    }

    public func applySettings() {
        settings.automaticThreshold = settings.confidencePreset.automaticThreshold
        settings.suggestionThreshold = settings.confidencePreset.suggestionThreshold
        suggestionCoordinator.updateSuggestionThreshold(settings.learningRepetitionThreshold)

        do {
            try settingsRepository.save(settings)
            try LaunchAtLoginManager.setEnabled(settings.launchAtLogin)
            engineController?.reloadConfiguration(from: self)
            refreshStatus()
        } catch {
            // Settings persist failure is surfaced via copy elsewhere if needed.
        }
    }

    public func observeManualCorrection(_ pair: ManualCorrectionPair) {
        guard settings.learnFromManualCorrections else { return }
        do {
            _ = try suggestionCoordinator.observeManualCorrection(pair)
            pendingSuggestions = suggestionCoordinator.pendingSuggestions
        } catch {}
    }

    public func toggleEnabled() {
        settings.enabled.toggle()
        if settings.enabled {
            resume()
        }
        applySettings()
    }

    public func pause(for duration: TimeInterval) {
        isPaused = true
        pauseUntil = Date().addingTimeInterval(duration)
        engineController?.setPaused(true)
        refreshStatus()
    }

    public func pauseUntilTomorrow() {
        let calendar = Calendar.current
        let startOfTomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        isPaused = true
        pauseUntil = startOfTomorrow
        engineController?.setPaused(true)
        refreshStatus()
    }

    public func pauseInCurrentApp() {
        guard let bundleID = engineController?.currentBundleIdentifier else { return }
        let policy = ApplicationPolicyRecord(
            bundleIdentifier: bundleID,
            displayName: engineController?.currentApplicationName,
            mode: .disabled
        )
        do {
            try applicationPolicyRepository.save(policy)
            reload()
            engineController?.reloadConfiguration(from: self)
        } catch {}
    }

    public func resume() {
        isPaused = false
        pauseUntil = nil
        engineController?.setPaused(false)
        refreshStatus()
    }

    @discardableResult
    public func undoLast() -> Bool {
        guard let engineController else { return false }
        let success = engineController.performUndo()
        if success {
            reload()
        }
        return success
    }

    public func updatePermissions(inputMonitoring: Bool, accessibility: Bool) {
        inputMonitoringGranted = inputMonitoring
        accessibilityGranted = accessibility
        refreshStatus()
        engineController?.updatePermissionState(granted: permissionsGranted)
    }

    public func recordCorrection(_ transaction: CorrectionTransaction) {
        lastCorrection = LastCorrectionDisplay(
            source: transaction.original,
            replacement: transaction.replacement
        )
        if settings.keepHistory {
            do {
                try historyRepository.append(transaction.historyRecord())
                smoothedToday = countSmoothedToday(
                    from: (try? historyRepository.fetchRecent(limit: 200)) ?? []
                )
            } catch {
                smoothedToday += 1
            }
        } else {
            smoothedToday += 1
        }
        refreshStatus()
        NotificationCenter.default.post(
            name: .butterKeysDidApplyCorrection,
            object: nil,
            userInfo: [
                "source": transaction.original,
                "replacement": transaction.replacement
            ]
        )
    }

    public func saveRule(_ rule: CorrectionRuleRecord) {
        do {
            try ruleRepository.save(rule)
            reload()
            engineController?.reloadConfiguration(from: self)
        } catch {}
    }

    /// Creates or updates a global automatic rule from a taught typo pair.
    @discardableResult
    public func upsertTaughtRule(
        source: String,
        replacement: String,
        behaviour: RuleBehaviour = .automatic
    ) -> CorrectionRuleRecord? {
        guard let draft = TeachCapture.makeRule(
            source: source,
            replacement: replacement,
            behaviour: behaviour
        ) else {
            return nil
        }

        if let existing = rules.first(where: {
            $0.appBundleID == nil
                && $0.source.caseInsensitiveCompare(draft.source) == .orderedSame
        }) {
            var updated = existing
            updated.replacement = draft.replacement
            updated.matchType = draft.matchType
            updated.behaviour = behaviour
            updated.enabled = true
            updated.updatedAt = Date()
            saveRule(updated)
            return updated
        }

        saveRule(draft)
        return draft
    }

    public func deleteRule(id: String) {
        do {
            try ruleRepository.delete(id: id)
            reload()
            engineController?.reloadConfiguration(from: self)
        } catch {}
    }

    public func customWords(in category: CustomWordCategory) -> [CustomWordRecord] {
        customWords
            .filter { $0.category == category.rawValue }
            .sorted { $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending }
    }

    public static func normalizeCustomWord(_ raw: String) -> String? {
        let word = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !word.isEmpty, word.allSatisfy({ $0.isLetter || $0 == "'" || $0 == "-" }) else {
            return nil
        }
        return word
    }

    @discardableResult
    public func addCustomWord(_ raw: String, category: CustomWordCategory) -> Bool {
        guard let word = Self.normalizeCustomWord(raw) else { return false }
        return saveCustomWord(
            CustomWordRecord(word: word, category: category.rawValue)
        )
    }

    /// Insert or update a custom dictionary word. Enforces unique normalized spelling.
    @discardableResult
    public func saveCustomWord(_ record: CustomWordRecord) -> Bool {
        guard let word = Self.normalizeCustomWord(record.word) else { return false }
        do {
            let repo = CustomWordRepository(dbQueue: database.dbQueue)
            let all = try repo.fetchAll()
            if let clash = all.first(where: {
                $0.id != record.id && $0.word.caseInsensitiveCompare(word) == .orderedSame
            }) {
                // Move the existing spelling into the requested category instead of duplicating.
                var merged = clash
                merged.category = record.category
                try repo.save(merged)
                if all.contains(where: { $0.id == record.id }) {
                    try repo.delete(id: record.id)
                }
            } else {
                var saved = record
                saved.word = word
                try repo.save(saved)
            }
            reload()
            engineController?.reloadConfiguration(from: self)
            return true
        } catch {
            return false
        }
    }

    public func deleteCustomWord(id: String) {
        do {
            try CustomWordRepository(dbQueue: database.dbQueue).delete(id: id)
            reload()
            engineController?.reloadConfiguration(from: self)
        } catch {}
    }

    /// Protect the original side of a false-positive correction.
    public func protectWord(_ word: String) {
        _ = addCustomWord(word, category: .protected)
    }

    public func saveApplicationPolicy(_ policy: ApplicationPolicyRecord) {
        do {
            try applicationPolicyRepository.save(policy)
            reload()
            engineController?.reloadConfiguration(from: self)
        } catch {}
    }

    public func deleteApplicationPolicy(id: String) {
        do {
            try applicationPolicyRepository.delete(id: id)
            reload()
            engineController?.reloadConfiguration(from: self)
        } catch {}
    }

    public func acceptSuggestionAutomatic(id: String) {
        do {
            let suggestion = pendingSuggestions.first { $0.id == id }
            try suggestionCoordinator.acceptAutomatic(id: id)
            if let suggestion {
                _ = upsertTaughtRule(
                    source: suggestion.source,
                    replacement: suggestion.replacement,
                    behaviour: .automatic
                )
            } else {
                reload()
            }
        } catch {}
    }

    public func acceptSuggestionOnly(id: String) {
        do {
            let suggestion = pendingSuggestions.first { $0.id == id }
            try suggestionCoordinator.acceptSuggestOnly(id: id)
            if let suggestion {
                _ = upsertTaughtRule(
                    source: suggestion.source,
                    replacement: suggestion.replacement,
                    behaviour: .suggestion
                )
            } else {
                reload()
            }
        } catch {}
    }

    public func rejectSuggestion(id: String) {
        do {
            try suggestionCoordinator.reject(id: id)
            reload()
        } catch {}
    }

    public func completeOnboarding() {
        settings.onboardingCompleted = true
        applySettings()
    }

    public func userModeOverrides() -> [String: ApplicationMode] {
        Dictionary(uniqueKeysWithValues: applicationPolicies.map { ($0.bundleIdentifier, $0.mode) })
    }

    public func exportRulesJSON(includeLearned: Bool = true) throws -> Data {
        let learned = try LearnedPatternRepository(dbQueue: database.dbQueue).fetchAll()
        let words = try CustomWordRepository(dbQueue: database.dbQueue).fetchAll()
        return try RulesImportExport.export(
            rules: rules,
            customWords: words,
            policies: applicationPolicies,
            learned: learned,
            includeLearned: includeLearned
        )
    }

    public func importRulesJSON(_ data: Data) throws {
        let document = try RulesImportExport.importDocument(from: data)
        for item in document.rules {
            let behaviour = RuleBehaviour(rawValue: item.mode) ?? .automatic
            let matchType = MatchType(rawValue: item.matchType) ?? .word
            let rule = CorrectionRuleRecord(
                source: item.source,
                replacement: item.replacement,
                matchType: matchType,
                appBundleID: item.scope == "global" ? nil : item.scope,
                behaviour: behaviour
            )
            try ruleRepository.save(rule)
        }
        for item in document.applicationPolicies {
            guard let mode = ApplicationMode(rawValue: item.mode) else { continue }
            try applicationPolicyRepository.save(
                ApplicationPolicyRecord(
                    bundleIdentifier: item.bundleIdentifier,
                    displayName: item.displayName,
                    mode: mode
                )
            )
        }
        let wordRepo = CustomWordRepository(dbQueue: database.dbQueue)
        for item in document.customWords {
            try wordRepo.save(CustomWordRecord(word: item.word, category: item.category))
        }
        reload()
        engineController?.reloadConfiguration(from: self)
    }

    public func clearHistory() {
        do {
            try historyRepository.deleteOlderThan(Date.distantFuture)
            reload()
        } catch {}
    }

    public func clearLearnedData() {
        do {
            let learned = LearnedPatternRepository(dbQueue: database.dbQueue)
            for pattern in try learned.fetchAll() {
                try learned.delete(id: pattern.id)
            }
            let motors = MotorPatternRepository(dbQueue: database.dbQueue)
            for pattern in try motors.fetchAll() {
                try motors.delete(id: pattern.id)
            }
            reload()
        } catch {}
    }

    public func deleteAllData() {
        do {
            clearHistory()
            clearLearnedData()
            for rule in try ruleRepository.fetchAll() {
                try ruleRepository.delete(id: rule.id)
            }
            for policy in try applicationPolicyRepository.fetchAll() {
                try applicationPolicyRepository.delete(id: policy.id)
            }
            let words = CustomWordRepository(dbQueue: database.dbQueue)
            for word in try words.fetchAll() {
                try words.delete(id: word.id)
            }
            settings = AppSettings()
            try settingsRepository.save(settings)
            try SeedDefaults.seedIfNeeded(dbQueue: database.dbQueue)
            reload()
            engineController?.reloadConfiguration(from: self)
        } catch {}
    }

    public func openDataFolder() {
        let url = DatabaseManager.defaultDatabaseURL.deletingLastPathComponent()
        NSWorkspace.shared.open(url)
    }

    // MARK: - Private

    private func refreshPauseState() {
        if let pauseUntil, pauseUntil <= Date() {
            isPaused = false
            self.pauseUntil = nil
            engineController?.setPaused(false)
        } else if pauseUntil != nil {
            isPaused = true
        }
    }

    public func refreshStatus() {
        refreshPauseState()

        guard settings.enabled else {
            status = .disabled
            return
        }
        guard permissionsGranted else {
            status = .needsPermission
            return
        }
        if isPaused {
            status = pauseUntil == nil ? .paused : .resting(until: pauseUntil)
            return
        }
        if let engineStatus = engineController?.contextStatus {
            status = engineStatus
            return
        }
        status = .smoothing
    }

    private func countSmoothedToday(from history: [CorrectionHistoryRecord]) -> Int {
        let calendar = Calendar.current
        return history.filter {
            !$0.wasUndone && calendar.isDateInToday($0.createdAt)
        }.count
    }
}
