import Foundation

public struct ShortPermutationStrategy: CorrectionStrategy {
    public static let id = "short_permutation"
    public var identifier: String { Self.id }

    public init() {}

    public func candidates(for context: CorrectionContext, language: LanguageServices) -> [CorrectionCandidate] {
        let token = context.currentToken
        guard (4...8).contains(token.count) else { return [] }

        if language.dictionary.contains(token), language.dictionary.frequency(token) > 0.01 {
            return []
        }

        let nearby = language.dictionary.candidates(like: token, maxDistance: 2)
        var results: [CorrectionCandidate] = []

        for replacement in nearby where replacement.lowercased() != token.lowercased() {
            let distance = DamerauLevenshtein.distance(token.lowercased(), replacement.lowercased(), max: 2)
            guard distance <= 2 else { continue }
            guard StrategySupport.sameMultiset(token, replacement) || distance <= 2 else { continue }

            var base = 0.82
            if StrategySupport.sameMultiset(token, replacement) { base += 0.06 }

            let confidence = StrategySupport.scorer.score(
                original: token,
                replacement: replacement,
                strategyBase: base,
                language: language,
                editDistance: distance
            )
            guard confidence > 0 else { continue }

            results.append(
                CorrectionCandidate(
                    original: token,
                    replacement: replacement,
                    affectedRange: 0..<token.count,
                    strategyID: Self.id,
                    confidence: confidence,
                    explanation: StrategySupport.sameMultiset(token, replacement)
                        ? "Short anagram permutation"
                        : "Short permutation (distance \(distance))"
                )
            )
        }

        return results
    }
}
