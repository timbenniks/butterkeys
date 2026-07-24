import Foundation
import GRDB

public final class CorrectionRuleRepository: Sendable {
    private let dbQueue: DatabaseQueue

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func fetchAll(enabledOnly: Bool = false) throws -> [CorrectionRuleRecord] {
        try dbQueue.read { db in
            var request = CorrectionRuleRecord.all().order(Column("source"))
            if enabledOnly {
                request = request.filter(Column("enabled") == true)
            }
            return try request.fetchAll(db)
        }
    }

    public func fetch(id: String) throws -> CorrectionRuleRecord? {
        try dbQueue.read { db in
            try CorrectionRuleRecord.fetchOne(db, key: id)
        }
    }

    public func save(_ rule: CorrectionRuleRecord) throws {
        try dbQueue.write { db in
            try rule.save(db)
        }
    }

    public func delete(id: String) throws {
        _ = try dbQueue.write { db in
            try CorrectionRuleRecord.deleteOne(db, key: id)
        }
    }
}

public final class LearnedPatternRepository: Sendable {
    private let dbQueue: DatabaseQueue

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func fetchAll(status: String? = nil) throws -> [LearnedPatternRecord] {
        try dbQueue.read { db in
            var request = LearnedPatternRecord.all().order(Column("last_seen_at").desc)
            if let status {
                request = request.filter(Column("status") == status)
            }
            return try request.fetchAll(db)
        }
    }

    public func fetch(id: String) throws -> LearnedPatternRecord? {
        try dbQueue.read { db in
            try LearnedPatternRecord.fetchOne(db, key: id)
        }
    }

    public func save(_ pattern: LearnedPatternRecord) throws {
        try dbQueue.write { db in
            try pattern.save(db)
        }
    }

    public func delete(id: String) throws {
        _ = try dbQueue.write { db in
            try LearnedPatternRecord.deleteOne(db, key: id)
        }
    }
}

public final class CorrectionHistoryRepository: Sendable {
    private let dbQueue: DatabaseQueue

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func append(_ entry: CorrectionHistoryRecord) throws {
        try dbQueue.write { db in
            try entry.insert(db)
        }
    }

    public func fetchRecent(limit: Int = 100) throws -> [CorrectionHistoryRecord] {
        try dbQueue.read { db in
            try CorrectionHistoryRecord
                .order(Column("created_at").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    public func markUndone(id: String) throws {
        try dbQueue.write { db in
            guard var entry = try CorrectionHistoryRecord.fetchOne(db, key: id) else { return }
            entry.wasUndone = true
            try entry.update(db)
        }
    }

    @discardableResult
    public func deleteOlderThan(_ date: Date) throws -> Int {
        try dbQueue.write { db in
            try CorrectionHistoryRecord
                .filter(Column("created_at") < date)
                .deleteAll(db)
        }
    }
}

public final class ApplicationPolicyRepository: Sendable {
    private let dbQueue: DatabaseQueue

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func fetchAll(enabledOnly: Bool = false) throws -> [ApplicationPolicyRecord] {
        try dbQueue.read { db in
            var request = ApplicationPolicyRecord.all().order(Column("display_name"))
            if enabledOnly {
                request = request.filter(Column("enabled") == true)
            }
            return try request.fetchAll(db)
        }
    }

    public func fetch(bundleIdentifier: String) throws -> ApplicationPolicyRecord? {
        try dbQueue.read { db in
            try ApplicationPolicyRecord
                .filter(Column("bundle_identifier") == bundleIdentifier)
                .fetchOne(db)
        }
    }

    public func save(_ policy: ApplicationPolicyRecord) throws {
        try dbQueue.write { db in
            try policy.save(db)
        }
    }

    public func delete(id: String) throws {
        _ = try dbQueue.write { db in
            try ApplicationPolicyRecord.deleteOne(db, key: id)
        }
    }

    public func resolvedMode(for bundleIdentifier: String) throws -> ApplicationMode? {
        let policies = try fetchAll(enabledOnly: true)

        if let exact = policies.first(where: { $0.bundleIdentifier == bundleIdentifier }) {
            return exact.mode
        }

        return policies
            .filter { Self.matches(bundleIdentifier: bundleIdentifier, pattern: $0.bundleIdentifier) }
            .sorted { $0.bundleIdentifier.count > $1.bundleIdentifier.count }
            .first?
            .mode
    }

    private static func matches(bundleIdentifier: String, pattern: String) -> Bool {
        guard pattern.hasSuffix(".*") else { return false }
        let prefix = String(pattern.dropLast(2))
        return bundleIdentifier.hasPrefix(prefix)
    }
}

public final class SettingsRepository: Sendable {
    public static let appSettingsKey = "app_settings"

    private let dbQueue: DatabaseQueue
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func load() throws -> AppSettings {
        try dbQueue.read { db in
            guard let row = try SettingRecord.fetchOne(db, key: Self.appSettingsKey) else {
                return AppSettings()
            }
            guard let data = row.value.data(using: .utf8) else {
                return AppSettings()
            }
            return try decoder.decode(AppSettings.self, from: data)
        }
    }

    public func save(_ settings: AppSettings) throws {
        let data = try encoder.encode(settings)
        guard let value = String(data: data, encoding: .utf8) else {
            throw SettingsRepositoryError.encodingFailed
        }

        try dbQueue.write { db in
            try SettingRecord(key: Self.appSettingsKey, value: value).save(db)
        }
    }
}

public enum SettingsRepositoryError: Error {
    case encodingFailed
}

public final class CustomWordRepository: Sendable {
    private let dbQueue: DatabaseQueue

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func fetchAll(category: String? = nil) throws -> [CustomWordRecord] {
        try dbQueue.read { db in
            var request = CustomWordRecord.all().order(Column("word"))
            if let category {
                request = request.filter(Column("category") == category)
            }
            return try request.fetchAll(db)
        }
    }

    public func contains(_ word: String) throws -> Bool {
        try dbQueue.read { db in
            try CustomWordRecord
                .filter(Column("word") == word)
                .fetchCount(db) > 0
        }
    }

    public func save(_ word: CustomWordRecord) throws {
        try dbQueue.write { db in
            try word.save(db)
        }
    }

    public func delete(id: String) throws {
        _ = try dbQueue.write { db in
            try CustomWordRecord.deleteOne(db, key: id)
        }
    }
}

public final class MotorPatternRepository: Sendable {
    private let dbQueue: DatabaseQueue

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func fetchAll(patternType: String? = nil) throws -> [MotorPatternRecord] {
        try dbQueue.read { db in
            var request = MotorPatternRecord.all().order(Column("last_seen_at").desc)
            if let patternType {
                request = request.filter(Column("pattern_type") == patternType)
            }
            return try request.fetchAll(db)
        }
    }

    public func fetch(
        patternType: String,
        sourceValue: String,
        observedValue: String
    ) throws -> MotorPatternRecord? {
        try dbQueue.read { db in
            try MotorPatternRecord
                .filter(Column("pattern_type") == patternType)
                .filter(Column("source_value") == sourceValue)
                .filter(Column("observed_value") == observedValue)
                .fetchOne(db)
        }
    }

    public func save(_ pattern: MotorPatternRecord) throws {
        try dbQueue.write { db in
            try pattern.save(db)
        }
    }

    public func delete(id: String) throws {
        _ = try dbQueue.write { db in
            try MotorPatternRecord.deleteOne(db, key: id)
        }
    }
}
