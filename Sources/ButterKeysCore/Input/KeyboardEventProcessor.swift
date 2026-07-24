import Carbon
import Foundation
import OSLog

public final class KeyboardEventProcessor: @unchecked Sendable {
    public typealias CorrectionHandler = @Sendable (CorrectionRequest) -> Void
    public typealias ManualCorrectionHandler = @Sendable (ManualCorrectionPair) -> Void

    private enum KeyCode {
        static let delete: UInt16 = UInt16(kVK_Delete)
        static let forwardDelete: UInt16 = UInt16(kVK_ForwardDelete)
        static let returnKey: UInt16 = UInt16(kVK_Return)
        static let tab: UInt16 = UInt16(kVK_Tab)
        static let escape: UInt16 = UInt16(kVK_Escape)
        static let leftArrow: UInt16 = UInt16(kVK_LeftArrow)
        static let rightArrow: UInt16 = UInt16(kVK_RightArrow)
        static let upArrow: UInt16 = UInt16(kVK_UpArrow)
        static let downArrow: UInt16 = UInt16(kVK_DownArrow)
        static let z: UInt16 = UInt16(kVK_ANSI_Z)
        static let t: UInt16 = UInt16(kVK_ANSI_T)
    }

    private let queue: DispatchQueue
    private let logger = Logger(subsystem: "com.timbeniks.ButterKeys", category: "KeyboardEventProcessor")
    private let translator: KeyboardLayoutTranslator
    private let syntheticGuard: SyntheticEventGuard
    private let onCorrectionRequest: CorrectionHandler
    private let onManualCorrection: ManualCorrectionHandler?

    private var buffer = InputBuffer()
    private var modifiers = ModifierState()
    private var timings = KeystrokeTimingTracker()
    private var manualDetector = ManualCorrectionDetector()
    private var isPaused = false
    private var learnFromManualCorrections = true
    private var currentAppBundleID: String?

    public init(
        translator: KeyboardLayoutTranslator,
        syntheticGuard: SyntheticEventGuard,
        queue: DispatchQueue = DispatchQueue(label: "com.timbeniks.ButterKeys.keyboard-processor", qos: .userInteractive),
        onCorrectionRequest: @escaping CorrectionHandler,
        onManualCorrection: ManualCorrectionHandler? = nil
    ) {
        self.translator = translator
        self.syntheticGuard = syntheticGuard
        self.queue = queue
        self.onCorrectionRequest = onCorrectionRequest
        self.onManualCorrection = onManualCorrection
    }

    public func enqueue(_ event: NormalizedKeyEvent) {
        queue.async { [self] in
            self.process(event)
        }
    }

    public func pause() {
        queue.async { [self] in
            self.isPaused = true
        }
    }

    public func resume() {
        queue.async { [self] in
            self.isPaused = false
        }
    }

    public func updateLearningConfiguration(enabled: Bool, appBundleID: String?) {
        queue.async { [self] in
            self.learnFromManualCorrections = enabled
            self.currentAppBundleID = appBundleID
            if !enabled {
                self.manualDetector.reset()
            }
        }
    }

    public func resetBuffer(reason: String) {
        queue.async { [self] in
            self.buffer.reset()
            self.timings.reset()
            self.manualDetector.reset()
            self.logger.debug("Input buffer reset (\(reason, privacy: .public))")
        }
    }

    public func signalPointerClick() {
        resetBuffer(reason: "pointer-click")
    }

    public func signalInputSourceChanged() {
        queue.async { [self] in
            self.translator.reset()
            self.buffer.reset()
            self.timings.reset()
            self.manualDetector.reset()
            self.logger.debug("Input source changed; buffer cleared")
        }
    }

    public func signalActiveApplicationChanged(bundleID: String?) {
        queue.async { [self] in
            self.currentAppBundleID = bundleID
            self.buffer.reset()
            self.timings.reset()
            self.manualDetector.reset()
            self.logger.debug("Input buffer reset (active-application-changed)")
        }
    }

    private func process(_ event: NormalizedKeyEvent) {
        guard !isPaused else { return }

        modifiers.apply(event)

        if event.type == .flagsChanged {
            return
        }

        guard event.type == .keyDown else { return }
        guard !syntheticGuard.isSynthetic(event) else { return }

        timings.record(timestamp: event.timestamp)

        // Control-Option-Z → ButterKeys undo (before ignoring control shortcuts).
        if modifiers.control, modifiers.option, !modifiers.command, event.keyCode == KeyCode.z {
            NotificationCenter.default.post(name: .butterKeysUndoShortcut, object: nil)
            return
        }

        // Control-Option-T → teach from selection.
        if modifiers.control, modifiers.option, !modifiers.command, event.keyCode == KeyCode.t {
            NotificationCenter.default.post(name: .butterKeysTeachShortcut, object: nil)
            return
        }

        if modifiers.commandOrControlDown {
            return
        }

        switch event.keyCode {
        case KeyCode.delete:
            handleBackspace()
            return
        case KeyCode.forwardDelete:
            buffer.forwardDelete()
            return
        case KeyCode.escape,
             KeyCode.leftArrow,
             KeyCode.rightArrow,
             KeyCode.upArrow,
             KeyCode.downArrow:
            buffer.reset()
            timings.reset()
            manualDetector.reset()
            return
        case KeyCode.returnKey:
            emitBoundary(boundary: "\n", timestamp: event.timestamp)
            return
        case KeyCode.tab:
            emitBoundary(boundary: "\t", timestamp: event.timestamp)
            return
        default:
            break
        }

        guard let character = resolvedCharacter(for: event) else { return }
        guard character.count == 1, let scalar = character.first else { return }

        if isWordBoundary(scalar) {
            emitBoundary(boundary: scalar, timestamp: event.timestamp)
        } else {
            if learnFromManualCorrections {
                manualDetector.recordRetypeStarted()
            }
            buffer.appendCharacter(scalar)
        }
    }

    private func handleBackspace() {
        let removed = buffer.snapshot.currentToken.last
        buffer.backspace()
        if learnFromManualCorrections {
            manualDetector.recordBackspace(removed: removed)
        }
    }

    private func resolvedCharacter(for event: NormalizedKeyEvent) -> String? {
        if let characters = event.characters, !characters.isEmpty {
            return characters
        }
        return translator.translate(keyCode: event.keyCode, modifiers: event.modifiers)
    }

    private func isWordBoundary(_ character: Character) -> Bool {
        if character.isWhitespace {
            return true
        }
        return character.unicodeScalars.allSatisfy { CharacterSet.punctuationCharacters.contains($0) }
    }

    private func emitBoundary(boundary: Character, timestamp: TimeInterval) {
        // Capture the completed word BEFORE markBoundary clears currentToken.
        let before = buffer.snapshot
        let completedToken = before.currentToken
        buffer.markBoundary(with: boundary)

        if learnFromManualCorrections,
           let pair = manualDetector.evaluateBoundary(
            completedToken: completedToken,
            appBundleID: currentAppBundleID
           ) {
            onManualCorrection?(pair)
        } else {
            manualDetector.reset()
        }

        guard !completedToken.isEmpty else { return }

        let after = buffer.snapshot
        let request = CorrectionRequest(
            currentToken: completedToken,
            previousToken: before.previousToken,
            phraseFragment: after.phraseFragment,
            tokens: after.tokens,
            boundary: boundary,
            keyTimings: timings.recentIntervals,
            bufferText: before.phraseFragment,
            eventTimestamp: timestamp,
            tokenWasEdited: before.currentTokenWasEdited
        )
        onCorrectionRequest(request)
    }
}
