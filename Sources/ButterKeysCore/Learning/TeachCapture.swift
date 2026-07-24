import Foundation

/// Validates and builds explicit rules from user-taught typo pairs.
public enum TeachCapture: Sendable {
    public static let maxTokenLength = 32
    public static let maxPhraseWords = 4

    public static func normalize(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    public static func matchType(for source: String) -> MatchType {
        source.contains(where: \.isWhitespace) ? .phrase : .word
    }

    public static func isValidPart(_ text: String) -> Bool {
        guard !text.isEmpty, text.count <= maxTokenLength * maxPhraseWords else { return false }
        let words = text.split(whereSeparator: \.isWhitespace)
        guard !words.isEmpty, words.count <= maxPhraseWords else { return false }
        return words.allSatisfy { word in
            let token = String(word)
            guard token.count <= maxTokenLength else { return false }
            return token.unicodeScalars.allSatisfy { scalar in
                CharacterSet.alphanumerics.contains(scalar) || scalar == "-" || scalar == "'"
            }
        }
    }

    public static func makeRule(
        source: String,
        replacement: String,
        behaviour: RuleBehaviour = .automatic
    ) -> CorrectionRuleRecord? {
        let source = normalize(source)
        let replacement = normalize(replacement)
        guard isValidPart(source), isValidPart(replacement) else { return nil }
        guard source.caseInsensitiveCompare(replacement) != .orderedSame else { return nil }

        return CorrectionRuleRecord(
            source: source,
            replacement: replacement,
            matchType: matchType(for: source),
            behaviour: behaviour
        )
    }
}
