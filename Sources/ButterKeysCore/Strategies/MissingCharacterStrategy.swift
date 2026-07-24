import Foundation

public struct MissingCharacterStrategy: CorrectionStrategy {
    public static let id = "missing_character"
    public var identifier: String { Self.id }

    public init() {}

    public func candidates(for context: CorrectionContext, language: LanguageServices) -> [CorrectionCandidate] {
        let token = context.currentToken
        guard token.count >= 4 else { return [] }

        if language.dictionary.contains(token),
           language.dictionary.frequency(token) > 0.01 {
            return []
        }

        let nearby = language.dictionary.candidates(like: token, maxDistance: 1)
        var results: [CorrectionCandidate] = []

        for replacement in nearby where replacement.count == token.count + 1 {
            let confidence = StrategySupport.scorer.score(
                original: token,
                replacement: replacement,
                strategyBase: 0.72,
                language: language,
                editDistance: 1,
                contextLooksTechnical: looksTechnical(token)
            )
            guard confidence >= 0.55 else { continue }

            results.append(
                CorrectionCandidate(
                    original: token,
                    replacement: replacement,
                    affectedRange: 0..<token.count,
                    strategyID: Self.id,
                    confidence: confidence,
                    explanation: "Missing character correction"
                )
            )
        }

        return Array(results.prefix(3))
    }

    private func looksTechnical(_ token: String) -> Bool {
        token.contains("_") || token.contains(where: \.isNumber)
    }
}
