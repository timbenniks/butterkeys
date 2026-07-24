import ButterKeysCore
import Testing

@Suite("Case pattern preserver")
struct CasePatternPreserverTests {
    @Test("Lowercase pattern", arguments: [
        ("teh", "the", "the"),
        ("soem", "some", "some"),
    ])
    func lowercase(pattern: String, replacement: String, expected: String) {
        #expect(CasePatternPreserver.apply(pattern: pattern, to: replacement) == expected)
    }

    @Test("Sentence case pattern", arguments: [
        ("Teh", "the", "The"),
        ("Htis", "this", "This"),
        ("Soem", "some", "Some"),
    ])
    func sentenceCase(pattern: String, replacement: String, expected: String) {
        #expect(CasePatternPreserver.apply(pattern: pattern, to: replacement) == expected)
    }

    @Test("Uppercase pattern", arguments: [
        ("TEH", "the", "THE"),
        ("HTIS", "this", "THIS"),
    ])
    func uppercase(pattern: String, replacement: String, expected: String) {
        #expect(CasePatternPreserver.apply(pattern: pattern, to: replacement) == expected)
    }

    @Test("Mixed case falls back to lowercase target")
    func bizarreMixedCase() {
        #expect(CasePatternPreserver.apply(pattern: "TeH", to: "the") == "the")
    }

    @Test("Coordinator preserves casing for explicit rules")
    func coordinatorPreservesCase() {
        let coordinator = CorrectionTestSupport.makeCoordinator()
        let context = CorrectionTestSupport.context(tokens: ["Teh"], currentToken: "Teh")
        let automatic = coordinator.evaluate(context)
        #expect(automatic?.replacement == "The")
    }
}
