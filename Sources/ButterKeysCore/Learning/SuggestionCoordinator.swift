import Foundation

public final class SuggestionCoordinator: @unchecked Sendable {
    private let lock = NSLock()
    private let learner: TypoPatternLearner
    private let confidenceTracker: PatternConfidenceTracker
    private let rejectionTracker: UserRejectionTracker
    private let repository: LearnedPatternRepository
    private var cachedSuggestions: [LearnedPatternSuggestion] = []

    public init(
        learner: TypoPatternLearner,
        confidenceTracker: PatternConfidenceTracker = PatternConfidenceTracker(),
        rejectionTracker: UserRejectionTracker,
        repository: LearnedPatternRepository
    ) {
        self.learner = learner
        self.confidenceTracker = confidenceTracker
        self.rejectionTracker = rejectionTracker
        self.repository = repository
    }

    public var pendingSuggestions: [LearnedPatternSuggestion] {
        lock.lock()
        defer { lock.unlock() }
        return cachedSuggestions
    }

    public func refresh() throws {
        let suggestions = try learner.pendingSuggestions()
        lock.lock()
        cachedSuggestions = suggestions
        lock.unlock()
    }

    public func updateSuggestionThreshold(_ value: Int) {
        learner.updateSuggestionThreshold(value)
    }

    @discardableResult
    public func observeManualCorrection(_ pair: ManualCorrectionPair) throws -> LearnedPatternRecord? {
        let record = try learner.observeManualCorrection(pair)
        try refresh()
        return record
    }

    public func acceptAutomatic(id: String) throws {
        try applyDecision(id: id, decision: .acceptAutomatic, status: .automatic)
    }

    public func acceptSuggestOnly(id: String) throws {
        try applyDecision(id: id, decision: .acceptSuggestOnly, status: .suggestOnly)
    }

    public func reject(id: String) throws {
        try applyDecision(id: id, decision: .reject, status: .rejected)
    }

    public func neverCorrect(id: String) throws {
        try applyDecision(id: id, decision: .never, status: .never)
    }

    public func recordUndo(for patternID: String) throws {
        guard var pattern = try repository.fetch(id: patternID) else { return }
        confidenceTracker.recordUndo(&pattern)
        if pattern.undoCount >= 2 {
            pattern.status = LearnedPatternStatus.suggestOnly.rawValue
        }
        try repository.save(pattern)
        try refresh()
    }

    private func applyDecision(
        id: String,
        decision: UserPatternDecision,
        status: LearnedPatternStatus
    ) throws {
        guard var pattern = try repository.fetch(id: id) else { return }

        rejectionTracker.record(decision, source: pattern.source, replacement: pattern.replacement)
        if decision == .acceptAutomatic {
            confidenceTracker.recordAcceptance(&pattern)
        }
        pattern.status = status.rawValue
        try repository.save(pattern)
        try refresh()
    }
}
