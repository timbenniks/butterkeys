import ButterKeysCore
import Testing

@Suite("Damerau-Levenshtein distance")
struct DamerauLevenshteinTests {
    @Test("Identical strings")
    func identical() {
        #expect(DamerauLevenshtein.distance("build", "build") == 0)
    }

    @Test("Single adjacent transposition", arguments: [
        ("soem", "some", 1),
        ("jsut", "just", 1),
        ("htis", "this", 1),
        ("teh", "the", 1),
    ])
    func adjacentTransposition(_ a: String, _ b: String, _ expected: Int) {
        #expect(DamerauLevenshtein.distance(a, b) == expected)
    }

    @Test("Short permutation distance", arguments: [
        ("buidl", "build", 1),
        ("gove", "give", 1),
        ("typoes", "typos", 1),
    ])
    func shortPermutations(_ a: String, _ b: String, _ expected: Int) {
        #expect(DamerauLevenshtein.distance(a, b, max: 3) == expected)
    }

    @Test("NGGN swap", arguments: [
        ("writign", "writing", 1),
        ("somethign", "something", 1),
    ])
    func nggnSwap(_ a: String, _ b: String, _ expected: Int) {
        #expect(DamerauLevenshtein.distance(a, b, max: 3) == expected)
    }

    @Test("Max distance early exit")
    func maxDistanceCap() {
        #expect(DamerauLevenshtein.distance("abc", "xyz", max: 1) > 1)
        #expect(DamerauLevenshtein.distance("a", "abcdefghij", max: 2) > 2)
    }

    @Test("Empty strings")
    func emptyStrings() {
        #expect(DamerauLevenshtein.distance("", "abc") == 3)
        #expect(DamerauLevenshtein.distance("abc", "") == 3)
        #expect(DamerauLevenshtein.distance("", "") == 0)
    }

    @Test("Case insensitive comparison")
    func caseInsensitive() {
        #expect(DamerauLevenshtein.distance("TeH", "the") == 1)
        #expect(DamerauLevenshtein.distance("BUILD", "buidl", max: 3) == 1)
    }
}
