import Foundation
import GRDB

public enum DatabaseMigrator {
    public static func migrate(_ dbQueue: DatabaseQueue) throws {
        var migrator = GRDB.DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "correction_rules") { table in
                table.column("id", .text).primaryKey()
                table.column("source", .text).notNull()
                table.column("replacement", .text).notNull()
                table.column("match_type", .text).notNull()
                table.column("preserve_case", .boolean).notNull().defaults(to: true)
                table.column("case_sensitive", .boolean).notNull().defaults(to: false)
                table.column("app_bundle_id", .text)
                table.column("application_mode", .text)
                table.column("behaviour", .text).notNull()
                table.column("enabled", .boolean).notNull().defaults(to: true)
                table.column("created_at", .datetime).notNull()
                table.column("updated_at", .datetime).notNull()
            }

            try db.create(table: "learned_patterns") { table in
                table.column("id", .text).primaryKey()
                table.column("source", .text).notNull()
                table.column("replacement", .text).notNull()
                table.column("pattern_type", .text).notNull()
                table.column("observed_count", .integer).notNull().defaults(to: 0)
                table.column("accepted_count", .integer).notNull().defaults(to: 0)
                table.column("undo_count", .integer).notNull().defaults(to: 0)
                table.column("confidence", .double).notNull().defaults(to: 0)
                table.column("app_bundle_id", .text)
                table.column("status", .text).notNull()
                table.column("first_seen_at", .datetime).notNull()
                table.column("last_seen_at", .datetime).notNull()
            }

            try db.create(table: "motor_patterns") { table in
                table.column("id", .text).primaryKey()
                table.column("pattern_type", .text).notNull()
                table.column("source_value", .text).notNull()
                table.column("observed_value", .text).notNull()
                table.column("occurrence_count", .integer).notNull().defaults(to: 0)
                table.column("confidence", .double).notNull().defaults(to: 0)
                table.column("first_seen_at", .datetime).notNull()
                table.column("last_seen_at", .datetime).notNull()
            }

            try db.create(table: "correction_history") { table in
                table.column("id", .text).primaryKey()
                table.column("source", .text).notNull()
                table.column("replacement", .text).notNull()
                table.column("correction_type", .text).notNull()
                table.column("app_bundle_id", .text)
                table.column("confidence", .double).notNull()
                table.column("was_undone", .boolean).notNull().defaults(to: false)
                table.column("created_at", .datetime).notNull()
            }

            try db.create(table: "application_policies") { table in
                table.column("id", .text).primaryKey()
                table.column("bundle_identifier", .text).notNull().unique()
                table.column("display_name", .text)
                table.column("mode", .text).notNull()
                table.column("enabled", .boolean).notNull().defaults(to: true)
                table.column("created_at", .datetime).notNull()
                table.column("updated_at", .datetime).notNull()
            }

            try db.create(table: "custom_words") { table in
                table.column("id", .text).primaryKey()
                table.column("word", .text).notNull().unique()
                table.column("category", .text).notNull()
                table.column("created_at", .datetime).notNull()
            }

            try db.create(table: "settings") { table in
                table.column("key", .text).primaryKey()
                table.column("value", .text).notNull()
            }
        }

        migrator.registerMigration("v2_code_safe_ides") { db in
            let codingBundleIDs = [
                "com.microsoft.VSCode",
                "com.todesktop.230313mzl4w4u92",
                "com.apple.dt.Xcode",
                "com.jetbrains.*"
            ]
            let now = Date()
            for bundleID in codingBundleIDs {
                if var policy = try ApplicationPolicyRecord
                    .filter(Column("bundle_identifier") == bundleID)
                    .fetchOne(db) {
                    policy.mode = .codeSafe
                    policy.updatedAt = now
                    try policy.update(db)
                } else {
                    let name: String = switch bundleID {
                    case "com.microsoft.VSCode": "Visual Studio Code"
                    case "com.todesktop.230313mzl4w4u92": "Cursor"
                    case "com.apple.dt.Xcode": "Xcode"
                    case "com.jetbrains.*": "JetBrains IDEs"
                    default: bundleID
                    }
                    try ApplicationPolicyRecord(
                        bundleIdentifier: bundleID,
                        displayName: name,
                        mode: .codeSafe,
                        createdAt: now,
                        updatedAt: now
                    ).insert(db)
                }
            }
        }

        try migrator.migrate(dbQueue)
    }
}
