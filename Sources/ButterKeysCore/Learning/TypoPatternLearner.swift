import Foundation

public final class TypoPatternLearner: @unchecked Sendable {
    private let lock = NSLock()
    private let repository: LearnedPatternRepository
    private let confidenceTracker: PatternConfidenceTracker
    private let rejectionTracker: UserRejectionTracker
    private var suggestionThreshold: Int

    public init(
        repository: LearnedPatternRepository,
        confidenceTracker: PatternConfidenceTracker = PatternConfidenceTracker(),
        rejectionTracker: UserRejectionTracker,
        suggestionThreshold: Int = 3
    ) {
        self.repository = repository
        self.confidenceTracker = confidenceTracker
        self.rejectionTracker = rejectionTracker
        self.suggestionThreshold = max(2, suggestionThreshold)
    }

    public func updateSuggestionThreshold(_ value: Int) {
        lock.lock()
        suggestionThreshold = max(2, value)
        lock.unlock()
    }

    @discardableResult
    public func observeManualCorrection(_ pair: ManualCorrectionPair) throws -> LearnedPatternRecord? {
        guard ManualCorrectionDetector.isCompactToken(pair.source),
              ManualCorrectionDetector.isCompactToken(pair.replacement) else {
            return nil
        }
        if rejectionTracker.isBlocked(source: pair.source, replacement: pair.replacement) {
            return nil
        }

        var pattern = try existingPattern(source: pair.source, replacement: pair.replacement, appBundleID: pair.appBundleID)
            ?? LearnedPatternRecord(
                source: pair.source,
                replacement: pair.replacement,
                patternType: LearnedPatternType.manualCorrection.rawValue,
                appBundleID: pair.appBundleID,
                status: LearnedPatternStatus.observing.rawValue
            )

        confidenceTracker.recordObservation(&pattern)
        pattern.status = resolvedStatus(for: pattern).rawValue
        try repository.save(pattern)
        return pattern
    }

    @discardableResult
    public func observeAcceptedCorrection(
        source: String,
        replacement: String,
        appBundleID: String?,
        patternType: LearnedPatternType = .acceptedCorrection
    ) throws -> LearnedPatternRecord? {
        guard ManualCorrectionDetector.isCompactToken(source),
              ManualCorrectionDetector.isCompactToken(replacement) else {
            return nil
        }

        var pattern = try existingPattern(source: source, replacement: replacement, appBundleID: appBundleID)
            ?? LearnedPatternRecord(
                source: source,
                replacement: replacement,
                patternType: patternType.rawValue,
                appBundleID: appBundleID,
                status: LearnedPatternStatus.observing.rawValue
            )

        confidenceTracker.recordAcceptance(&pattern)
        pattern.status = resolvedStatus(for: pattern).rawValue
        try repository.save(pattern)
        return pattern
    }

    public func shouldSuggest(_ pattern: LearnedPatternRecord) -> Bool {
        let threshold = currentThreshold()
        guard pattern.status == LearnedPatternStatus.pendingSuggestion.rawValue
                || pattern.status == LearnedPatternStatus.observing.rawValue else {
            return false
        }
        return pattern.observedCount >= threshold
            && !rejectionTracker.isBlocked(source: pattern.source, replacement: pattern.replacement)
    }

    public func pendingSuggestions() throws -> [LearnedPatternSuggestion] {
        try repository.fetchAll(status: LearnedPatternStatus.pendingSuggestion.rawValue)
            .filter(shouldSuggest)
            .map(LearnedPatternSuggestion.init)
    }

    private func currentThreshold() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return suggestionThreshold
    }

    private func existingPattern(
        source: String,
        replacement: String,
        appBundleID: String?
    ) throws -> LearnedPatternRecord? {
        try repository.fetchAll()
            .first {
                $0.source.caseInsensitiveCompare(source) == .orderedSame
                    && $0.replacement.caseInsensitiveCompare(replacement) == .orderedSame
                    && $0.appBundleID == appBundleID
            }
    }

    private func resolvedStatus(for pattern: LearnedPatternRecord) -> LearnedPatternStatus {
        if rejectionTracker.isBlocked(source: pattern.source, replacement: pattern.replacement) {
            return .never
        }
        if rejectionTracker.isSuggestOnly(source: pattern.source, replacement: pattern.replacement) {
            return .suggestOnly
        }
        if pattern.observedCount >= currentThreshold() {
            return .pendingSuggestion
        }
        return LearnedPatternStatus(rawValue: pattern.status) ?? .observing
    }
}
