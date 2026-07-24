import Foundation

public struct ExplicitRuleStrategy: CorrectionStrategy {
    public static let id = "explicit_rule"
    public var identifier: String { Self.id }

    public init() {}

    public func candidates(for context: CorrectionContext, language: LanguageServices) -> [CorrectionCandidate] {
        let token = context.currentToken
        guard !token.isEmpty else { return [] }

        let twoTokenPhrase = [context.previousToken, token]
            .compactMap { $0 }
            .joined(separator: " ")
        let matchTargets: [(String, Range<Int>)] = [
            (token, 0..<token.count),
            (twoTokenPhrase, 0..<twoTokenPhrase.count),
            (context.phraseFragment, 0..<context.phraseFragment.count)
        ].filter { !$0.0.isEmpty }

        var results: [CorrectionCandidate] = []

        for rule in RuleCache.shared.rules where rule.enabled && rule.behaviour != .never {
            guard StrategySupport.appliesToApp(rule, bundleID: context.appBundleID) else { continue }

            for (source, range) in matchTargets where matches(rule: rule, source: source) {
                let matched = source
                let replacement = StrategySupport.replacement(for: rule, matched: matched)
                let confidence: Double = rule.behaviour == .automatic ? 0.98 : 0.75

                results.append(
                    CorrectionCandidate(
                        original: matched,
                        replacement: replacement,
                        affectedRange: range,
                        strategyID: Self.id,
                        confidence: confidence,
                        explanation: "Explicit rule: \(rule.source) → \(rule.replacement)",
                        suggestionOnly: rule.behaviour == .suggestion
                    )
                )
            }
        }

        return results
    }

    private func matches(rule: CorrectionRuleRecord, source: String) -> Bool {
        switch rule.matchType {
        case .word:
            return StrategySupport.wholeWordMatch(source, rule.source)
        case .phrase:
            return StrategySupport.phraseMatch(source, rule.source)
        }
    }
}
