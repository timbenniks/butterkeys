import ButterKeysCore
import Testing

@Suite("Manual correction learning")
struct ManualCorrectionLearningTests {
    @Test("isCompactToken accepts single tokens only")
    func compactTokenValidation() {
        #expect(ManualCorrectionDetector.isCompactToken("implemnetation"))
        #expect(ManualCorrectionDetector.isCompactToken("implementation"))
        #expect(!ManualCorrectionDetector.isCompactToken(""))
        #expect(!ManualCorrectionDetector.isCompactToken("two words"))
        #expect(!ManualCorrectionDetector.isCompactToken(String(repeating: "a", count: 33)))
    }

    @Test("Full-word delete and retype records compact pair")
    func fullWordRetypePair() {
        var detector = ManualCorrectionDetector()
        let original = "implemnetation"
        for char in original.reversed() {
            detector.recordBackspace(removed: char)
        }
        detector.recordRetypeStarted()

        let pair = detector.evaluateBoundary(
            completedToken: "implementation",
            appBundleID: "com.apple.Notes"
        )

        #expect(pair?.source == "implemnetation")
        #expect(pair?.replacement == "implementation")
        #expect(pair?.appBundleID == "com.apple.Notes")
        #expect(!pair!.source.contains(" "))
        #expect(!pair!.replacement.contains(" "))
    }

    @Test("Partial delete and retype records deleted segment as source")
    func partialRetypePair() {
        var detector = ManualCorrectionDetector()
        let deletedSuffix = Array("implemnetation".suffix(8))
        for char in deletedSuffix.reversed() {
            detector.recordBackspace(removed: char)
        }
        detector.recordRetypeStarted()

        let pair = detector.evaluateBoundary(
            completedToken: "implementation",
            appBundleID: nil
        )

        #expect(pair != nil)
        #expect(pair?.source == "netation")
        #expect(pair?.replacement == "implementation")
    }

    @Test("Same token after retype produces no pair")
    func sameTokenIgnored() {
        var detector = ManualCorrectionDetector()
        for char in "teh".reversed() {
            detector.recordBackspace(removed: char)
        }
        detector.recordRetypeStarted()

        #expect(detector.evaluateBoundary(completedToken: "teh", appBundleID: nil) == nil)
    }

    @Test("Reset clears pending state")
    func resetClearsState() {
        var detector = ManualCorrectionDetector()
        detector.recordBackspace(removed: "h")
        detector.reset()
        detector.recordRetypeStarted()

        #expect(detector.evaluateBoundary(completedToken: "the", appBundleID: nil) == nil)
    }

    @Test("Pair stores only tokens, never sentence context")
    func noSentencePersistence() {
        var detector = ManualCorrectionDetector()
        for char in "soem".reversed() {
            detector.recordBackspace(removed: char)
        }
        detector.recordRetypeStarted()

        let pair = detector.evaluateBoundary(
            completedToken: "some",
            appBundleID: "com.apple.Notes"
        )

        #expect(pair?.source == "soem")
        #expect(pair?.replacement == "some")
        #expect(pair!.source.count <= ManualCorrectionDetector.maxTokenLength)
        #expect(pair!.replacement.count <= ManualCorrectionDetector.maxTokenLength)
    }

    @Test("Repeated recordRetypeStarted keeps pending source")
    func retypeStartedIdempotent() {
        var detector = ManualCorrectionDetector()
        for char in "teh".reversed() {
            detector.recordBackspace(removed: char)
        }
        detector.recordRetypeStarted()
        detector.recordRetypeStarted()
        detector.recordRetypeStarted()

        let pair = detector.evaluateBoundary(completedToken: "the", appBundleID: nil)
        #expect(pair?.source == "teh")
        #expect(pair?.replacement == "the")
    }
}
