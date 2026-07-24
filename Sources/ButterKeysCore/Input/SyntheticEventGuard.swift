import Foundation

public final class SyntheticEventGuard: @unchecked Sendable {
    private let lock = NSLock()
    private var generation: UInt64 = 0
    private var recentTimestamps: [TimeInterval] = []
    private let maxEntries = 32
    private let timestampTolerance: TimeInterval = 0.002

    public init() {}

    public func nextGeneration() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        generation &+= 1
        return generation
    }

    public func markSynthetic(timestamp: TimeInterval, generation: UInt64? = nil) {
        lock.lock()
        defer { lock.unlock() }
        recentTimestamps.append(timestamp)
        if recentTimestamps.count > maxEntries {
            recentTimestamps.removeFirst(recentTimestamps.count - maxEntries)
        }
        if let generation {
            self.generation = max(self.generation, generation)
        }
    }

    public func isSynthetic(_ event: NormalizedKeyEvent) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if let eventGeneration = event.syntheticGeneration, eventGeneration <= generation {
            return true
        }

        return recentTimestamps.contains { abs($0 - event.timestamp) <= timestampTolerance }
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        recentTimestamps.removeAll(keepingCapacity: true)
    }
}
