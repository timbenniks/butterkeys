import Foundation

public struct LocalDictionary: Sendable {
    private let words: Set<String>
    private let frequencies: [String: Double]
    private let customNever: Set<String>
    private let customNames: Set<String>

    public init(
        words: Set<String>,
        frequencies: [String: Double] = [:],
        customNever: Set<String> = [],
        customNames: Set<String> = []
    ) {
        self.words = words.union(customNames)
        self.frequencies = frequencies
        self.customNever = customNever
        self.customNames = customNames
    }

    public static func loadBundled() -> LocalDictionary {
        BundledDictionaryLoader.load()
    }

    public func contains(_ word: String) -> Bool {
        words.contains(word.lowercased())
    }

    public func shouldNeverCorrect(_ word: String) -> Bool {
        customNever.contains(word.lowercased())
    }

    public func isName(_ word: String) -> Bool {
        customNames.contains(word.lowercased())
    }

    public func frequency(_ word: String) -> Double {
        frequencies[word.lowercased()] ?? (contains(word) ? 0.001 : 0)
    }

    public func isMuchMoreFrequent(_ candidate: String, than original: String, ratio: Double = 8) -> Bool {
        let c = frequency(candidate)
        let o = frequency(original)
        if o <= 0 { return c > 0 }
        return c / o >= ratio
    }

    /// Bounded candidates by edit distance using length buckets (no full permutation).
    public func candidates(like token: String, maxDistance: Int) -> [String] {
        let lower = token.lowercased()
        guard !lower.isEmpty else { return [] }
        let len = lower.count
        var results: [String] = []
        for word in words {
            if abs(word.count - len) > maxDistance { continue }
            if DamerauLevenshtein.distance(lower, word, max: maxDistance) <= maxDistance {
                results.append(word)
            }
        }
        return results.sorted { frequency($0) > frequency($1) }
    }

    public func withCustom(never: Set<String>, names: Set<String>, extra: Set<String>) -> LocalDictionary {
        LocalDictionary(
            words: words.union(extra).union(names),
            frequencies: frequencies,
            customNever: customNever.union(never),
            customNames: customNames.union(names)
        )
    }
}

enum BundledDictionaryLoader {
    static func load() -> LocalDictionary {
        var frequencies: [String: Double] = [:]
        var words: Set<String> = []

        if let url = ButterKeysResources.url(forResource: "word_frequencies", withExtension: "tsv"),
           let data = try? String(contentsOf: url, encoding: .utf8) {
            for line in data.split(separator: "\n") {
                let parts = line.split(separator: "\t")
                guard parts.count >= 2, let freq = Double(parts[1]) else { continue }
                let word = String(parts[0]).lowercased()
                words.insert(word)
                frequencies[word] = freq
            }
        }

        // Ensure fixture/common words exist even if TSV is trimmed.
        for word in SeedWords.all {
            words.insert(word)
            frequencies[word] = max(frequencies[word] ?? 0.01, 0.01)
        }

        return LocalDictionary(words: words, frequencies: frequencies)
    }
}

enum SeedWords {
    static let all: Set<String> = [
        "the", "this", "your", "looks", "and", "with", "some", "just", "give", "me",
        "build", "writing", "something", "working", "building", "typos", "based", "on",
        "in", "for", "app", "feature", "file", "title", "message", "useful", "please",
        "can", "you", "we", "are", "am", "is", "now", "about", "else", "user", "new",
        "keyboard", "jokes", "could", "create", "butter", "fix", "prompt", "not",
        "update", "fix", "implementation", "because", "language", "recognize", "comment",
        "application", "love", "move", "gave", "gnome", "gnostic", "signature", "magnet",
        "signal", "design", "nothing", "typing", "changes", "should", "work", "fix",
        "a", "an", "to", "of", "it", "he", "she", "they", "that", "there", "here",
        "into", "from", "have", "has", "had", "was", "were", "be", "been", "being",
        "do", "does", "did", "will", "would", "could", "should", "may", "might",
        "get", "got", "make", "made", "made", "keep", "making", "wrong", "word",
        "include", "wrote", "often", "change", "smooth", "automatically",
        "thing", "things", "think", "thought", "through", "though", "those", "these"
    ]
}
