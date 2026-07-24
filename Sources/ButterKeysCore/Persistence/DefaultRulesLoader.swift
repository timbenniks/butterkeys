import Foundation

enum DefaultRulesLoader {
    struct Seed: Decodable {
        let source: String
        let replacement: String
        let matchType: MatchType
        let behaviour: RuleBehaviour
    }

    static func loadRecords(createdAt: Date = Date()) -> [CorrectionRuleRecord] {
        guard let url = ButterKeysResources.url(forResource: "DefaultRules", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let seeds = try? JSONDecoder().decode([Seed].self, from: data)
        else { return [] }

        return seeds.map { seed in
            CorrectionRuleRecord(
                source: seed.source,
                replacement: seed.replacement,
                matchType: seed.matchType,
                behaviour: seed.behaviour,
                createdAt: createdAt,
                updatedAt: createdAt
            )
        }
    }
}

enum ButterKeysResources {
    private final class Token {}

    static var bundle: Bundle {
        Bundle(for: Token.self)
    }

    static func url(forResource name: String, withExtension ext: String) -> URL? {
        if let url = bundle.url(forResource: name, withExtension: ext) {
            return url
        }
        for subdirectory in ["Dictionary", "PhraseData"] {
            if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
                return url
            }
        }
        return nil
    }
}
