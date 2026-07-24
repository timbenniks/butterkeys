import ButterKeysCore
import Foundation
import Testing

@Suite("Synthetic event guard")
struct SyntheticEventGuardTests {
    private let guard_ = SyntheticEventGuard()

    private func makeEvent(
        timestamp: TimeInterval = 1.0,
        generation: UInt64? = nil
    ) -> NormalizedKeyEvent {
        NormalizedKeyEvent(
            keyCode: 0,
            characters: "a",
            modifiers: [],
            timestamp: timestamp,
            isRepeat: false,
            type: .keyDown,
            syntheticGeneration: generation
        )
    }

    @Test("Unmarked physical events are not synthetic")
    func physicalEventsPassThrough() {
        #expect(!guard_.isSynthetic(makeEvent(timestamp: 10.0)))
    }

    @Test("Marked synthetic timestamps are filtered")
    func markedTimestampsFiltered() {
        guard_.markSynthetic(timestamp: 42.0)
        #expect(guard_.isSynthetic(makeEvent(timestamp: 42.0)))
        #expect(guard_.isSynthetic(makeEvent(timestamp: 42.001)))
        #expect(!guard_.isSynthetic(makeEvent(timestamp: 43.0)))
    }

    @Test("Synthetic generation tags are filtered")
    func generationTagsFiltered() {
        let generation = guard_.nextGeneration()
        guard_.markSynthetic(timestamp: 5.0, generation: generation)

        #expect(guard_.isSynthetic(makeEvent(timestamp: 99.0, generation: generation)))
        #expect(guard_.isSynthetic(makeEvent(timestamp: 99.0, generation: generation - 1)))
        #expect(!guard_.isSynthetic(makeEvent(timestamp: 99.0, generation: generation + 1)))
    }

    @Test("Reset clears recent synthetic timestamps")
    func resetClearsMarks() {
        guard_.markSynthetic(timestamp: 7.0)
        guard_.reset()
        #expect(!guard_.isSynthetic(makeEvent(timestamp: 7.0)))
    }

    @Test("Replacement loop prevention scenario")
    func noInfiniteLoopScenario() {
        let guardA = SyntheticEventGuard()
        let generation = guardA.nextGeneration()
        guardA.markSynthetic(timestamp: 100.0, generation: generation)

        let syntheticReplacement = makeEvent(timestamp: 100.0, generation: generation)
        let physicalFollowUp = makeEvent(timestamp: 200.0)

        #expect(guardA.isSynthetic(syntheticReplacement))
        #expect(!guardA.isSynthetic(physicalFollowUp))
    }
}
