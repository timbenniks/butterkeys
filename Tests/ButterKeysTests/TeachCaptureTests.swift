import ButterKeysCore
import Testing

@Suite("Teach capture")
struct TeachCaptureTests {
    @Test("Builds a word rule from a typo pair")
    func wordRule() {
        let rule = TeachCapture.makeRule(source: " writign ", replacement: "writing")
        #expect(rule?.source == "writign")
        #expect(rule?.replacement == "writing")
        #expect(rule?.matchType == .word)
        #expect(rule?.behaviour == .automatic)
    }

    @Test("Builds a phrase rule when the source has spaces")
    func phraseRule() {
        let rule = TeachCapture.makeRule(source: "int he", replacement: "in the")
        #expect(rule?.matchType == .phrase)
        #expect(rule?.source == "int he")
        #expect(rule?.replacement == "in the")
    }

    @Test("Rejects identical pairs and empty input")
    func rejectsInvalid() {
        #expect(TeachCapture.makeRule(source: "the", replacement: "the") == nil)
        #expect(TeachCapture.makeRule(source: "", replacement: "the") == nil)
        #expect(TeachCapture.makeRule(source: "teh", replacement: "") == nil)
        #expect(TeachCapture.makeRule(source: "has space!!", replacement: "clean") == nil)
    }
}

@Suite("Taught-only policy")
struct TaughtOnlyPolicyTests {
    @Test("Taught-only mode only auto-applies explicit rules")
    func taughtOnlyIgnoresSpeculative() {
        TestFixtures.ensureRulesLoaded()
        let taught = CorrectionTestSupport.makeCoordinator(
            policy: ConfidencePolicy(preset: .taughtOnly)
        )
        let balanced = CorrectionTestSupport.makeCoordinator(
            policy: ConfidencePolicy(preset: .balanced),
            includeShortPermutation: true
        )

        // Seeded explicit rule still works.
        let teh = CorrectionTestSupport.context(tokens: ["teh"], currentToken: "teh")
        #expect(taught.evaluate(teh)?.replacement == "the")
        #expect(taught.evaluate(teh)?.strategyID == ExplicitRuleStrategy.id)

        // Speculative permutation should not fire in taught-only.
        let speculative = CorrectionTestSupport.context(
            tokens: ["wirting"],
            currentToken: "wirting"
        )
        #expect(taught.evaluate(speculative) == nil)

        // Balanced may still propose something for motor-pattern typos with dictionary help.
        let balancedCandidates = balanced.candidates(for: speculative)
        #expect(!balancedCandidates.isEmpty || balanced.evaluate(speculative) == nil)
    }

    @Test("Taught-only preset disables speculative strategies")
    func presetFlag() {
        #expect(ConfidencePreset.taughtOnly.allowsSpeculativeStrategies == false)
        #expect(ConfidencePreset.balanced.allowsSpeculativeStrategies == true)
        #expect(ConfidencePolicy(preset: .taughtOnly).allowsSpeculativeStrategies == false)
    }
}
