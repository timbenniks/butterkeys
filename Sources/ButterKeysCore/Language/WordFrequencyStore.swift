import Foundation

/// Thin wrapper around bundled word frequencies exposed by `LocalDictionary`.
public struct WordFrequencyStore: Sendable {
    private let dictionary: LocalDictionary

    public init(dictionary: LocalDictionary) {
        self.dictionary = dictionary
    }

    public static func bundled() -> WordFrequencyStore {
        WordFrequencyStore(dictionary: .loadBundled())
    }

    public func contains(_ word: String) -> Bool {
        dictionary.contains(word)
    }

    public func frequency(_ word: String) -> Double {
        dictionary.frequency(word)
    }

    public func isMuchMoreFrequent(_ candidate: String, than original: String, ratio: Double = 8) -> Bool {
        dictionary.isMuchMoreFrequent(candidate, than: original, ratio: ratio)
    }
}
