import Foundation

public struct NGGNStrategy: CorrectionStrategy {
    public static let id = "ng_gn"
    public var identifier: String { Self.id }

    private static let gnStartWords: Set<String> = ["gnome", "gnostic"]
    private static let preservedWords: Set<String> = ["gnome", "gnostic", "signature", "magnet", "signal", "design"]

    public init() {}

    public func candidates(for context: CorrectionContext, language: LanguageServices) -> [CorrectionCandidate] {
        let token = context.currentToken
        guard token.lowercased().contains("gn") else { return [] }

        let lower = token.lowercased()
        if Self.preservedWords.contains(lower), language.dictionary.contains(token) {
            return []
        }
        if lower.hasPrefix("gn"), Self.gnStartWords.contains(where: { lower.hasPrefix($0) || lower == $0 }) {
            return []
        }
        if language.dictionary.contains(token), language.dictionary.frequency(token) > 0.01 {
            return []
        }

        var variants: [String] = []
        if lower.hasSuffix("ign") {
            variants.append(String(lower.dropLast(3)) + "ing")
        }
        if lower.contains("gn") {
            variants.append(lower.replacingOccurrences(of: "gn", with: "ng"))
        }

        var results: [CorrectionCandidate] = []
        for replacement in Set(variants) where replacement != lower {
            guard language.dictionary.contains(replacement) else { continue }

            let confidence = StrategySupport.scorer.score(
                original: token,
                replacement: replacement,
                strategyBase: lower.hasSuffix("ign") ? 0.86 : 0.78,
                language: language,
                editDistance: DamerauLevenshtein.distance(lower, replacement, max: 2)
            )
            guard confidence > 0 else { continue }

            results.append(
                CorrectionCandidate(
                    original: token,
                    replacement: replacement,
                    affectedRange: 0..<token.count,
                    strategyID: Self.id,
                    confidence: confidence,
                    explanation: "gn → ng transposition"
                )
            )
        }

        return results
    }
}
