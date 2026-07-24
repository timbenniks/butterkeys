import Foundation

public struct PatternConfidenceTracker: Sendable {
    public static let acceptanceBoost = 0.08
    public static let undoPenalty = 0.18
    public static let repeatedUndoPenalty = 0.12

    public init() {}

    public func recordObservation(_ pattern: inout LearnedPatternRecord) {
        pattern.observedCount += 1
        pattern.lastSeenAt = Date()
        pattern.confidence = recalculateConfidence(for: pattern)
    }

    public func recordAcceptance(_ pattern: inout LearnedPatternRecord) {
        pattern.acceptedCount += 1
        pattern.confidence = min(1, pattern.confidence + Self.acceptanceBoost)
        pattern.lastSeenAt = Date()
    }

    public func recordUndo(_ pattern: inout LearnedPatternRecord) {
        pattern.undoCount += 1
        let penalty = Self.undoPenalty + Double(max(0, pattern.undoCount - 1)) * Self.repeatedUndoPenalty
        pattern.confidence = max(0, pattern.confidence - penalty)
        pattern.lastSeenAt = Date()
    }

    public func recalculateConfidence(for pattern: LearnedPatternRecord) -> Double {
        guard pattern.observedCount > 0 else { return 0 }

        let acceptanceRatio = Double(pattern.acceptedCount) / Double(pattern.observedCount)
        let undoRatio = Double(pattern.undoCount) / Double(max(pattern.observedCount, 1))
        let observationWeight = min(1, Double(pattern.observedCount) / 10.0)

        let base = 0.35 + acceptanceRatio * 0.45 + observationWeight * 0.15
        return min(max(base - undoRatio * 0.35, 0), 1)
    }

    public func undoPenaltyBoost(source: String, replacement: String, undoCount: Int) -> Double {
        guard undoCount > 0 else { return 0 }
        return min(0.5, Double(undoCount) * Self.undoPenalty)
    }
}
