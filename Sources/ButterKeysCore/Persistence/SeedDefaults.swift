import Foundation
import GRDB

enum SeedDefaults {
    static func seedIfNeeded(dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            let ruleCount = try CorrectionRuleRecord.fetchCount(db)
            if ruleCount == 0 {
                try seedRules(db)
            }

            let policyCount = try ApplicationPolicyRecord.fetchCount(db)
            if policyCount == 0 {
                try seedApplicationPolicies(db)
            } else {
                // Migrations (e.g. v2) may insert IDE policies before first seed.
                // Ensure prose / disabled defaults still land on a fresh database.
                try ensureMissingDefaultPolicies(db)
            }
        }
    }

    private static func seedRules(_ db: Database) throws {
        let now = Date()
        let rules = DefaultRulesLoader.loadRecords(createdAt: now)
        guard !rules.isEmpty else {
            // Bundle resource missing — fall back so tests / first launch still work.
            for rule in fallbackRules(createdAt: now) {
                try rule.insert(db)
            }
            return
        }
        for rule in rules {
            try rule.insert(db)
        }
    }

    private static func fallbackRules(createdAt: Date) -> [CorrectionRuleRecord] {
        [
            ("teh", "the"),
            ("soem", "some"),
            ("jsut", "just"),
            ("htis", "this"),
            ("taht", "that"),
            ("adn", "and"),
            ("becuase", "because"),
            ("writign", "writing"),
        ].map {
            CorrectionRuleRecord(
                source: $0.0,
                replacement: $0.1,
                matchType: .word,
                behaviour: .automatic,
                createdAt: createdAt,
                updatedAt: createdAt
            )
        }
    }

    private static func seedApplicationPolicies(_ db: Database) throws {
        let now = Date()
        for policy in defaultPolicies(createdAt: now) {
            try policy.insert(db)
        }
    }

    private static func ensureMissingDefaultPolicies(_ db: Database) throws {
        let now = Date()
        let existing = Set(
            try ApplicationPolicyRecord.fetchAll(db).map(\.bundleIdentifier)
        )
        for policy in defaultPolicies(createdAt: now) where !existing.contains(policy.bundleIdentifier) {
            try policy.insert(db)
        }
    }

    private static func defaultPolicies(createdAt: Date) -> [ApplicationPolicyRecord] {
        let disabledPolicies: [(String, String)] = [
            ("com.apple.Terminal", "Terminal"),
            ("com.googlecode.iterm2", "iTerm"),
            ("dev.warp.Warp-Stable", "Warp"),
            ("com.1password.1password", "1Password"),
            ("com.agilebits.onepassword7", "1Password 7"),
            ("com.apple.keychainaccess", "Keychain Access"),
            ("com.github.wez.wezterm", "WezTerm"),
            ("net.kovidgoyal.kitty", "kitty"),
            ("com.parallels.desktop.console", "Parallels Desktop"),
            ("com.vmware.fusion", "VMware Fusion"),
            ("com.microsoft.rdc.macos", "Microsoft Remote Desktop"),
        ]

        let codeSafePolicies: [(String, String)] = [
            ("com.microsoft.VSCode", "Visual Studio Code"),
            ("com.todesktop.230313mzl4w4u92", "Cursor"),
            ("com.apple.dt.Xcode", "Xcode"),
            ("com.jetbrains.*", "JetBrains IDEs"),
        ]

        let prosePolicies: [(String, String)] = [
            ("com.apple.mail", "Mail"),
            ("com.apple.MobileSMS", "Messages"),
            ("com.apple.Notes", "Notes"),
            ("com.apple.Safari", "Safari"),
            ("com.tinyspeck.slackmacgap", "Slack"),
        ]

        var records: [ApplicationPolicyRecord] = []
        for (bundleID, name) in disabledPolicies {
            records.append(
                ApplicationPolicyRecord(
                    bundleIdentifier: bundleID,
                    displayName: name,
                    mode: .disabled,
                    createdAt: createdAt,
                    updatedAt: createdAt
                )
            )
        }
        for (bundleID, name) in codeSafePolicies {
            records.append(
                ApplicationPolicyRecord(
                    bundleIdentifier: bundleID,
                    displayName: name,
                    mode: .codeSafe,
                    createdAt: createdAt,
                    updatedAt: createdAt
                )
            )
        }
        for (bundleID, name) in prosePolicies {
            records.append(
                ApplicationPolicyRecord(
                    bundleIdentifier: bundleID,
                    displayName: name,
                    mode: .prose,
                    createdAt: createdAt,
                    updatedAt: createdAt
                )
            )
        }
        return records
    }
}
