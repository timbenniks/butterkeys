import ButterKeysCore
import Foundation
import GRDB
import Testing

@Suite("Database migration")
struct DatabaseMigrationTests {
    private func makeTempDatabase(seedDefaults: Bool = true) throws -> (DatabaseManager, URL) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("butterkeys-test-\(UUID().uuidString).sqlite")
        let database = try DatabaseManager(path: tempURL.path)

        // DatabaseManager migrates + SeedDefaults.seedIfNeeded on open.
        // For schema-only tests, pass seedDefaults: false and use an empty migrated DB —
        // but seed already ran. Re-open after wiping is awkward; use a separate path below.
        if !seedDefaults {
            // Open without relying on seeded content: delete rows for schema checks only.
            try database.dbQueue.write { db in
                try db.execute(sql: "DELETE FROM correction_rules")
                try db.execute(sql: "DELETE FROM application_policies")
            }
        }

        return (database, tempURL)
    }

    @Test("Open temp DB, migrate, seed, and fetch rules")
    func migrateSeedAndFetch() throws {
        let (database, tempURL) = try makeTempDatabase()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let rules = try CorrectionRuleRepository(dbQueue: database.dbQueue).fetchAll()
        let policies = try ApplicationPolicyRepository(dbQueue: database.dbQueue).fetchAll()

        #expect(!rules.isEmpty)
        #expect(rules.contains { $0.source == "teh" && $0.replacement == "the" })
        #expect(rules.contains { $0.source == "soem" && $0.replacement == "some" })
        #expect(rules.contains { $0.source == "jsut" && $0.replacement == "just" })
        #expect(rules.allSatisfy { $0.enabled })

        #expect(!policies.isEmpty)
        #expect(policies.contains { $0.bundleIdentifier == "com.apple.Notes" && $0.mode == .prose })
        #expect(policies.contains { $0.bundleIdentifier == "com.apple.dt.Xcode" && $0.mode == .codeSafe })
    }

    @Test("Migration creates schema on empty database")
    func migrationCreatesSchema() throws {
        let (database, tempURL) = try makeTempDatabase(seedDefaults: false)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let hasRules = try database.dbQueue.read { try $0.tableExists("correction_rules") }
        let hasLearned = try database.dbQueue.read { try $0.tableExists("learned_patterns") }
        let hasPolicies = try database.dbQueue.read { try $0.tableExists("application_policies") }
        let hasSettings = try database.dbQueue.read { try $0.tableExists("settings") }

        #expect(hasRules)
        #expect(hasLearned)
        #expect(hasPolicies)
        #expect(hasSettings)
    }

    @Test("Migration is idempotent")
    func idempotentMigration() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("butterkeys-test-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let first = try DatabaseManager(path: tempURL.path)
        let firstCount = try CorrectionRuleRepository(dbQueue: first.dbQueue).fetchAll().count

        let second = try DatabaseManager(path: tempURL.path)
        let secondCount = try CorrectionRuleRepository(dbQueue: second.dbQueue).fetchAll().count

        #expect(firstCount == secondCount)
        #expect(firstCount > 0)
    }

    @Test("Resolved application mode from seeded policies")
    func resolvedApplicationMode() throws {
        let (database, tempURL) = try makeTempDatabase()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let repository = ApplicationPolicyRepository(dbQueue: database.dbQueue)

        #expect(try repository.resolvedMode(for: "com.apple.Notes") == .prose)
        #expect(try repository.resolvedMode(for: "com.apple.dt.Xcode") == .codeSafe)
        #expect(try repository.resolvedMode(for: "com.jetbrains.AppCode") == .codeSafe)
    }
}
