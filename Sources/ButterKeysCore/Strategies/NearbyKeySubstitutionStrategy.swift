import Foundation

public struct NearbyKeySubstitutionStrategy: CorrectionStrategy {
    public static let id = "nearby_key"
    public var identifier: String { Self.id }

    private static let protectedWords: Set<String> = ["love", "move", "gave"]
    private static let givePhrases: Set<String> = ["give me", "give this", "give it"]

    public init() {}

    public func candidates(for context: CorrectionContext, language: LanguageServices) -> [CorrectionCandidate] {
        let token = context.currentToken
        guard token.count >= 2 else { return [] }

        var results: [CorrectionCandidate] = []
        let phraseWindow = phraseContext(for: context)

        for (replacement, from, to) in language.adjacency.substitutions(of: token) {
            guard language.dictionary.contains(replacement) else { continue }

            let lower = token.lowercased()
            if Self.protectedWords.contains(lower), !hasStrongGiveContext(replacement: replacement, phraseWindow: phraseWindow, language: language) {
                continue
            }

            let motorBoost = language.motorPatterns.nearbyBoost(from: from, to: to)
            var base = 0.80 + motorBoost

            if replacement.lowercased() == "give", hasStrongGiveContext(replacement: replacement, phraseWindow: phraseWindow, language: language) {
                base += 0.10
            }

            let phraseBoost = givePhraseBoost(replacement: replacement, context: context, language: language)
            let confidence = StrategySupport.scorer.score(
                original: token,
                replacement: replacement,
                strategyBase: base,
                language: language,
                editDistance: 1,
                phraseBoost: phraseBoost
            )
            guard confidence > 0 else { continue }

            results.append(
                CorrectionCandidate(
                    original: token,
                    replacement: replacement,
                    affectedRange: 0..<token.count,
                    strategyID: Self.id,
                    confidence: confidence,
                    explanation: "Nearby key substitution: \(from) → \(to)"
                )
            )
        }

        return results
    }

    private func phraseContext(for context: CorrectionContext) -> String {
        if !context.phraseFragment.isEmpty { return context.phraseFragment.lowercased() }
        let parts = [context.previousToken, context.currentToken].compactMap { $0?.lowercased() }
        return parts.joined(separator: " ")
    }

    private func hasStrongGiveContext(replacement: String, phraseWindow: String, language: LanguageServices) -> Bool {
        guard replacement.lowercased() == "give" else { return false }
        return Self.givePhrases.contains(where: { phraseWindow.contains($0) })
            || language.phrases.frequency("give me") > 0
                && (phraseWindow.hasSuffix(" me") || phraseWindow.hasSuffix(" this") || phraseWindow.hasSuffix(" it"))
    }

    private func givePhraseBoost(replacement: String, context: CorrectionContext, language: LanguageServices) -> Double {
        guard replacement.lowercased() == "give" else { return 0 }
        let window = phraseContext(for: context)
        let matched = Self.givePhrases
            .map { ($0, language.phrases.frequency($0)) }
            .filter { window.contains($0.0) }
            .map(\.1)
            .max() ?? 0
        return min(matched * 0.12, 0.12)
    }
}
