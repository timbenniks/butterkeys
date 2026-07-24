import Foundation
import GRDB

public struct CorrectionRuleRecord: Codable, FetchableRecord, PersistableRecord, Sendable, Identifiable {
    public static let databaseTableName = "correction_rules"

    public var id: String
    public var source: String
    public var replacement: String
    public var matchType: MatchType
    public var preserveCase: Bool
    public var caseSensitive: Bool
    public var appBundleID: String?
    public var applicationMode: ApplicationMode?
    public var behaviour: RuleBehaviour
    public var enabled: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        source: String,
        replacement: String,
        matchType: MatchType,
        preserveCase: Bool = true,
        caseSensitive: Bool = false,
        appBundleID: String? = nil,
        applicationMode: ApplicationMode? = nil,
        behaviour: RuleBehaviour,
        enabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.source = source
        self.replacement = replacement
        self.matchType = matchType
        self.preserveCase = preserveCase
        self.caseSensitive = caseSensitive
        self.appBundleID = appBundleID
        self.applicationMode = applicationMode
        self.behaviour = behaviour
        self.enabled = enabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, source, replacement, behaviour, enabled
        case matchType = "match_type"
        case preserveCase = "preserve_case"
        case caseSensitive = "case_sensitive"
        case appBundleID = "app_bundle_id"
        case applicationMode = "application_mode"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct LearnedPatternRecord: Codable, FetchableRecord, PersistableRecord, Sendable, Identifiable {
    public static let databaseTableName = "learned_patterns"

    public var id: String
    public var source: String
    public var replacement: String
    public var patternType: String
    public var observedCount: Int
    public var acceptedCount: Int
    public var undoCount: Int
    public var confidence: Double
    public var appBundleID: String?
    public var status: String
    public var firstSeenAt: Date
    public var lastSeenAt: Date

    public init(
        id: String = UUID().uuidString,
        source: String,
        replacement: String,
        patternType: String,
        observedCount: Int = 0,
        acceptedCount: Int = 0,
        undoCount: Int = 0,
        confidence: Double = 0,
        appBundleID: String? = nil,
        status: String,
        firstSeenAt: Date = Date(),
        lastSeenAt: Date = Date()
    ) {
        self.id = id
        self.source = source
        self.replacement = replacement
        self.patternType = patternType
        self.observedCount = observedCount
        self.acceptedCount = acceptedCount
        self.undoCount = undoCount
        self.confidence = confidence
        self.appBundleID = appBundleID
        self.status = status
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
    }

    enum CodingKeys: String, CodingKey {
        case id, source, replacement, confidence, status
        case patternType = "pattern_type"
        case observedCount = "observed_count"
        case acceptedCount = "accepted_count"
        case undoCount = "undo_count"
        case appBundleID = "app_bundle_id"
        case firstSeenAt = "first_seen_at"
        case lastSeenAt = "last_seen_at"
    }
}

public struct MotorPatternRecord: Codable, FetchableRecord, PersistableRecord, Sendable, Identifiable {
    public static let databaseTableName = "motor_patterns"

    public var id: String
    public var patternType: String
    public var sourceValue: String
    public var observedValue: String
    public var occurrenceCount: Int
    public var confidence: Double
    public var firstSeenAt: Date
    public var lastSeenAt: Date

    public init(
        id: String = UUID().uuidString,
        patternType: String,
        sourceValue: String,
        observedValue: String,
        occurrenceCount: Int = 0,
        confidence: Double = 0,
        firstSeenAt: Date = Date(),
        lastSeenAt: Date = Date()
    ) {
        self.id = id
        self.patternType = patternType
        self.sourceValue = sourceValue
        self.observedValue = observedValue
        self.occurrenceCount = occurrenceCount
        self.confidence = confidence
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
    }

    enum CodingKeys: String, CodingKey {
        case id, confidence
        case patternType = "pattern_type"
        case sourceValue = "source_value"
        case observedValue = "observed_value"
        case occurrenceCount = "occurrence_count"
        case firstSeenAt = "first_seen_at"
        case lastSeenAt = "last_seen_at"
    }
}

public struct CorrectionHistoryRecord: Codable, FetchableRecord, PersistableRecord, Sendable, Identifiable {
    public static let databaseTableName = "correction_history"

    public var id: String
    public var source: String
    public var replacement: String
    public var correctionType: String
    public var appBundleID: String?
    public var confidence: Double
    public var wasUndone: Bool
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        source: String,
        replacement: String,
        correctionType: String,
        appBundleID: String? = nil,
        confidence: Double,
        wasUndone: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.source = source
        self.replacement = replacement
        self.correctionType = correctionType
        self.appBundleID = appBundleID
        self.confidence = confidence
        self.wasUndone = wasUndone
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, source, replacement, confidence
        case correctionType = "correction_type"
        case appBundleID = "app_bundle_id"
        case wasUndone = "was_undone"
        case createdAt = "created_at"
    }
}

public struct ApplicationPolicyRecord: Codable, FetchableRecord, PersistableRecord, Sendable, Identifiable {
    public static let databaseTableName = "application_policies"

    public var id: String
    public var bundleIdentifier: String
    public var displayName: String?
    public var mode: ApplicationMode
    public var enabled: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        bundleIdentifier: String,
        displayName: String? = nil,
        mode: ApplicationMode,
        enabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.mode = mode
        self.enabled = enabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, mode, enabled
        case bundleIdentifier = "bundle_identifier"
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct CustomWordRecord: Codable, FetchableRecord, PersistableRecord, Sendable, Identifiable {
    public static let databaseTableName = "custom_words"

    public var id: String
    public var word: String
    public var category: String
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        word: String,
        category: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.word = word
        self.category = category
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, word, category
        case createdAt = "created_at"
    }
}

struct SettingRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "settings"

    var key: String
    var value: String
}
