import Foundation

public enum LearnedPatternStatus: String, Sendable, Codable {
    case observing
    case pendingSuggestion = "pending_suggestion"
    case automatic
    case suggestOnly = "suggest_only"
    case rejected
    case never
}

public enum LearnedPatternType: String, Sendable, Codable {
    case manualCorrection = "manual_correction"
    case acceptedCorrection = "accepted_correction"
}

public enum MotorPatternType: String, Sendable, Codable {
    case nearbyKeySubstitution = "nearby_key_substitution"
}

public struct ManualCorrectionPair: Sendable, Equatable {
    public let source: String
    public let replacement: String
    public let appBundleID: String?

    public init(source: String, replacement: String, appBundleID: String? = nil) {
        self.source = source
        self.replacement = replacement
        self.appBundleID = appBundleID
    }
}

public struct LearnedPatternSuggestion: Sendable, Equatable, Identifiable {
    public let id: String
    public let source: String
    public let replacement: String
    public let observedCount: Int
    public let confidence: Double
    public let appBundleID: String?

    public init(record: LearnedPatternRecord) {
        id = record.id
        source = record.source
        replacement = record.replacement
        observedCount = record.observedCount
        confidence = record.confidence
        appBundleID = record.appBundleID
    }
}

public enum UserPatternDecision: Sendable, Equatable {
    case acceptAutomatic
    case acceptSuggestOnly
    case reject
    case never
}
