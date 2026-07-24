import Foundation

/// Inserts a space when a correction sits immediately after a period (`end.teh` → `end. the`).
public enum PeriodSpacing: Sendable {
    public static func adjustedReplacement(
        original: String,
        replacement: String,
        precedingPhrase: String
    ) -> String {
        guard !replacement.hasPrefix(" ") else { return replacement }
        guard isGluedAfterPeriod(token: original, in: precedingPhrase) else {
            return replacement
        }
        return " " + replacement
    }

    public static func isGluedAfterPeriod(token: String, in phrase: String) -> Bool {
        guard !token.isEmpty, phrase.count >= token.count + 1 else { return false }
        let suffix = String(phrase.suffix(token.count + 1))
        guard suffix.first == "." else { return false }
        let gluedToken = String(suffix.dropFirst())
        return gluedToken.caseInsensitiveCompare(token) == .orderedSame
    }
}
