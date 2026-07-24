import ButterKeysCore
import Testing

@Suite("Period spacing")
struct PeriodSpacingTests {
    @Test("Adds a space when the typo is glued to a period")
    func addsSpaceAfterPeriod() {
        let adjusted = PeriodSpacing.adjustedReplacement(
            original: "teh",
            replacement: "the",
            precedingPhrase: "Hello.teh"
        )
        #expect(adjusted == " the")
    }

    @Test("Leaves spaced punctuation alone")
    func leavesExistingSpace() {
        let adjusted = PeriodSpacing.adjustedReplacement(
            original: "teh",
            replacement: "the",
            precedingPhrase: "Hello. teh"
        )
        #expect(adjusted == "the")
    }

    @Test("Is case-insensitive for the glued token")
    func caseInsensitive() {
        #expect(
            PeriodSpacing.adjustedReplacement(
                original: "Teh",
                replacement: "The",
                precedingPhrase: "End.teh"
            ) == " The"
        )
    }

    @Test("Does not double-space")
    func noDoubleSpace() {
        let adjusted = PeriodSpacing.adjustedReplacement(
            original: "teh",
            replacement: " the",
            precedingPhrase: "Hello.teh"
        )
        #expect(adjusted == " the")
    }
}

@Suite("Edited-token correction skip")
struct EditedTokenSkipTests {
    @Test("Backspace inside the current token marks it edited")
    func backspaceMarksEdited() {
        var buffer = InputBuffer()
        for ch in "teh" {
            buffer.appendCharacter(ch)
        }
        #expect(buffer.snapshot.currentTokenWasEdited == false)
        buffer.backspace()
        #expect(buffer.snapshot.currentTokenWasEdited == true)
        buffer.appendCharacter("h")
        #expect(buffer.snapshot.currentToken == "teh")
        #expect(buffer.snapshot.currentTokenWasEdited == true)
    }

    @Test("Boundary clears the edited flag for the next token")
    func boundaryClearsFlag() {
        var buffer = InputBuffer()
        buffer.appendCharacter("t")
        buffer.backspace()
        buffer.appendCharacter("a")
        #expect(buffer.snapshot.currentTokenWasEdited == true)
        buffer.markBoundary(with: " ")
        #expect(buffer.snapshot.currentTokenWasEdited == false)
    }
}
