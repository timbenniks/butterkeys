import ButterKeysCore
import Testing

@Suite("Confidence policy")
struct ConfidencePolicyTests {
    @Test("Taught-only preset thresholds")
    func taughtOnlyPreset() {
        let policy = ConfidencePolicy(preset: .taughtOnly)
        #expect(policy.automaticThreshold == 0.90)
        #expect(policy.suggestionThreshold == 0.90)
        #expect(policy.allowsSpeculativeStrategies == false)
    }

    @Test("Balanced preset thresholds")
    func balancedPreset() {
        let policy = ConfidencePolicy(preset: .balanced)
        #expect(policy.automaticThreshold == 0.85)
        #expect(policy.suggestionThreshold == 0.60)
        #expect(policy.allowsSpeculativeStrategies == true)
    }

    @Test("Conservative preset thresholds")
    func conservativePreset() {
        let policy = ConfidencePolicy(preset: .conservative)
        #expect(policy.automaticThreshold == 0.92)
        #expect(policy.suggestionThreshold == 0.70)
    }

    @Test("Enthusiastic preset thresholds")
    func enthusiasticPreset() {
        let policy = ConfidencePolicy(preset: .enthusiastic)
        #expect(policy.automaticThreshold == 0.78)
        #expect(policy.suggestionThreshold == 0.55)
    }

    @Test("Decision boundaries", arguments: [
        (0.95, false, CorrectionAction.automatic),
        (0.85, false, CorrectionAction.automatic),
        (0.84, false, CorrectionAction.suggest),
        (0.60, false, CorrectionAction.suggest),
        (0.59, false, CorrectionAction.ignore),
        (0.95, true, CorrectionAction.suggest),
    ])
    func decisionBoundaries(confidence: Double, suggestionOnly: Bool, expected: CorrectionAction) {
        let policy = ConfidencePolicy(preset: .balanced)
        #expect(policy.decision(for: confidence, suggestionOnly: suggestionOnly) == expected)
    }

    @Test("Coordinator respects automatic threshold")
    func coordinatorThreshold() {
        let language = CorrectionTestSupport.makeLanguage()
        let conservative = CorrectionTestSupport.makeCoordinator(
            language: language,
            policy: ConfidencePolicy(preset: .conservative)
        )
        let enthusiastic = CorrectionTestSupport.makeCoordinator(
            language: language,
            policy: ConfidencePolicy(preset: .enthusiastic)
        )

        let context = CorrectionTestSupport.context(tokens: ["teh"], currentToken: "teh")

        #expect(conservative.evaluate(context)?.replacement == "the")
        #expect(enthusiastic.evaluate(context)?.replacement == "the")

        // Enthusiastic auto-threshold is lower; a solid candidate should clear it.
        let mediumConfidenceContext = CorrectionTestSupport.context(
            tokens: ["gove", "me"],
            currentToken: "gove",
            previousToken: "Please",
            phraseFragment: "Please gove me"
        )
        let candidates = enthusiastic.candidates(for: mediumConfidenceContext)
        if let top = candidates.first(where: { $0.replacement == "give" }) {
            #expect(top.confidence >= ConfidencePreset.enthusiastic.automaticThreshold)
            #expect(enthusiastic.action(for: top) == .automatic)
        }
    }

    @Test("Settings migrate onto teach-first defaults once")
    func settingsMigration() {
        var settings = AppSettings()
        settings.settingsSchemaVersion = 0
        settings.confidencePreset = .balanced
        #expect(settings.migrateIfNeeded() == true)
        #expect(settings.confidencePreset == .taughtOnly)
        #expect(settings.settingsSchemaVersion == 1)
        #expect(settings.migrateIfNeeded() == false)
    }
}
