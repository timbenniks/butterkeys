import Foundation

public struct KeyboardAdjacencyMap: Sendable {
    private let neighbors: [Character: Set<Character>]

    public static let qwerty = KeyboardAdjacencyMap(neighbors: [
        "q": ["w", "a"],
        "w": ["q", "e", "a", "s"],
        "e": ["w", "r", "s", "d"],
        "r": ["e", "t", "d", "f"],
        "t": ["r", "y", "f", "g"],
        "y": ["t", "u", "g", "h"],
        "u": ["y", "i", "h", "j"],
        "i": ["u", "o", "j", "k"],
        "o": ["i", "p", "k", "l"],
        "p": ["o", "l"],
        "a": ["q", "w", "s", "z"],
        "s": ["a", "w", "e", "d", "z", "x"],
        "d": ["s", "e", "r", "f", "x", "c"],
        "f": ["d", "r", "t", "g", "c", "v"],
        "g": ["f", "t", "y", "h", "v", "b"],
        "h": ["g", "y", "u", "j", "b", "n"],
        "j": ["h", "u", "i", "k", "n", "m"],
        "k": ["j", "i", "o", "l", "m"],
        "l": ["k", "o", "p"],
        "z": ["a", "s", "x"],
        "x": ["z", "s", "d", "c"],
        "c": ["x", "d", "f", "v"],
        "v": ["c", "f", "g", "b"],
        "b": ["v", "g", "h", "n"],
        "n": ["b", "h", "j", "m"],
        "m": ["n", "j", "k"]
    ])

    public init(neighbors: [Character: Set<Character>]) {
        self.neighbors = neighbors
    }

    public func areAdjacent(_ a: Character, _ b: Character) -> Bool {
        neighbors[Character(a.lowercased())]?.contains(Character(b.lowercased())) == true
    }

    public func substitutions(of word: String) -> [(String, Character, Character)] {
        let chars = Array(word.lowercased())
        var results: [(String, Character, Character)] = []
        for i in chars.indices {
            guard let nearby = neighbors[chars[i]] else { continue }
            for n in nearby {
                var copy = chars
                copy[i] = n
                results.append((String(copy), chars[i], n))
            }
        }
        return results
    }
}

public struct PhraseFrequencyStore: Sendable {
    private let phrases: [String: Double]

    public static let bundled = PhraseFrequencyStore(phrases: [
        "give me": 1.0,
        "give this": 0.6,
        "give it": 0.7,
        "in the": 1.0,
        "for the": 0.9,
        "with the": 0.8,
        "based on": 0.7,
        "and the": 0.8,
        "of the": 1.0,
        "to the": 0.9,
        "typing this": 0.4,
        "building a": 0.5,
        "something else": 0.5,
        "writing about": 0.3
    ])

    public init(phrases: [String: Double]) {
        self.phrases = phrases
    }

    public func frequency(_ phrase: String) -> Double {
        phrases[phrase.lowercased()] ?? 0
    }
}
