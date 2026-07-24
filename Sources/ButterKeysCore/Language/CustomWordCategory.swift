import Foundation

/// Lean user dictionary categories stored in `custom_words.category`.
public enum CustomWordCategory: String, Sendable, CaseIterable, Identifiable {
    /// Never auto-correct this token (protected / deny list).
    case protected = "protected"
    /// Treat as a valid word for scoring / candidate matching.
    case dictionary = "dictionary"
    /// Personal names — valid word + lightly penalize changing them.
    case name = "name"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .protected: "Protected"
        case .dictionary: "My words"
        case .name: "Names"
        }
    }
}
