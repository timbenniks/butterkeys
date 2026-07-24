import Foundation

public struct ConfidencePolicy: Sendable {
    public var automaticThreshold: Double
    public var suggestionThreshold: Double
    public var allowsSpeculativeStrategies: Bool

    public init(preset: ConfidencePreset = .taughtOnly) {
        automaticThreshold = preset.automaticThreshold
        suggestionThreshold = preset.suggestionThreshold
        allowsSpeculativeStrategies = preset.allowsSpeculativeStrategies
    }

    public init(
        automaticThreshold: Double,
        suggestionThreshold: Double,
        allowsSpeculativeStrategies: Bool = true
    ) {
        self.automaticThreshold = automaticThreshold
        self.suggestionThreshold = suggestionThreshold
        self.allowsSpeculativeStrategies = allowsSpeculativeStrategies
    }

    public func decision(for confidence: Double, suggestionOnly: Bool) -> CorrectionAction {
        if suggestionOnly || confidence < automaticThreshold {
            if confidence >= suggestionThreshold { return .suggest }
            return .ignore
        }
        if confidence >= automaticThreshold { return .automatic }
        if confidence >= suggestionThreshold { return .suggest }
        return .ignore
    }
}

public enum CorrectionAction: Sendable {
    case automatic
    case suggest
    case ignore
}

public struct CandidateScorer: Sendable {
    public init() {}

    public func score(
        original: String,
        replacement: String,
        strategyBase: Double,
        language: LanguageServices,
        editDistance: Int? = nil,
        timingBoost: Double = 0,
        historyBoost: Double = 0,
        undoPenalty: Double = 0,
        phraseBoost: Double = 0,
        contextLooksTechnical: Bool = false
    ) -> Double {
        if language.dictionary.shouldNeverCorrect(original) { return 0 }
        if original.lowercased() == replacement.lowercased() { return 0 }

        let origValid = language.dictionary.contains(original)
        let replValid = language.dictionary.contains(replacement)
        guard replValid else { return min(strategyBase * 0.2, 0.4) }

        var score = strategyBase

        if !origValid {
            // Unknown short tokens are often another language — don't reward "typo" assumption.
            if original.count <= 4 {
                score -= 0.18
            } else {
                score += 0.12
            }
        }
        if language.dictionary.isMuchMoreFrequent(replacement, than: original) { score += 0.10 }
        else if language.dictionary.frequency(replacement) > language.dictionary.frequency(original) {
            score += 0.04
        }

        if let distance = editDistance {
            score += max(0, 0.08 - Double(distance) * 0.03)
        }

        score += timingBoost
        score += historyBoost
        score += phraseBoost
        score -= undoPenalty

        if contextLooksTechnical { score -= 0.25 }
        if language.dictionary.isName(original) { score -= 0.3 }
        if looksLikeCode(original) { score -= 0.4 }

        // Ambiguous: both valid and similar frequency — stay conservative.
        if origValid, !language.dictionary.isMuchMoreFrequent(replacement, than: original, ratio: 4) {
            score -= 0.15
        }

        return min(max(score, 0), 1)
    }

    private func looksLikeCode(_ token: String) -> Bool {
        token.contains("_")
            || token.contains(where: { $0.isNumber })
            || (token.contains(where: \.isUppercase) && token.contains(where: \.isLowercase) && token.count > 2)
    }
}
