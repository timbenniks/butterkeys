import Foundation

public struct ShiftedBoundaryStrategy: CorrectionStrategy {
    public static let id = "shifted_boundary"
    public var identifier: String { Self.id }

    private static let boostedPhrases: Set<String> = ["in the", "for the", "with the", "and the"]

    public init() {}

    public func candidates(for context: CorrectionContext, language: LanguageServices) -> [CorrectionCandidate] {
        var results: [CorrectionCandidate] = []

        if let previous = context.previousToken, !previous.isEmpty, !context.currentToken.isEmpty {
            results.append(contentsOf: shiftedSpaceCandidate(previous: previous, current: context.currentToken, language: language))
        }

        results.append(contentsOf: missingSpaceCandidate(token: context.currentToken, language: language))
        return results
    }

    private func shiftedSpaceCandidate(previous: String, current: String, language: LanguageServices) -> [CorrectionCandidate] {
        guard let last = previous.last else { return [] }

        let newPrevious = String(previous.dropLast())
        let newCurrent = String(last) + current
        guard !newPrevious.isEmpty else { return [] }

        guard language.dictionary.contains(newPrevious), language.dictionary.contains(newCurrent) else { return [] }

        let originalPhrase = "\(previous) \(current)"
        let replacementPhrase = "\(newPrevious) \(newCurrent)"
        let phraseBoost = phraseBoost(for: replacementPhrase, language: language)

        let confidence = StrategySupport.scorer.score(
            original: originalPhrase,
            replacement: replacementPhrase,
            strategyBase: 0.85,
            language: language,
            editDistance: 1,
            phraseBoost: phraseBoost
        )
        guard confidence > 0 else { return [] }

        return [
            CorrectionCandidate(
                original: originalPhrase,
                replacement: replacementPhrase,
                affectedRange: 0..<originalPhrase.count,
                strategyID: Self.id,
                confidence: confidence,
                explanation: "Shifted boundary: moved '\(last)' to next token"
            )
        ]
    }

    private func missingSpaceCandidate(token: String, language: LanguageServices) -> [CorrectionCandidate] {
        guard token.count >= 4 else { return [] }

        for splitIndex in 2..<(token.count - 1) {
            let left = String(token.prefix(splitIndex))
            let right = String(token.suffix(token.count - splitIndex))
            guard language.dictionary.contains(left), language.dictionary.contains(right) else { continue }

            let replacementPhrase = "\(left) \(right)"
            let phraseBoost = phraseBoost(for: replacementPhrase, language: language)
            let confidence = StrategySupport.scorer.score(
                original: token,
                replacement: replacementPhrase,
                strategyBase: 0.82,
                language: language,
                editDistance: 1,
                phraseBoost: phraseBoost
            )
            guard confidence > 0 else { continue }

            return [
                CorrectionCandidate(
                    original: token,
                    replacement: replacementPhrase,
                    affectedRange: 0..<token.count,
                    strategyID: Self.id,
                    confidence: confidence,
                    explanation: "Inserted missing space"
                )
            ]
        }

        return []
    }

    private func phraseBoost(for phrase: String, language: LanguageServices) -> Double {
        let lower = phrase.lowercased()
        let freq = language.phrases.frequency(lower)
        let extra = Self.boostedPhrases.contains(lower) ? 0.08 : 0
        return min(freq * 0.15 + extra, 0.20)
    }
}
