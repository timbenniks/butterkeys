import Foundation

public struct AdjacentTranspositionStrategy: CorrectionStrategy {
    public static let id = "adjacent_transposition"
    public var identifier: String { Self.id }

    public init() {}

    public func candidates(for context: CorrectionContext, language: LanguageServices) -> [CorrectionCandidate] {
        let token = context.currentToken
        guard token.count >= 2 else { return [] }

        let originalValid = language.dictionary.contains(token)
        if originalValid, language.dictionary.frequency(token) > 0.01 {
            return []
        }

        let timingBoost = StrategySupport.fastKeyIntervalBoost(context.keyTimings)
        var results: [CorrectionCandidate] = []

        let chars = Array(token)
        for index in 0..<(chars.count - 1) {
            var swapped = chars
            swapped.swapAt(index, index + 1)
            let replacement = String(swapped)
            guard language.dictionary.contains(replacement) else { continue }
            guard !originalValid || language.dictionary.isMuchMoreFrequent(replacement, than: token) else { continue }

            let confidence = StrategySupport.scorer.score(
                original: token,
                replacement: replacement,
                strategyBase: 0.88,
                language: language,
                editDistance: 1,
                timingBoost: timingBoost
            )
            guard confidence > 0 else { continue }

            results.append(
                CorrectionCandidate(
                    original: token,
                    replacement: replacement,
                    affectedRange: 0..<token.count,
                    strategyID: Self.id,
                    confidence: confidence,
                    explanation: "Adjacent transposition at position \(index)"
                )
            )
        }

        return results
    }
}
