import Foundation

public final class CorrectionCoordinator: @unchecked Sendable {
    private let strategies: [any CorrectionStrategy]
    private let scorer: CandidateScorer
    private var policy: ConfidencePolicy
    private var language: LanguageServices
    private var explicitRules: [CorrectionRuleRecord]
    private var learnedBoosts: [String: Double]
    private var undoPenalties: [String: Double]

    /// Strategies allowed in code editors — motor-pattern fixes without aggressive dictionary swaps.
    private static let codeSafeStrategyIDs: Set<String> = [
        ExplicitRuleStrategy.id,
        AdjacentTranspositionStrategy.id,
        ShortPermutationStrategy.id,
        NGGNStrategy.id,
        DuplicateCharacterStrategy.id,
        ExtraCharacterStrategy.id,
        MissingCharacterStrategy.id
    ]

    /// Strategies safe on short tokens. Others often mangle foreign/short words (met→me, kan→an).
    private static let shortTokenStrategyIDs: Set<String> = [
        ExplicitRuleStrategy.id,
        AdjacentTranspositionStrategy.id,
        PhraseRuleStrategy.id,
        DuplicateCharacterStrategy.id
    ]

    /// Known dictionary words may only be changed by these (never ShortPermutation → typing).
    private static let knownWordStrategyIDs: Set<String> = [
        ExplicitRuleStrategy.id,
        AdjacentTranspositionStrategy.id,
        PhraseRuleStrategy.id
    ]

    public init(
        strategies: [any CorrectionStrategy]? = nil,
        language: LanguageServices,
        policy: ConfidencePolicy = ConfidencePolicy(),
        explicitRules: [CorrectionRuleRecord] = []
    ) {
        self.strategies = strategies ?? Self.defaultStrategies()
        self.scorer = CandidateScorer()
        self.policy = policy
        self.language = language
        self.explicitRules = explicitRules
        self.learnedBoosts = [:]
        self.undoPenalties = [:]
    }

    public func updatePolicy(_ policy: ConfidencePolicy) { self.policy = policy }
    public func updateLanguage(_ language: LanguageServices) { self.language = language }
    public func updateRules(_ rules: [CorrectionRuleRecord]) { explicitRules = rules }
    public func setLearnedBoost(source: String, replacement: String, boost: Double) {
        learnedBoosts[pairKey(source, replacement)] = boost
    }
    public func setUndoPenalty(source: String, replacement: String, penalty: Double) {
        undoPenalties[pairKey(source, replacement)] = penalty
    }

    public static func defaultStrategies() -> [any CorrectionStrategy] {
        [
            ExplicitRuleStrategy(),
            AdjacentTranspositionStrategy(),
            ShortPermutationStrategy(),
            NearbyKeySubstitutionStrategy(),
            NGGNStrategy(),
            EarlySpaceStrategy(),
            ShiftedBoundaryStrategy(),
            ExtraCharacterStrategy(),
            MissingCharacterStrategy(),
            DuplicateCharacterStrategy(),
            PhraseRuleStrategy()
        ]
    }

    public func evaluate(_ context: CorrectionContext) -> CorrectionCandidate? {
        switch context.applicationMode {
        case .disabled: return nil
        case .plainText:
            return best(
                from: candidates(for: context).filter {
                    $0.strategyID == ExplicitRuleStrategy.id || $0.confidence >= 0.95
                },
                context: context
            )
        case .codeSafe:
            return best(
                from: candidates(for: context).filter { Self.codeSafeStrategyIDs.contains($0.strategyID) },
                context: context
            )
        case .prose, .custom:
            return best(from: candidates(for: context), context: context)
        }
    }

