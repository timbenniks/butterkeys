import Foundation

/// Centralized ButterLevel-aware user-facing copy.
/// Privacy, permission, error, and security strings are always plain/direct.
public struct CopyProvider: Sendable {
    public let butterLevel: ButterLevel

    public init(butterLevel: ButterLevel) {
        self.butterLevel = butterLevel
    }

    // MARK: - Menu

    public var menuActiveTitle: String {
        switch butterLevel {
        case .plain: "ButterKeys: On"
        case .lightlyButtered: "ButterKeys: Smooth"
        case .extraButtery: "ButterKeys: Smooth as toast"
        }
    }

    public var undoLastLabel: String {
        switch butterLevel {
        case .plain: "Undo last correction"
        case .lightlyButtered: "Undo last smooth"
        case .extraButtery: "Un-smooth the last one"
        }
    }

    public var teachFromSelectionLabel: String {
        switch butterLevel {
        case .plain: "Teach from selection…"
        case .lightlyButtered, .extraButtery: "Teach a smoother…"
        }
    }

    public var openSettingsLabel: String { "Open ButterKeys" }
    public var quitLabel: String { "Quit ButterKeys" }

    public func lastCorrectionLabel(source: String, replacement: String) -> String {
        "\(source) → \(replacement)"
    }

    public var lastCorrectionTitle: String {
        switch butterLevel {
        case .plain: "Last correction"
        case .lightlyButtered, .extraButtery: "Last smooth"
        }
    }

    // MARK: - Settings headings

    public var automaticCorrectionsTitle: String {
        switch butterLevel {
        case .plain: "Automatic corrections"
        case .lightlyButtered: "Automatic smoothing"
        case .extraButtery: "Automatic smoothing"
        }
    }

    public var teachPanelTitle: String {
        switch butterLevel {
        case .plain: "Teach a correction"
        case .lightlyButtered, .extraButtery: "Teach a smoother"
        }
    }

    public var teachPanelSubtitle: String {
        switch butterLevel {
        case .plain:
            "Select a typo, then tell ButterKeys what you meant. Next time it will fix it automatically."
        case .lightlyButtered, .extraButtery:
            "Select a slip, then tell ButterKeys what you meant. Next time it melts away on its own."
        }
    }

    public var teachSourcePlaceholder: String { "What you typed" }
    public var teachReplacementPlaceholder: String { "What you meant" }

    public var teachSaveLabel: String {
        switch butterLevel {
        case .plain: "Save rule"
        case .lightlyButtered, .extraButtery: "Save smoother"
        }
    }

    public var teachInvalidPairMessage: String {
        "Enter a short typed form and the corrected form."
    }

    public func teachSavedFeedback(source: String, replacement: String) -> String {
        switch butterLevel {
        case .plain: "Saved \(source) → \(replacement)"
        case .lightlyButtered, .extraButtery: "Taught \(source) → \(replacement)"
        }
    }

    public var correctionHistoryTitle: String {
        switch butterLevel {
        case .plain: "Correction history"
        case .lightlyButtered: "Smoothing history"
        case .extraButtery: "Smoothing history"
        }
    }

    public var pauseCorrectionsTitle: String {
        switch butterLevel {
        case .plain: "Pause corrections"
        case .lightlyButtered: "Pause smoothing"
        case .extraButtery: "Give ButterKeys a rest"
        }
    }

    // MARK: - Monitoring (always direct)

    public func monitoringStatus(_ status: MonitoringStatus) -> String {
        switch status {
        case .smoothing:
            switch butterLevel {
            case .plain: "ButterKeys is active"
            case .lightlyButtered: "ButterKeys is smoothing"
            case .extraButtery: "Your typing is nicely buttered"
            }
        case .paused:
            switch butterLevel {
            case .plain: "ButterKeys is paused"
            case .lightlyButtered: "Smoothing paused"
            case .extraButtery: "ButterKeys is chilled"
            }
        case .resting(until: _):
            switch butterLevel {
            case .plain: "ButterKeys is paused"
            case .lightlyButtered: "ButterKeys is resting"
            case .extraButtery: "ButterKeys is resting"
            }
        case .secureInput:
            "ButterKeys is paused for secure input."
        case .needsPermission:
            "ButterKeys needs permission to smooth typing."
        case .disabled:
            "ButterKeys is disabled."
        case .excluded:
            "ButterKeys is paused in this app."
        }
    }

