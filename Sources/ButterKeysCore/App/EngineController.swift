import Foundation

public extension Notification.Name {
    static let butterKeysUndoShortcut = Notification.Name("com.timbeniks.ButterKeys.undoShortcut")
    static let butterKeysTeachShortcut = Notification.Name("com.timbeniks.ButterKeys.teachShortcut")
    static let butterKeysDidApplyCorrection = Notification.Name("com.timbeniks.ButterKeys.didApplyCorrection")
    static let butterKeysDidTeachRule = Notification.Name("com.timbeniks.ButterKeys.didTeachRule")
}

public final class EngineController: @unchecked Sendable {
    private let appState: AppState
    private let database: DatabaseManager

    private let syntheticGuard = SyntheticEventGuard()
    private lazy var emitter = SyntheticEventEmitter(syntheticGuard: syntheticGuard)
    private lazy var executor = TextReplacementExecutor(emitter: emitter)
    private lazy var undoManager = ButterUndoManager(
        executor: executor,
        historyRepository: CorrectionHistoryRepository(dbQueue: database.dbQueue)
    )

    private let secureInputDetector = SecureInputDetector()
    private let sensitiveContextPolicy: SensitiveContextPolicy
    private let ruleRepository: CorrectionRuleRepository
    private let applicationPolicyRepository: ApplicationPolicyRepository

    private var languageServices: LanguageServices
    private var correctionCoordinator: CorrectionCoordinator
    private var keyboardProcessor: KeyboardEventProcessor!
    private var keyboardMonitor: KeyboardEventMonitor!
    private var activeApplicationMonitor: ActiveApplicationMonitor!

    private let processingQueue = DispatchQueue(label: "com.timbeniks.ButterKeys.engine", qos: .userInteractive)
    private var undoObserver: NSObjectProtocol?

    private var userPaused = false
    private var permissionsGranted = false
    private var settings = AppSettings()
    private var userModeOverrides: [String: ApplicationMode] = [:]

    private var currentAppInfo = ActiveApplicationInfo(bundleIdentifier: nil, localizedName: nil)
    private var contextEvaluation = SensitiveContextEvaluation(
        monitoringStatus: .needsPermission,
        applicationMode: .prose,
        shouldProcessInput: false
    )

    public var contextStatus: MonitoringStatus {
        contextEvaluation.monitoringStatus
    }

    public var currentBundleIdentifier: String? {
        currentAppInfo.bundleIdentifier
    }

    public var currentApplicationName: String? {
        currentAppInfo.localizedName
    }

    public var eventTapState: KeyboardEventMonitor.State {
        keyboardMonitor?.currentState ?? .stopped
    }

    public var applicationMode: ApplicationMode {
        contextEvaluation.applicationMode
    }

    public init(appState: AppState, database: DatabaseManager) {
        self.appState = appState
        self.database = database
        ruleRepository = CorrectionRuleRepository(dbQueue: database.dbQueue)
        applicationPolicyRepository = ApplicationPolicyRepository(dbQueue: database.dbQueue)
        sensitiveContextPolicy = SensitiveContextPolicy()

        let dictionary = LocalDictionary.loadBundled()
        languageServices = LanguageServices(dictionary: dictionary)
        correctionCoordinator = CorrectionCoordinator(language: languageServices)

        setupPipeline()
        observeUndoShortcut()
    }

    deinit {
        if let undoObserver {
            NotificationCenter.default.removeObserver(undoObserver)
        }
        stop()
    }

    public func start() {
        secureInputDetector.startPeriodicChecks()
        activeApplicationMonitor.start()
        refreshContextEvaluation()

        if permissionsGranted, settings.enabled, !userPaused {
            keyboardMonitor.start()
        }
    }

    public func stop() {
        keyboardMonitor.stop()
        activeApplicationMonitor.stop()
        secureInputDetector.stopPeriodicChecks()
    }

    public func reloadConfiguration(from state: AppState) {
        Task { @MainActor in
            self.settings = state.settings
            self.userModeOverrides = state.userModeOverrides()
            self.permissionsGranted = state.permissionsGranted
            self.userPaused = state.isPaused
            self.reloadRules(from: state.rules)
            self.reloadDictionary(from: state.customWords)
            self.correctionCoordinator.updatePolicy(
                ConfidencePolicy(
                    automaticThreshold: state.settings.automaticThreshold,
                    suggestionThreshold: state.settings.suggestionThreshold,
                    allowsSpeculativeStrategies: state.settings.confidencePreset.allowsSpeculativeStrategies
                )
            )
            self.keyboardProcessor?.updateLearningConfiguration(
                enabled: state.settings.learnFromManualCorrections,
                appBundleID: self.currentAppInfo.bundleIdentifier
            )
            self.syncMonitoringState()
            state.refreshStatus()
        }
    }

    public func updatePermissionState(granted: Bool) {
        permissionsGranted = granted
        syncMonitoringState()
    }

    public func setPaused(_ paused: Bool) {
        userPaused = paused
        syncMonitoringState()
    }

    @discardableResult
    public func performUndo() -> Bool {
        undoManager.performUndo()
    }

    // MARK: - Setup

    private func setupPipeline() {
        let translator = KeyboardLayoutTranslator()
        keyboardProcessor = KeyboardEventProcessor(
            translator: translator,
            syntheticGuard: syntheticGuard,
            queue: processingQueue,
            onCorrectionRequest: { [weak self] request in
                self?.handleCorrectionRequest(request)
            },
            onManualCorrection: { [weak self] pair in
                self?.handleManualCorrection(pair)
            }
        )

        keyboardMonitor = KeyboardEventMonitor(processor: keyboardProcessor)

        activeApplicationMonitor = ActiveApplicationMonitor { [weak self] info in
            self?.handleActiveApplicationChanged(info)
        }
    }

