import ButterKeysCore
import Testing

@Suite("Explicit rules", .serialized)
struct ExplicitRuleTests {
    private let language = CorrectionTestSupport.makeLanguage()
    private let strategy = ExplicitRuleStrategy()

    @Test("RuleCache loads bundled or fixture default rules")
    func ruleCacheLoadsDefaults() {
        TestFixtures.ensureRulesLoaded()
        let rules = RuleCache.shared.rules
        #expect(!rules.isEmpty)
        #expect(rules.contains { $0.source == "teh" && $0.replacement == "the" })
        #expect(rules.contains { $0.source == "soem" && $0.replacement == "some" })
    }

    @Test("teh → the via ExplicitRuleStrategy")
    func tehToThe() {
        let context = CorrectionTestSupport.context(
            tokens: ["teh"],
            currentToken: "teh"
        )
        let candidates = strategy.candidates(for: context, language: language)
        #expect(candidates.contains { $0.replacement == "the" && $0.strategyID == ExplicitRuleStrategy.id })

        let coordinator = CorrectionTestSupport.makeCoordinator(language: language)
        let automatic = coordinator.evaluate(context)
        #expect(automatic?.replacement == "the")
        #expect(automatic != nil)
    }

    @Test("Phrase explicit rules match full phrase")
    func phraseRules() {
        let context = CorrectionTestSupport.context(
            tokens: ["base", "don"],
            currentToken: "don",
            previousToken: "base",
            phraseFragment: "base don"
        )
        let candidates = strategy.candidates(for: context, language: language)
        #expect(candidates.contains { $0.original == "base don" && $0.replacement == "based on" })
    }

    @Test("Default explicit rules are globally scoped")
    func globalScopeRules() {
        TestFixtures.ensureRulesLoaded()
        let rules = RuleCache.shared.rules.filter { $0.source == "teh" || $0.source == "soem" }
        #expect(!rules.isEmpty)
        #expect(rules.allSatisfy { $0.appBundleID == nil })
    }

    @Test("Suggestion-only explicit rules stay in candidate list")
    func suggestionOnlyRules() {
        TestFixtures.ensureRulesLoaded()
        let context = CorrectionTestSupport.context(tokens: ["gove"], currentToken: "gove")
        let candidates = strategy.candidates(for: context, language: language)
        let explicit = candidates.first { $0.strategyID == ExplicitRuleStrategy.id && $0.replacement == "give" }
        #expect(explicit != nil)
        #expect(explicit?.suggestionOnly == true)
    }
}
