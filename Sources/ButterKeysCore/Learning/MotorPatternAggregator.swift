import Foundation

public final class MotorPatternAggregator: Sendable {
    private let repository: MotorPatternRepository
    private let adjacency: KeyboardAdjacencyMap

    public init(repository: MotorPatternRepository, adjacency: KeyboardAdjacencyMap = .qwerty) {
        self.repository = repository
        self.adjacency = adjacency
    }

    public func recordAcceptedNearbyKeyCorrection(source: String, replacement: String) throws {
        guard source.count == replacement.count else { return }

        let sourceChars = Array(source.lowercased())
        let replacementChars = Array(replacement.lowercased())
        let now = Date()

        for index in sourceChars.indices where sourceChars[index] != replacementChars[index] {
            let from = sourceChars[index]
            let to = replacementChars[index]
            guard adjacency.areAdjacent(from, to) else { continue }

            try upsertNearbyPair(from: from, to: to, now: now)
        }
    }

    public func snapshot() throws -> MotorPatternSnapshot {
        let records = try repository.fetchAll(patternType: MotorPatternType.nearbyKeySubstitution.rawValue)
        var pairs: [String: Double] = [:]
        for record in records {
            let key = "\(record.sourceValue)↔\(record.observedValue)"
            pairs[key] = record.confidence
        }
        return MotorPatternSnapshot(nearbyKeyPairs: pairs, transpositionBias: 0, earlySpaceBias: 0)
    }

    private func upsertNearbyPair(from: Character, to: Character, now: Date) throws {
        let patternType = MotorPatternType.nearbyKeySubstitution.rawValue
        let sourceValue = String(from)
        let observedValue = String(to)

        if var existing = try repository.fetch(
            patternType: patternType,
            sourceValue: sourceValue,
            observedValue: observedValue
        ) {
            existing.occurrenceCount += 1
            existing.lastSeenAt = now
            existing.confidence = min(1, Double(existing.occurrenceCount) / 20.0)
            try repository.save(existing)
            return
        }

        let record = MotorPatternRecord(
            patternType: patternType,
            sourceValue: sourceValue,
            observedValue: observedValue,
            occurrenceCount: 1,
            confidence: 0.05,
            firstSeenAt: now,
            lastSeenAt: now
        )
        try repository.save(record)
    }
}
