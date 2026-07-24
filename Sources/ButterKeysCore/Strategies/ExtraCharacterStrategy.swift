import Foundation

public struct ExtraCharacterStrategy: CorrectionStrategy {
    public static let id = "extra_character"
    public var identifier: String { Self.id }

    public init() {}

    public func candidates(for context: CorrectionContext, language: LanguageServices) -> [CorrectionCandidate] {
        let token = context.currentToken
        guard token.count >= 3 else { return [] }

        let chars = Array(token)
        var seenRemovals: Set<String> = []
        var results: [CorrectionCandidate] = []

        for index in chars.indices {
            let removalChar = chars[index]
            var copy = chars
            copy.remove(at: index)
            let replacement = String(copy)
            guard !replacement.isEmpty, seenRemovals.insert(replacement.lowercased()).inserted else { continue }
            guard language.dictionary.contains(replacement) else { continue }

            let isDuplicate = index > 0 && chars[index - 1] == removalChar
            let base = isDuplicate ? 0.86 : 0.78
            let confidence = StrategySupport.scorer.score(
                original: token,
                replacement: replacement,
                strategyBase: base,
                language: language,
                editDistance: 1,
                timingBoost: isDuplicate ? StrategySupport.fastKeyIntervalBoost(context.keyTimings) : 0
            )
            guard confidence > 0 else { continue }

            results.append(
                CorrectionCandidate(
                    original: token,
                    replacement: replacement,
                    affectedRange: 0..<token.count,
                    strategyID: Self.id,
                    confidence: confidence,
                    explanation: isDuplicate ? "Removed duplicate character" : "Removed extra character"
                )
            )
        }

        return results.sorted { $0.confidence > $1.confidence }
    }
}