    // MARK: - Feedback

    public func correctionAppliedFeedback() -> String {
        switch butterLevel {
        case .plain: "Correction applied"
        case .lightlyButtered: "Smoothed."
        case .extraButtery: feedbackMessages.randomElement() ?? "Freshly smoothed."
        }
    }

    public func correctionPairFeedback(source: String, replacement: String) -> String {
        "\(source) → \(replacement)"
    }

    // MARK: - Empty states

    public var rulesEmptyTitle: String {
        switch butterLevel {
        case .plain: "No personal rules yet"
        case .lightlyButtered: "No personal smoothers yet"
        case .extraButtery: "No personal smoothers yet"
        }
    }

    public var rulesEmptySubtitle: String {
        switch butterLevel {
        case .plain:
            "Select a typo and press ⌃⌥T, or add a rule here."
        case .lightlyButtered, .extraButtery:
            "Select a slip and press ⌃⌥T, or add a smoother here."
        }
    }

    public var historyEmptyTitle: String {
        switch butterLevel {
        case .plain: "Nothing corrected yet"
        case .lightlyButtered: "Nothing smoothed yet"
        case .extraButtery: "Nothing smoothed yet"
        }
    }

    public var historyEmptySubtitle: String {
        switch butterLevel {
        case .plain:
            "Corrections will appear here after ButterKeys helps."
        case .lightlyButtered, .extraButtery:
            "Either your typing is flawless or ButterKeys has just arrived."
        }
    }

    public var learningEmptyTitle: String {
        switch butterLevel {
        case .plain: "No learned patterns yet"
        case .lightlyButtered, .extraButtery: "No new patterns yet"
        }
    }

    public var learningEmptySubtitle: String {
        switch butterLevel {
        case .plain:
            "Teach with ⌃⌥T, or keep fixing typos manually — repeats can become suggestions."
        case .lightlyButtered, .extraButtery:
            "Teach with ⌃⌥T, or let your fingers do research the long way."
        }
    }

    public var applicationsEmptyTitle: String { "No additional excluded apps" }

    public var applicationsEmptySubtitle: String {
        "ButterKeys already avoids secure fields and sensitive applications."
    }

    public func pendingSuggestionPrompt(source: String, replacement: String) -> String {
        switch butterLevel {
        case .plain:
            "You often change “\(source)” to “\(replacement)”. Apply this automatically?"
        case .lightlyButtered, .extraButtery:
            "You often change “\(source)” to “\(replacement)”. Smooth this automatically?"
        }
    }

    public var repeatedUndoPrompt: String {
        switch butterLevel {
        case .plain:
            "This correction keeps getting undone. ButterKeys will stop applying it automatically."
        case .lightlyButtered, .extraButtery:
            "This smooth keeps getting undone. ButterKeys will stop applying it automatically."
        }
    }

    // MARK: - Errors (always direct)

    public func permissionStatusSummary(
        inputMonitoring: Bool,
        accessibility: Bool
    ) -> String {
        switch (inputMonitoring, accessibility) {
        case (true, true):
            "Permissions ready."
        case (true, false):
            "Accessibility still required."
        case (false, true):
            "Input Monitoring still required."
        case (false, false):
            "Input Monitoring and Accessibility required."
        }
    }

    public var permissionError: String {
        "ButterKeys cannot smooth typing yet.\n\nEnable Input Monitoring and Accessibility in System Settings."
    }

    public var eventTapStoppedError: String {
        "ButterKeys lost access to keyboard events.\n\nRestore permissions or restart ButterKeys."
    }

    public var databaseError: String {
        "ButterKeys could not save this correction.\n\nTyping will continue normally."
    }

    public var correctionFailureError: String {
        "ButterKeys could not safely apply that correction.\n\nYour original text was left unchanged."
    }

    public var onboardingReady: String {
        switch butterLevel {
        case .plain: "ButterKeys is ready."
        case .lightlyButtered: "ButterKeys is ready to smooth."
        case .extraButtery: "ButterKeys is ready to smooth."
        }
    }

    private var feedbackMessages: [String] {
        [
            "Another typo melted away.",
            "ButterKeys caught a slippery one.",
            "Letters successfully unjumbled.",
            "Freshly smoothed."
        ]
    }
}