    private func observeUndoShortcut() {
        undoObserver = NotificationCenter.default.addObserver(
            forName: .butterKeysUndoShortcut,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _ = self?.performUndo()
            Task { @MainActor in
                self?.appState.reload()
            }
        }
    }

    // MARK: - Rules

    private func reloadRules(from rules: [CorrectionRuleRecord]) {
        let enabledRules = rules.filter(\.enabled)
        RuleCache.shared.update(enabledRules)
        correctionCoordinator.updateRules(enabledRules)
    }

    private func reloadDictionary(from customWords: [CustomWordRecord]) {
        var never: Set<String> = []
        var names: Set<String> = []
        var extra: Set<String> = []
        for record in customWords {
            let word = record.word.lowercased()
            switch CustomWordCategory(rawValue: record.category) {
            case .protected:
                never.insert(word)
            case .name:
                names.insert(word)
                extra.insert(word)
            case .dictionary, .none:
                extra.insert(word)
            }
        }
        let base = LocalDictionary.loadBundled()
        languageServices = LanguageServices(
            dictionary: base.withCustom(never: never, names: names, extra: extra)
        )
        correctionCoordinator.updateLanguage(languageServices)
    }

    public func bootstrap() {
        Task { @MainActor in
            self.settings = appState.settings
            self.userModeOverrides = appState.userModeOverrides()
            self.permissionsGranted = appState.permissionsGranted
            self.userPaused = appState.isPaused
            self.reloadRules(from: appState.rules)
            self.reloadDictionary(from: appState.customWords)
            self.correctionCoordinator.updatePolicy(
                ConfidencePolicy(
                    automaticThreshold: appState.settings.automaticThreshold,
                    suggestionThreshold: appState.settings.suggestionThreshold,
                    allowsSpeculativeStrategies: appState.settings.confidencePreset.allowsSpeculativeStrategies
                )
            )
            self.keyboardProcessor?.updateLearningConfiguration(
                enabled: appState.settings.learnFromManualCorrections,
                appBundleID: self.currentAppInfo.bundleIdentifier
            )
            self.start()
        }
    }

    // MARK: - Context

    private func refreshContextEvaluation() {
        _ = secureInputDetector.checkNow()
        contextEvaluation = sensitiveContextPolicy.evaluate(
            bundleIdentifier: currentAppInfo.bundleIdentifier,
            secureInputActive: secureInputDetector.secureInputActive,
            focusedElementSecure: nil,
            userModeOverrides: userModeOverrides
        )
    }

    private func handleActiveApplicationChanged(_ info: ActiveApplicationInfo) {
        currentAppInfo = info
        refreshContextEvaluation()
        keyboardProcessor.signalActiveApplicationChanged(bundleID: info.bundleIdentifier)
        keyboardProcessor.updateLearningConfiguration(
            enabled: settings.learnFromManualCorrections,
            appBundleID: info.bundleIdentifier
        )
        // Keep the tap alive across app switches; only correction gating uses context.
        syncMonitoringState()
        Task { @MainActor in
            appState.refreshStatus()
        }
    }

    private func syncMonitoringState() {
        refreshContextEvaluation()

        // Event tap must run whenever we have permission — not only in the frontmost app.
        // Excluded apps are skipped later in handleCorrectionRequest.
        let shouldRun = permissionsGranted
            && settings.enabled
            && !userPaused

        switch keyboardMonitor.currentState {
        case .stopped:
            if shouldRun { keyboardMonitor.start() }
        case .running:
            if !shouldRun { keyboardMonitor.pause() }
        case .paused:
            if shouldRun { keyboardMonitor.resume() }
            else if !permissionsGranted || !settings.enabled { keyboardMonitor.stop() }
        }

        Task { @MainActor in
            appState.refreshStatus()
        }
    }

    // MARK: - Correction pipeline

    private func handleCorrectionRequest(_ request: CorrectionRequest) {
        refreshContextEvaluation()

        guard permissionsGranted else { return }
        guard settings.enabled else { return }
        guard !userPaused else { return }
        guard contextEvaluation.shouldProcessInput else { return }
        // Mid-token backspacing usually means the user is editing, not finishing a typo.
        guard !request.tokenWasEdited else { return }

        let context = CorrectionContext(
            tokens: request.tokens,
            currentToken: request.currentToken,
            previousToken: request.previousToken,
            phraseFragment: request.phraseFragment,
            boundary: request.boundary,
            appBundleID: currentAppInfo.bundleIdentifier,
            applicationMode: contextEvaluation.applicationMode,
            keyTimings: request.keyTimings,
            bufferText: request.bufferText
        )

        guard let candidate = correctionCoordinator.evaluate(context) else { return }

        let replacement = PeriodSpacing.adjustedReplacement(
            original: candidate.original,
            replacement: candidate.replacement,
            precedingPhrase: request.bufferText
        )

        let result = executor.execute(
            plan: CorrectionTransactionPlan(
                original: candidate.original,
                replacement: replacement,
                boundary: request.boundary
            ),
            strategyID: candidate.strategyID,
            confidence: candidate.confidence,
            appBundleID: currentAppInfo.bundleIdentifier
        )

        switch result {
        case .success(let transaction):
            undoManager.record(transaction)
            Task { @MainActor in
                appState.recordCorrection(transaction)
            }
        case .failure:
            break
        }
    }

    private func handleManualCorrection(_ pair: ManualCorrectionPair) {
        guard settings.learnFromManualCorrections else { return }
        Task { @MainActor in
            appState.observeManualCorrection(pair)
        }
    }
}
