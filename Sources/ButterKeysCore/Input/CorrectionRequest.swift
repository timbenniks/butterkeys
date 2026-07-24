import Foundation

public struct CorrectionRequest: Sendable, Equatable {
    public let currentToken: String
    public let previousToken: String?
    public let phraseFragment: String
    public let tokens: [String]
    public let boundary: Character?
    public let keyTimings: [TimeInterval]
    /// Phrase text ending at the completed token (no trailing boundary) — used for spacing heuristics.
    public let bufferText: String
    public let eventTimestamp: TimeInterval
    /// User backspaced inside this token before committing it.
    public let tokenWasEdited: Bool

    public init(
        currentToken: String,
        previousToken: String?,
        phraseFragment: String,
        tokens: [String],
        boundary: Character?,
        keyTimings: [TimeInterval],
        bufferText: String,
        eventTimestamp: TimeInterval,
        tokenWasEdited: Bool = false
    ) {
        self.currentToken = currentToken
        self.previousToken = previousToken
        self.phraseFragment = phraseFragment
        self.tokens = tokens
        self.boundary = boundary
        self.keyTimings = keyTimings
        self.bufferText = bufferText
        self.eventTimestamp = eventTimestamp
        self.tokenWasEdited = tokenWasEdited
    }

    public init(snapshot: InputBufferSnapshot, boundary: Character?, keyTimings: [TimeInterval], eventTimestamp: TimeInterval) {
        self.init(
            currentToken: snapshot.currentToken,
            previousToken: snapshot.previousToken,
            phraseFragment: snapshot.phraseFragment,
            tokens: snapshot.tokens,
            boundary: boundary,
            keyTimings: keyTimings,
            bufferText: snapshot.bufferText,
            eventTimestamp: eventTimestamp,
            tokenWasEdited: snapshot.currentTokenWasEdited
        )
    }
}
