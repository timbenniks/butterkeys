import ButterKeysCore
import Testing

@Suite("Conservative short-token corrections")
struct ShortTokenSafetyTests {
    private var coordinator: CorrectionCoordinator {
        TestFixtures.ensureRulesLoaded()
        let language = LanguageServices(dictionary: LocalDictionary.loadBundled())
        return CorrectionCoordinator(
            language: language,
            policy: ConfidencePolicy(preset: .balanced)
        )
    }

    @Test("Dutch short words are not auto-corrected", arguments: [
        ("met", "me"),
        ("kan", "an"),
        ("nog", "not"),
        ("soms", "does"),
        ("ring", "being"),
    ])
    func dutchShortWordsUntouched(original: String, wrongReplacement: String) {
        let context = CorrectionTestSupport.context(
            tokens: [original],
            currentToken: original,
            applicationMode: .prose
        )
        let candidate = coordinator.evaluate(context)
        #expect(candidate == nil || candidate?.replacement.lowercased() != wrongReplacement)
        #expect(candidate == nil || candidate?.original.lowercased() != original.lowercased() || candidate?.strategyID == ExplicitRuleStrategy.id)
        // Stronger: no automatic correction of these tokens at all.
        if let candidate, candidate.original.lowercased() == original.lowercased() {
            Issue.record("Unexpected automatic correction \(candidate.original) → \(candidate.replacement) via \(candidate.strategyID)")
        }
        #expect(candidate == nil || candidate?.original.lowercased() != original.lowercased())
    }

    @Test("teh still corrects via explicit/transposition path")
    func tehStillWorks() {
        let context = CorrectionTestSupport.context(tokens: ["teh"], currentToken: "teh")
        let candidate = coordinator.evaluate(context)
        #expect(candidate?.replacement.lowercased() == "the")
    }

    @Test("writigg can correct in code-safe mode")
    func writiggInCodeSafe() {
        let context = CorrectionTestSupport.context(
            tokens: ["writigg"],
            currentToken: "writigg",
            applicationMode: .codeSafe
        )
        let candidates = coordinator.candidates(for: context)
        #expect(candidates.contains { $0.replacement.lowercased() == "writing" })
        let automatic = coordinator.evaluate(context)
        #expect(automatic?.replacement.lowercased() == "writing")
    }

    @Test("thing is never auto-corrected to typing")
    func thingStaysThing() {
        for mode in [ApplicationMode.prose, .codeSafe] {
            let context = CorrectionTestSupport.context(
                tokens: ["thing"],
                currentToken: "thing",
                applicationMode: mode
            )
            let automatic = coordinator.evaluate(context)
            #expect(automatic == nil || automatic?.replacement.lowercased() == "thing")
            if let automatic {
                Issue.record("Unexpected \(mode): \(automatic.original) → \(automatic.replacement) via \(automatic.strategyID)")
            }
        }
    }

    @Test("Protected custom words are never corrected")
    func protectedCustomWord() {
        let base = LocalDictionary.loadBundled()
        let language = LanguageServices(
            dictionary: base.withCustom(never: ["soms"], names: [], extra: [])
        )
        let coordinator = CorrectionCoordinator(
            language: language,
            policy: ConfidencePolicy(preset: .balanced)
        )
        let context = CorrectionTestSupport.context(
            tokens: ["soms"],
            currentToken: "soms",
            applicationMode: .prose
        )
        #expect(coordinator.evaluate(context) == nil)
    }

    @Test("Taught-only skips speculative short-token guesses")
    func taughtOnlySkipsSpeculative() {
        TestFixtures.ensureRulesLoaded()
        let language = LanguageServices(dictionary: LocalDictionary.loadBundled())
        let taught = CorrectionCoordinator(
            language: language,
            policy: ConfidencePolicy(preset: .taughtOnly)
        )
        let context = CorrectionTestSupport.context(
            tokens: ["writigg"],
            currentToken: "writigg",
            applicationMode: .codeSafe
        )
        #expect(taught.evaluate(context) == nil)
    }
}
