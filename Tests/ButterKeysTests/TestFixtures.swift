import ButterKeysCore
import Foundation

enum TestFixtures {
    static let defaultRules: [CorrectionRuleRecord] = [
        rule("teh", "the"),
        rule("hte", "the"),
        rule("htis", "this"),
        rule("tihs", "this"),
        rule("yoru", "your"),
        rule("loosk", "looks"),
        rule("adn", "and"),
        rule("wiht", "with"),
        rule("soem", "some"),
        rule("jsut", "just"),
        phraseRule("base don", "based on"),
        phraseRule("int he", "in the", behaviour: .suggestion),
        rule("gove", "give", behaviour: .suggestion),
        rule("buidl", "build", behaviour: .suggestion),
        rule("writign", "writing", behaviour: .suggestion),
        rule("somethign", "something", behaviour: .suggestion),
        rule("workign", "working", behaviour: .suggestion),
        rule("buildign", "building", behaviour: .suggestion),
        rule("typoes", "typos", behaviour: .suggestion),
    ]

    static func ensureRulesLoaded() {
        RuleCache.shared.update(defaultRules)
    }

    static func makeLanguage(useBundledDictionary: Bool = false) -> LanguageServices {
        if useBundledDictionary {
            return LanguageServices(dictionary: LocalDictionary.loadBundled())
        }
        return LanguageServices(dictionary: fixtureDictionary(), phrases: fixturePhrases())
    }

    static func makeCoordinator(
        policy: ConfidencePolicy = ConfidencePolicy(preset: .balanced),
        useBundledDictionary: Bool = false,
        includeShortPermutation: Bool = false
    ) -> CorrectionCoordinator {
        ensureRulesLoaded()
        var strategies: [any CorrectionStrategy] = [
            ExplicitRuleStrategy(),
            AdjacentTranspositionStrategy(),
            NearbyKeySubstitutionStrategy(),
            NGGNStrategy(),
            EarlySpaceStrategy(),
            ShiftedBoundaryStrategy(),
            ExtraCharacterStrategy(),
            MissingCharacterStrategy(),
            DuplicateCharacterStrategy(),
            PhraseRuleStrategy(),
        ]
        if includeShortPermutation {
            strategies.insert(ShortPermutationStrategy(), at: 2)
        }
        return CorrectionCoordinator(
            strategies: strategies,
            language: makeLanguage(useBundledDictionary: useBundledDictionary),
            policy: policy
        )
    }

    static func fixtureDictionary() -> LocalDictionary {
        let words: Set<String> = [
            "a", "an", "and", "app", "are", "about", "based", "build", "building", "butter",
            "can", "changes", "could", "create", "else", "feature", "file", "fix", "for",
            "full", "gave", "give", "gnome", "have", "he", "here", "in", "include", "is",
            "it", "jokes", "just", "keep", "keyboard", "love", "made", "magnet", "making",
            "me", "message", "move", "new", "not", "now", "of", "on", "please", "prompt",
            "she", "should", "signature", "some", "something", "the", "there", "this",
            "title", "to", "typing", "typos", "update", "useful", "user", "we", "with",
            "word", "work", "working", "would", "wrong", "writing", "you", "i", "am",
            "wrote", "often", "change", "smooth", "automatically"
        ]

        var frequencies: [String: Double] = [:]
        for word in words {
            frequencies[word] = preferredFrequencies[word] ?? 0.01
        }

        return LocalDictionary(words: words, frequencies: frequencies)
    }

    static func fixturePhrases() -> PhraseFrequencyStore {
        PhraseFrequencyStore(phrases: [
            "give me": 1.0,
            "give this": 0.6,
            "give it": 0.7,
            "in the": 1.0,
            "for the": 0.9,
            "with the": 0.8,
            "based on": 0.7,
            "typing this": 0.4,
            "building a": 0.5,
        ])
    }

    private static let preferredFrequencies: [String: Double] = [
        "the": 100, "this": 80, "some": 90, "just": 85, "give": 70, "build": 60,
        "writing": 55, "something": 50, "building": 45, "typos": 20, "typing": 40,
        "in": 95, "for": 90, "with": 88, "love": 30, "move": 25, "gave": 25,
        "gnome": 15, "signature": 20, "magnet": 15, "she": 0.01, "a": 50, "he": 40
    ]

    private static func rule(
        _ source: String,
        _ replacement: String,
        behaviour: RuleBehaviour = .automatic
    ) -> CorrectionRuleRecord {
        CorrectionRuleRecord(
            source: source,
            replacement: replacement,
            matchType: .word,
            behaviour: behaviour
        )
    }

    private static func phraseRule(
        _ source: String,
        _ replacement: String,
        behaviour: RuleBehaviour = .automatic
    ) -> CorrectionRuleRecord {
        CorrectionRuleRecord(
            source: source,
            replacement: replacement,
            matchType: .phrase,
            behaviour: behaviour
        )
    }
}
