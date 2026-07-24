import ButterKeysCore
import Foundation
import Testing

enum CorrectionTestSupport {
    static let defaultBundleID = "com.apple.Notes"

    static func makeLanguage() -> LanguageServices {
        TestFixtures.ensureRulesLoaded()
        return TestFixtures.makeLanguage()
    }

    static func makeCoordinator(
        language: LanguageServices? = nil,
        policy: ConfidencePolicy = ConfidencePolicy(preset: .balanced),
        explicitRules: [CorrectionRuleRecord] = [],
        includeShortPermutation: Bool = false
    ) -> CorrectionCoordinator {
        if language != nil || !explicitRules.isEmpty {
            TestFixtures.ensureRulesLoaded()
            return CorrectionCoordinator(
                language: language ?? TestFixtures.makeLanguage(),
                policy: policy,
                explicitRules: explicitRules
            )
        }
        return TestFixtures.makeCoordinator(
            policy: policy,
            includeShortPermutation: includeShortPermutation
        )
    }

    static func context(
        tokens: [String],
        currentToken: String,
        previousToken: String? = nil,
        phraseFragment: String? = nil,
        boundary: Character? = " ",
        appBundleID: String? = defaultBundleID,
        applicationMode: ApplicationMode = .prose,
        keyTimings: [TimeInterval] = [],
        bufferText: String = ""
    ) -> CorrectionContext {
        CorrectionContext(
            tokens: tokens,
            currentToken: currentToken,
            previousToken: previousToken ?? tokens.dropLast().last,
            phraseFragment: phraseFragment ?? tokens.joined(separator: " "),
            boundary: boundary,
            appBundleID: appBundleID,
            applicationMode: applicationMode,
            keyTimings: keyTimings,
            bufferText: bufferText
        )
    }

    static func wordContext(
        in sentence: String,
        currentWord: String,
        boundary: Character? = " "
    ) -> CorrectionContext {
        let words = sentence.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        guard let index = words.lastIndex(of: currentWord) else {
            preconditionFailure("Word '\(currentWord)' not found in '\(sentence)'")
        }
        let tokens = Array(words.prefix(index + 1))
        let previous = index > 0 ? words[index - 1] : nil
        return context(
            tokens: tokens,
            currentToken: currentWord,
            previousToken: previous,
            phraseFragment: sentence
        )
    }

    static func candidates(
        for context: CorrectionContext,
        coordinator: CorrectionCoordinator? = nil
    ) -> [CorrectionCandidate] {
        (coordinator ?? makeCoordinator()).candidates(for: context)
    }

    static func automatic(
        for context: CorrectionContext,
        coordinator: CorrectionCoordinator? = nil
    ) -> CorrectionCandidate? {
        (coordinator ?? makeCoordinator()).evaluate(context)
    }

    static func hasCandidate(
        replacing original: String,
        with replacement: String,
        in context: CorrectionContext,
        coordinator: CorrectionCoordinator? = nil
    ) -> Bool {
        candidates(for: context, coordinator: coordinator).contains {
            $0.original.caseInsensitiveCompare(original) == .orderedSame
                && $0.replacement.caseInsensitiveCompare(replacement) == .orderedSame
        }
    }

    static func expectCorrection(
        replacing original: String,
        with replacement: String,
        in context: CorrectionContext,
        expectAutomatic: Bool,
        coordinator: CorrectionCoordinator? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let engine = coordinator ?? makeCoordinator()
        let matches = engine.candidates(for: context).filter {
            $0.original.caseInsensitiveCompare(original) == .orderedSame
                && $0.replacement.caseInsensitiveCompare(replacement) == .orderedSame
        }
        #expect(!matches.isEmpty, "Expected candidate \(original) → \(replacement)", sourceLocation: sourceLocation)

        if expectAutomatic {
            let automatic = engine.evaluate(context)
            #expect(automatic != nil, "Expected automatic correction for \(original)", sourceLocation: sourceLocation)
            #expect(
                automatic!.original.caseInsensitiveCompare(original) == .orderedSame,
                "Expected automatic correction for '\(original)', got original '\(automatic!.original)'",
                sourceLocation: sourceLocation
            )
            #expect(
                automatic!.replacement.caseInsensitiveCompare(replacement) == .orderedSame,
                "Expected automatic replacement '\(replacement)', got '\(automatic!.replacement)'",
                sourceLocation: sourceLocation
            )
        }
    }

    static func expectNoAutomaticCorrection(
        for token: String,
        in context: CorrectionContext,
        coordinator: CorrectionCoordinator? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let engine = coordinator ?? makeCoordinator()
        #expect(engine.evaluate(context) == nil, "Expected no automatic correction for '\(token)'", sourceLocation: sourceLocation)

        let aggressive = engine.candidates(for: context).filter {
            $0.original.caseInsensitiveCompare(token) == .orderedSame
                && $0.replacement.caseInsensitiveCompare(token) != .orderedSame
                && engine.action(for: $0) == .automatic
        }
        #expect(aggressive.isEmpty, "Expected no automatic candidate for '\(token)'", sourceLocation: sourceLocation)
    }

    static func evaluateSentenceFixtures(
        _ sentence: String,
        expectations: [String: String],
        expectAutomatic: Set<String> = [],
        coordinator: CorrectionCoordinator? = nil
    ) {
        let words = sentence.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        for (index, word) in words.enumerated() {
            guard let expected = expectations[word] else { continue }
            let tokens = Array(words.prefix(index + 1))
            let ctx = context(
                tokens: tokens,
                currentToken: word,
                previousToken: index > 0 ? words[index - 1] : nil,
                phraseFragment: sentence
            )
            expectCorrection(
                replacing: word,
                with: expected,
                in: ctx,
                expectAutomatic: expectAutomatic.contains(word),
                coordinator: coordinator
            )
        }
    }
}
