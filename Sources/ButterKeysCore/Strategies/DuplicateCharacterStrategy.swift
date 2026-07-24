import Foundation

public struct DuplicateCharacterStrategy: CorrectionStrategy {
    public static let id = "duplicate_character"
    public var identifier: String { Self.id }

    public init() {}

    public func candidates(for context: CorrectionContext, language: LanguageServices) -> [CorrectionCandidate] {
        let token = context.currentToken
        guard token.count >= 3 else { return [] }

        let chars = Array(token)
        var results: [CorrectionCandidate] = []
        var seen: Set<String> = []

        for index in 1..<chars.count where chars[index] == chars[index - 1] {
            var copy = chars
            copy.remove(at: index)
            let replacement = String(copy)
            guard seen.insert(replacement.lowercased()).inserted else { continue }
            guard language.dictionary.contains(replacement) else { continue }

            let confidence = StrategySupport.scorer.score(
                original: token,
                replacement: replacement,
                strategyBase: 0.87,
                language: language,
                editDistance: 1,
                timingBoost: StrategySupport.fastKeyIntervalBoost(context.keyTimings)
            )
            guard confidence > 0 else { continue }

            results.append(
                CorrectionCandidate(
                    original: token,
                    replacement: replacement,
                    affectedRange: 0..<token.count,
                    strategyID: Self.id,
                    confidence: confidence,
                    explanation: "Collapsed duplicate '\(chars[index])'"
                )
            )
        }

        return results
    }
}
