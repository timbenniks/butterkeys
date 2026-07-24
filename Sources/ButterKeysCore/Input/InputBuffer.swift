import Foundation

public struct InputBufferSnapshot: Sendable, Equatable {
    public let currentToken: String
    public let previousToken: String?
    public let phraseFragment: String
    public let tokens: [String]
    public let deletionSequence: [Character]
    public let bufferText: String
    /// True when the user backspaced inside the current token (likely editing, not a finished typo).
    public let currentTokenWasEdited: Bool

    public init(
        currentToken: String,
        previousToken: String?,
        phraseFragment: String,
        tokens: [String],
        deletionSequence: [Character],
        bufferText: String,
        currentTokenWasEdited: Bool = false
    ) {
        self.currentToken = currentToken
        self.previousToken = previousToken
        self.phraseFragment = phraseFragment
        self.tokens = tokens
        self.deletionSequence = deletionSequence
        self.bufferText = bufferText
        self.currentTokenWasEdited = currentTokenWasEdited
    }
}

public struct InputBuffer: Sendable {
    public static let phraseFragmentLimit = 100
    private static let maxDeletionHistory = 16

    private var currentToken: String = ""
    private var previousToken: String?
    private var phraseFragment: String = ""
    private var tokens: [String] = []
    private var deletionSequence: [Character] = []
    private var currentTokenWasEdited = false

    public init() {}

    public mutating func appendCharacter(_ character: Character) {
        deletionSequence.removeAll(keepingCapacity: true)
        currentToken.append(character)
        appendToPhrase(character)
    }

    public mutating func backspace() {
        guard !currentToken.isEmpty else {
            trimPhraseFragment()
            return
        }

        currentTokenWasEdited = true
        let removed = currentToken.removeLast()
        deletionSequence.append(removed)
        if deletionSequence.count > Self.maxDeletionHistory {
            deletionSequence.removeFirst(deletionSequence.count - Self.maxDeletionHistory)
        }
        trimPhraseFragment()
    }

    public mutating func forwardDelete() {
        // Forward delete only affects phrase fragment tail when token state is uncertain.
        trimPhraseFragment()
    }

    public mutating func markBoundary(with character: Character?) {
        let completed = currentToken
        if !completed.isEmpty {
            previousToken = completed
            tokens.append(completed)
            if tokens.count > 8 {
                tokens.removeFirst(tokens.count - 8)
            }
        }
        currentToken = ""
        currentTokenWasEdited = false
        if let character {
            appendToPhrase(character)
        }
    }

    public mutating func reset() {
        currentToken = ""
        previousToken = nil
        phraseFragment = ""
        tokens.removeAll(keepingCapacity: true)
        deletionSequence.removeAll(keepingCapacity: true)
        currentTokenWasEdited = false
    }

    public var snapshot: InputBufferSnapshot {
        InputBufferSnapshot(
            currentToken: currentToken,
            previousToken: previousToken,
            phraseFragment: phraseFragment,
            tokens: tokens,
            deletionSequence: deletionSequence,
            bufferText: phraseFragment,
            currentTokenWasEdited: currentTokenWasEdited
        )
    }

    private mutating func appendToPhrase(_ character: Character) {
        phraseFragment.append(character)
        if phraseFragment.count > Self.phraseFragmentLimit {
            phraseFragment = String(phraseFragment.suffix(Self.phraseFragmentLimit))
        }
    }

    private mutating func trimPhraseFragment() {
        if !phraseFragment.isEmpty {
            phraseFragment.removeLast()
        }
    }
}
