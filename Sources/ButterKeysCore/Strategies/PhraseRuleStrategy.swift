import Foundation

public struct PhraseRuleStrategy: CorrectionStrategy {
    public static let id = "phrase_rule"
    public var identifier: String { Self.id }

    private static let reconstructions: [(String, String, String, String)] = [
        ("int", "he", "in", "the"),
        ("fort", "he", "for", "the"),
        ("wit", "hthe", "with", "the"),
        ("wit", "the", "with", "the")
    ]

    public init() {}

    public func candidates(for context: CorrectionContext, language: LanguageServices) -> [CorrectionCandidate] {
        var results: [CorrectionCandidate] = []

        let twoTokenPhrase = [context.previousToken, context.currentToken]
            .compactMap { $0 }
            .joined(separator: " ")
        let phraseTargets = [twoTokenPhrase, context.phraseFragment].filter { !$0.isEmpty }

        for rule in RuleCache.shared.rules where rule.enabled && rule.matchType == .phrase && rule.behaviour != .never {
            guard StrategySupport.appliesToApp(rule, bundleID: context.appBundleID) else { continue }

            for source in phraseTargets where StrategySupport.phraseMatch(source, rule.source) {
                let replacement = StrategySupport.replacement(for: rule, matched: source)
                let confidence: Double = rule.behaviour == .automatic ? 0.96 : 0.72
                results.append(
                    CorrectionCandidate(
                        original: source,
                        replacement: replacement,
                        affectedRange: 0..<source.count,
                        strategyID: Self.id,
                        confidence: confidence,
                        explanation: "Phrase rule: \(rule.source) → \(rule.replacement)",
                        suggestionOnly: rule.behaviour == .suggestion
                    )
                )
            }
        }

        if let previous = context.previousToken {
            for (srcLeft, srcRight, dstLeft, dstRight) in Self.reconstructions
                where previous.lowercased() == srcLeft && context.currentToken.lowercased() == srcRight {
                let original = "\(previous) \(context.currentToken)"
                let replacement = "\(dstLeft) \(dstRight)"
                let phraseBoost = min(language.phrases.frequency(replacement) * 0.18, 0.18)
                guard phraseBoost > 0 else { continue }

                let confidence = StrategySupport.scorer.score(
                    original: original,
                    replacement: replacement,
                    strategyBase: 0.83,
                    language: language,
                    editDistance: 1,
                    phraseBoost: phraseBoost
                )
                guard confidence > 0 else { continue }

                results.append(
                    CorrectionCandidate(
                        original: original,
                        replacement: replacement,
                        affectedRange: 0..<original.count,
                        strategyID: Self.id,
                        confidence: confidence,
                        explanation: "Phrase frequency reconstruction"
                    )
                )
            }
        }

        return results
    }
}
