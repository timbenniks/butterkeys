import Foundation

public struct CorrectionCandidate: Sendable, Equatable, Identifiable {
    public var id: String { "\(strategyID):\(original)→\(replacement):\(affectedRange)" }

    public let original: String
    public let replacement: String
    public let affectedRange: Range<Int>
    public let strategyID: String
    public let confidence: Double
    public let explanation: String
    public let requiresBoundary: Bool
    public let suggestionOnly: Bool

    public init(
        original: String,
        replacement: String,
        affectedRange: Range<Int>,
        strategyID: String,
        confidence: Double,
        explanation: String,
        requiresBoundary: Bool = true,
        suggestionOnly: Bool = false
    ) {
        self.original = original
        self.replacement = replacement
        self.affectedRange = affectedRange
        self.strategyID = strategyID
        self.confidence = confidence
        self.explanation = explanation
        self.requiresBoundary = requiresBoundary
        self.suggestionOnly = suggestionOnly
    }
}

public struct CorrectionContext: Sendable {
    public let tokens: [String]
    public let currentToken: String
    public let previousToken: String?
    public let phraseFragment: String
    public let boundary: Character?
    public let appBundleID: String?
    public let applicationMode: ApplicationMode
    public let keyTimings: [TimeInterval]
    public let bufferText: String

    public init(
        tokens: [String],
        currentToken: String,
        previousToken: String?,
        phraseFragment: String,
        boundary: Character?,
        appBundleID: String?,
        applicationMode: ApplicationMode,
        keyTimings: [TimeInterval] = [],
        bufferText: String = ""
    ) {
        self.tokens = tokens
        self.currentToken = currentToken
        self.previousToken = previousToken
        self.phraseFragment = phraseFragment
        self.boundary = boundary
        self.appBundleID = appBundleID
        self.applicationMode = applicationMode
        self.keyTimings = keyTimings
        self.bufferText = bufferText
    }

    public var completedWord: String? {
        guard boundary != nil || !currentToken.isEmpty else { return nil }
        return currentToken
    }
}

public enum ApplicationMode: String, Sendable, Codable, CaseIterable, Identifiable {
    case disabled
    case plainText = "plain_text"
    case prose
    case codeSafe = "code_safe"
    case custom

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .disabled: "Disabled"
        case .plainText: "Plain text"
        case .prose: "Prose"
        case .codeSafe: "Code-safe"
        case .custom: "Custom"
        }
    }
}

public enum RuleBehaviour: String, Sendable, Codable, CaseIterable, Identifiable {
    case automatic
    case suggestion
    case never

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .automatic: "Automatic"
        case .suggestion: "Suggest only"
        case .never: "Never"
        }
    }
}

public enum MatchType: String, Sendable, Codable, CaseIterable, Identifiable {
    case word
    case phrase

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .word: "Word"
        case .phrase: "Phrase"
        }
    }
}

public enum ConfidencePreset: String, Sendable, Codable, CaseIterable, Identifiable {
    /// Only explicit / taught rules auto-correct. Speculative pattern strategies stay off.
    case taughtOnly = "taught_only"
    case conservative
    case balanced
    case enthusiastic

    public var id: String { rawValue }

    public var allowsSpeculativeStrategies: Bool {
        self != .taughtOnly
    }

    public var automaticThreshold: Double {
        switch self {
        case .taughtOnly: 0.90
        case .conservative: 0.92
        case .balanced: 0.85
        case .enthusiastic: 0.78
        }
    }

    public var suggestionThreshold: Double {
        switch self {
        case .taughtOnly: 0.90
        case .conservative: 0.70
        case .balanced: 0.60
        case .enthusiastic: 0.55
        }
    }

    public var displayName: String {
        switch self {
        case .taughtOnly: "Taught only"
        case .conservative: "Conservative"
        case .balanced: "Balanced"
        case .enthusiastic: "Enthusiastic"
        }
    }

    public var detail: String {
        switch self {
        case .taughtOnly:
            "Only rules you teach (or accept) fire automatically."
        case .conservative:
            "High-confidence pattern fixes plus your rules."
        case .balanced:
            "A wider set of motor-pattern fixes plus your rules."
        case .enthusiastic:
            "Most aggressive automatic pattern matching."
        }
    }
}

public enum ButterLevel: String, Sendable, Codable, CaseIterable, Identifiable {
    case plain
    case lightlyButtered = "lightly_buttered"
    case extraButtery = "extra_buttery"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .plain: "Plain"
        case .lightlyButtered: "Lightly buttered"
        case .extraButtery: "Extra buttery"
        }
    }
}

public enum MonitoringStatus: Sendable, Equatable {
    case smoothing
    case paused
    case resting(until: Date?)
    case secureInput
    case needsPermission
    case disabled
    case excluded
}

public struct AppSettings: Sendable, Equatable, Codable {
    /// Bumped when defaults change so existing installs can migrate once.
    public var settingsSchemaVersion: Int = 0
    public var enabled: Bool = true
    public var launchAtLogin: Bool = false
    public var confidencePreset: ConfidencePreset = .taughtOnly
    public var automaticThreshold: Double = 0.90
    public var suggestionThreshold: Double = 0.90
    public var undoShortcut: String = "⌃⌥Z"
    public var teachShortcut: String = "⌃⌥T"
    public var showCorrectionFeedback: Bool = false
    public var playCorrectionSound: Bool = false
    public var keepHistory: Bool = true
    public var historyRetentionDays: Int = 30
    public var butterLevel: ButterLevel = .lightlyButtered
    public var learnFromManualCorrections: Bool = true
    public var learnMotorPatterns: Bool = true
    public var learningRepetitionThreshold: Int = 3
    public var clipboardFallbackEnabled: Bool = false
    public var debugLogging: Bool = false
    public var onboardingCompleted: Bool = false

    public init() {}

    /// One-shot migration onto the teach-first defaults.
    public mutating func migrateIfNeeded() -> Bool {
        guard settingsSchemaVersion < 1 else { return false }
        confidencePreset = .taughtOnly
        automaticThreshold = ConfidencePreset.taughtOnly.automaticThreshold
        suggestionThreshold = ConfidencePreset.taughtOnly.suggestionThreshold
        if teachShortcut.isEmpty { teachShortcut = "⌃⌥T" }
        settingsSchemaVersion = 1
        return true
    }
}