    public func candidates(for context: CorrectionContext) -> [CorrectionCandidate] {
        var generated: [CorrectionCandidate] = []

        for strategy in strategies {
            if !policy.allowsSpeculativeStrategies,
               strategy.identifier != ExplicitRuleStrategy.id {
                continue
            }
            if context.applicationMode == .codeSafe,
               !Self.codeSafeStrategyIDs.contains(strategy.identifier) {
                continue
            }
            if context.applicationMode == .plainText,
               strategy.identifier != ExplicitRuleStrategy.id {
                continue
            }

            let raw = strategy.candidates(for: context, language: language)
            for candidate in raw {
                let key = pairKey(candidate.original, candidate.replacement)
                let boosted = CorrectionCandidate(
                    original: candidate.original,
                    replacement: CasePatternPreserver.apply(pattern: candidate.original, to: candidate.replacement),
                    affectedRange: candidate.affectedRange,
                    strategyID: candidate.strategyID,
                    confidence: clamp(
                        candidate.confidence
                            + (learnedBoosts[key] ?? 0)
                            - (undoPenalties[key] ?? 0)
                    ),
                    explanation: candidate.explanation,
                    requiresBoundary: candidate.requiresBoundary,
                    suggestionOnly: candidate.suggestionOnly || explicitSuggestionOnly(candidate)
                )
                generated.append(boosted)
            }
        }

        var bestByReplacement: [String: CorrectionCandidate] = [:]
        for candidate in generated {
            let key = candidate.replacement.lowercased()
            if let existing = bestByReplacement[key] {
                if candidate.confidence > existing.confidence {
                    bestByReplacement[key] = candidate
                }
            } else {
                bestByReplacement[key] = candidate
            }
        }
        return bestByReplacement.values.sorted { $0.confidence > $1.confidence }
    }

    public func action(for candidate: CorrectionCandidate) -> CorrectionAction {
        policy.decision(for: candidate.confidence, suggestionOnly: candidate.suggestionOnly)
    }

    private func best(from list: [CorrectionCandidate], context: CorrectionContext) -> CorrectionCandidate? {
        let filtered = list.filter { isSafeAutomaticCandidate($0, context: context) }
        guard let top = filtered.max(by: { $0.confidence < $1.confidence }) else { return nil }
        switch action(for: top) {
        case .automatic: return top
        case .suggest, .ignore: return nil
        }
    }

    /// Blocks aggressive dictionary swaps on short / likely-foreign tokens (Dutch "met", "kan", "nog", …).
    private func isSafeAutomaticCandidate(_ candidate: CorrectionCandidate, context: CorrectionContext) -> Bool {
        let original = candidate.original
        let lower = original.lowercased()
        let replacement = candidate.replacement.lowercased()

        if language.dictionary.shouldNeverCorrect(lower) {
            return false
        }

        // Known words stay put unless the strategy is a tight motor fix / explicit rule.
        // Prevents thing→typing via short-permutation / missing-character dictionary fishing.
        if language.dictionary.contains(lower),
           !Self.knownWordStrategyIDs.contains(candidate.strategyID) {
            return false
        }

        // Never "upgrade" to a less frequent word when the original is already valid.
        if language.dictionary.contains(lower),
           language.dictionary.contains(replacement),
           language.dictionary.frequency(replacement) < language.dictionary.frequency(lower),
           candidate.strategyID != ExplicitRuleStrategy.id {
            return false
        }

        // Short unknown tokens are often other languages — only allow safe strategies.
        if lower.count <= 4,
           !language.dictionary.contains(lower),
           !Self.shortTokenStrategyIDs.contains(candidate.strategyID) {
            return false
        }

        // Extra-character on short words ("met"→"me", "kan"→"an") is a common false positive.
        if candidate.strategyID == ExtraCharacterStrategy.id, lower.count <= 4 {
            return false
        }

        // Missing-character expanding short tokens ("ring"→"being") is similarly aggressive.
        if candidate.strategyID == MissingCharacterStrategy.id, lower.count <= 4 {
            return false
        }

        // Nearby-key on short tokens without phrase support.
        if candidate.strategyID == NearbyKeySubstitutionStrategy.id, lower.count <= 4 {
            return false
        }

        return true
    }

    private func explicitSuggestionOnly(_ candidate: CorrectionCandidate) -> Bool {
        explicitRules.contains {
            $0.enabled
                && $0.source.lowercased() == candidate.original.lowercased()
                && $0.replacement.lowercased() == candidate.replacement.lowercased()
                && $0.behaviour == .suggestion
        }
    }

    private func pairKey(_ a: String, _ b: String) -> String {
        "\(a.lowercased())→\(b.lowercased())"
    }

    private func clamp(_ value: Double) -> Double { min(max(value, 0), 1) }
}
