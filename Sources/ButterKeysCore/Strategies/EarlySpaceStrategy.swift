import Foundation

public struct EarlySpaceStrategy: CorrectionStrategy {
    public static let id = "early_space"
    public var identifier: String { Self.id }

    public init() {}

    public func candidates(for context: CorrectionContext, language: LanguageServices) -> [CorrectionCandidate] {
        guard let previous = context.previousToken, !previous.isEmpty else { return [] }
        let current = context.currentToken
        guard current.count >= 2 else { return [] }

        let movedChar = current.first!
        let newPrevious = previous + String(movedChar)
        let newCurrent = String(current.dropFirst())
        guard !newCurrent.isEmpty else { return [] }

        guard language.dictionary.contains(newPrevious), language.dictionary.contains(newCurrent) else { return [] }

        let originalPhrase = "\(previous) \(current)"
        let replacementPhrase = "\(newPrevious) \(newCurrent)"

        let prevImproved = !language.dictionary.contains(previous)
            || language.dictionary.isMuchMoreFrequent(newPrevious, than: previous)
            || language.dictionary.frequency(newPrevious) > language.dictionary.frequency(previous)
        let currImproved = !language.dictionary.contains(current)
            || language.dictionary.isMuchMoreFrequent(newCurrent, than: current)
            || language.dictionary.frequency(newCurrent) > language.dictionary.frequency(current)
        guard prevImproved && currImproved else { return [] }

        let phraseBoost = min(language.phrases.frequency(replacementPhrase.lowercased()) * 0.15, 0.15)
        let timingBoost = language.motorPatterns.earlySpaceBias + StrategySupport.fastKeyIntervalBoost(context.keyTimings)

        let confidence = StrategySupport.scorer.score(
            original: originalPhrase,
            replacement: replacementPhrase,
            strategyBase: 0.84,
            language: language,
            editDistance: 1,
            timingBoost: timingBoost,
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
                explanation: "Early space: moved '\(movedChar)' to previous token"
            )
        ]
    }
}
