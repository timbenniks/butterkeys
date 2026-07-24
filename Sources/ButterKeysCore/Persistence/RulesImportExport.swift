import Foundation

public struct ButterKeysExportDocument: Codable, Sendable {
    public var formatVersion: Int
    public var rules: [ExportRule]
    public var customWords: [ExportCustomWord]
    public var applicationPolicies: [ExportAppPolicy]
    public var learnedPatterns: [ExportLearnedPattern]

    public init(
        formatVersion: Int = 1,
        rules: [ExportRule] = [],
        customWords: [ExportCustomWord] = [],
        applicationPolicies: [ExportAppPolicy] = [],
        learnedPatterns: [ExportLearnedPattern] = []
    ) {
        self.formatVersion = formatVersion
        self.rules = rules
        self.customWords = customWords
        self.applicationPolicies = applicationPolicies
        self.learnedPatterns = learnedPatterns
    }
}

public struct ExportRule: Codable, Sendable {
    public var source: String
    public var replacement: String
    public var mode: String
    public var scope: String
    public var matchType: String

    public init(source: String, replacement: String, mode: String, scope: String = "global", matchType: String = "word") {
        self.source = source
        self.replacement = replacement
        self.mode = mode
        self.scope = scope
        self.matchType = matchType
    }
}

public struct ExportCustomWord: Codable, Sendable {
    public var word: String
    public var category: String
}

public struct ExportAppPolicy: Codable, Sendable {
    public var bundleIdentifier: String
    public var displayName: String?
    public var mode: String
}

public struct ExportLearnedPattern: Codable, Sendable {
    public var source: String
    public var replacement: String
    public var patternType: String
    public var status: String
}

public enum RulesImportExport {
    public static func export(
        rules: [CorrectionRuleRecord],
        customWords: [CustomWordRecord] = [],
        policies: [ApplicationPolicyRecord] = [],
        learned: [LearnedPatternRecord] = [],
        includeLearned: Bool = true
    ) throws -> Data {
        let document = ButterKeysExportDocument(
            rules: rules.map {
                ExportRule(
                    source: $0.source,
                    replacement: $0.replacement,
                    mode: $0.behaviour.rawValue,
                    scope: $0.appBundleID ?? "global",
                    matchType: $0.matchType.rawValue
                )
            },
            customWords: customWords.map { ExportCustomWord(word: $0.word, category: $0.category) },
            applicationPolicies: policies.map {
                ExportAppPolicy(
                    bundleIdentifier: $0.bundleIdentifier,
                    displayName: $0.displayName,
                    mode: $0.mode.rawValue
                )
            },
            learnedPatterns: includeLearned
                ? learned.map {
                    ExportLearnedPattern(
                        source: $0.source,
                        replacement: $0.replacement,
                        patternType: $0.patternType,
                        status: $0.status
                    )
                }
                : []
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(document)
    }

    public static func importDocument(from data: Data) throws -> ButterKeysExportDocument {
        let decoder = JSONDecoder()
        let document = try decoder.decode(ButterKeysExportDocument.self, from: data)
        guard document.formatVersion == 1 else {
            throw ImportError.unsupportedVersion(document.formatVersion)
        }
        for rule in document.rules {
            guard !rule.source.isEmpty, !rule.replacement.isEmpty else {
                throw ImportError.malformed("Empty rule source or replacement")
            }
        }
        return document
    }

    public enum ImportError: Error, LocalizedError {
        case unsupportedVersion(Int)
        case malformed(String)

        public var errorDescription: String? {
            switch self {
            case .unsupportedVersion(let v): "Unsupported export format version \(v)"
            case .malformed(let message): message
            }
        }
    }
}
