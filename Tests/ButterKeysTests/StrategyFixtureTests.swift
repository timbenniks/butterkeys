import ButterKeysCore
import Testing

@Suite("Strategy fixtures", .serialized)
struct StrategyFixtureTests {
    private var coordinator: CorrectionCoordinator {
        CorrectionTestSupport.makeCoordinator()
    }

    // MARK: - Adjacent transpositions

    @Test("Adjacent transpositions", arguments: [
        ("I made soem changes", "soem", "some", true),
        ("Please jsut fix this", "jsut", "just", true),
        ("Htis should work", "Htis", "This", true),
    ])
    func adjacentTranspositions(sentence: String, typo: String, expected: String, expectAutomatic: Bool) {
        let context = CorrectionTestSupport.wordContext(in: sentence, currentWord: typo)
        CorrectionTestSupport.expectCorrection(
            replacing: typo,
            with: expected,
            in: context,
            expectAutomatic: expectAutomatic,
            coordinator: coordinator
        )
    }

    // MARK: - Nearby-key substitutions

    @Test("Nearby-key substitutions with phrase context", arguments: [
        ("Please gove me the file", "gove", "give"),
        ("Can you gove this a title?", "gove", "give"),
    ])
    func nearbyKeySubstitutions(sentence: String, typo: String, expected: String) {
        let context = CorrectionTestSupport.wordContext(in: sentence, currentWord: typo)
        CorrectionTestSupport.expectCorrection(
            replacing: typo,
            with: expected,
            in: context,
            expectAutomatic: false,
            coordinator: coordinator
        )
    }

    @Test("Nearby-key protected words stay unchanged", arguments: [
        "I love this",
        "Move the file",
        "He gave me the file",
    ])
    func nearbyKeyProtectedWords(sentence: String) {
        let words = ["love", "Move", "gave"]
        for word in words where sentence.contains(word) {
            let context = CorrectionTestSupport.wordContext(in: sentence, currentWord: word)
            CorrectionTestSupport.expectNoAutomaticCorrection(for: word, in: context, coordinator: coordinator)
        }
    }

    // MARK: - Short permutations

    @Test("Short permutations", arguments: [
        ("Please buidl the app", "buidl", "build"),
        ("Can we buidl this?", "buidl", "build"),
    ])
    func shortPermutations(sentence: String, typo: String, expected: String) {
        let context = CorrectionTestSupport.wordContext(in: sentence, currentWord: typo)
        let coordinator = CorrectionTestSupport.makeCoordinator(includeShortPermutation: true)
        CorrectionTestSupport.expectCorrection(
            replacing: typo,
            with: expected,
            in: context,
            expectAutomatic: false,
            coordinator: coordinator
        )
    }

    // MARK: - NGGN

    @Test("NGGN corrections", arguments: [
        ("I am writign this message", "writign", "writing"),
        ("This is somethign useful", "somethign", "something"),
        ("We are buildign the app", "buildign", "building"),
    ])
    func nggnCorrections(sentence: String, typo: String, expected: String) {
        let context = CorrectionTestSupport.wordContext(in: sentence, currentWord: typo)
        CorrectionTestSupport.expectCorrection(
            replacing: typo,
            with: expected,
            in: context,
            expectAutomatic: false,
            coordinator: coordinator
        )
    }

    @Test("NGGN legitimate words unchanged", arguments: [
        ("The gnome is here", "gnome"),
        ("This is a signature", "signature"),
        ("The magnet is strong", "magnet"),
    ])
    func nggnLegitimateWords(sentence: String, word: String) {
        let context = CorrectionTestSupport.wordContext(in: sentence, currentWord: word)
        CorrectionTestSupport.expectNoAutomaticCorrection(for: word, in: context, coordinator: coordinator)
    }

    // MARK: - Shifted boundaries

    @Test("Shifted boundary corrections", arguments: [
        ("There are jokes int he app", "int", "in", "he", "the"),
        ("We should include this fort he user", "fort", "for", "he", "the"),
    ])
    func shiftedBoundaries(
        sentence: String,
        previousTypo: String,
        previousExpected: String,
        currentTypo: String,
        currentExpected: String
    ) {
        let context = CorrectionTestSupport.wordContext(in: sentence, currentWord: currentTypo)
        let strategy = ShiftedBoundaryStrategy()
        let language = TestFixtures.makeLanguage()
        let phraseCandidate = strategy.candidates(for: context, language: language).first
        #expect(phraseCandidate != nil, "Expected shifted-boundary phrase correction in '\(sentence)'")
        #expect(phraseCandidate!.replacement.lowercased().contains(previousExpected.lowercased()))
        #expect(phraseCandidate!.replacement.lowercased().contains(currentExpected.lowercased()))
    }

    @Test("Phrase reconstruction for wit hthe")
    func witHthePhraseReconstruction() {
        let context = CorrectionTestSupport.wordContext(
            in: "I wrote it wit hthe new keyboard",
            currentWord: "hthe"
        )
        let strategy = PhraseRuleStrategy()
        let language = TestFixtures.makeLanguage()
        let candidate = strategy.candidates(for: context, language: language)
            .first { $0.replacement.lowercased() == "with the" }
        #expect(candidate != nil)
    }

    // MARK: - Early spaces

    @Test("Early space corrections", arguments: [
        ("I am typin gthis now", "typin", "typing", "gthis", "this"),
        ("We are buildin ga feature", "buildin", "building", "ga", "a"),
    ])
    func earlySpaces(
        sentence: String,
        previousTypo: String,
        previousExpected: String,
        currentTypo: String,
        currentExpected: String
    ) {
        let context = CorrectionTestSupport.wordContext(in: sentence, currentWord: currentTypo)
        let strategy = EarlySpaceStrategy()
        let language = TestFixtures.makeLanguage()
        let phraseCandidate = strategy.candidates(for: context, language: language).first
        #expect(phraseCandidate != nil, "Expected early-space phrase correction in '\(sentence)'")
        #expect(phraseCandidate!.replacement.lowercased().contains(previousExpected.lowercased()))
        #expect(phraseCandidate!.replacement.lowercased().contains(currentExpected.lowercased()))
    }

    // MARK: - Extra characters

    @Test("Extra character corrections", arguments: [
        ("I keep making typoes", "typoes", "typos"),
        ("This has thhe wrong word", "thhe", "the"),
    ])
    func extraCharacters(sentence: String, typo: String, expected: String) {
        let context = CorrectionTestSupport.wordContext(in: sentence, currentWord: typo)
        CorrectionTestSupport.expectCorrection(
            replacing: typo,
            with: expected,
            in: context,
            expectAutomatic: false,
            coordinator: coordinator
        )
    }

    // MARK: - Combined sentences

    @Test("Combined sentence token evaluation")
    func combinedSentences() {
        CorrectionTestSupport.evaluateSentenceFixtures(
            "Please gove me the full prompt, not jsut the update.",
            expectations: ["gove": "give", "jsut": "just"],
            coordinator: coordinator
        )

        CorrectionTestSupport.evaluateSentenceFixtures(
            "We could create soem butter jokes int he app.",
            expectations: ["soem": "some"],
            expectAutomatic: ["soem"],
            coordinator: coordinator
        )

        CorrectionTestSupport.evaluateSentenceFixtures(
            "Can we buidl this and fix the typoes?",
            expectations: ["buidl": "build", "typoes": "typos"],
            coordinator: coordinator
        )

        CorrectionTestSupport.evaluateSentenceFixtures(
            "I am writign somethign int he app.",
            expectations: ["writign": "writing", "somethign": "something"],
            coordinator: coordinator
        )
    }
}
