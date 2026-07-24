import Foundation

public struct KeystrokeTimingTracker: Sendable {
    public static let defaultCapacity = 16

    private var lastTimestamp: TimeInterval?
    private var intervals: [TimeInterval]
    private let capacity: Int

    public init(capacity: Int = Self.defaultCapacity) {
        self.capacity = max(1, capacity)
        self.intervals = []
    }

    public mutating func record(timestamp: TimeInterval) {
        if let last = lastTimestamp {
            let interval = max(0, timestamp - last)
            intervals.append(interval)
            if intervals.count > capacity {
                intervals.removeFirst(intervals.count - capacity)
            }
        }
        lastTimestamp = timestamp
    }

    public mutating func reset() {
        lastTimestamp = nil
        intervals.removeAll(keepingCapacity: true)
    }

    public var recentIntervals: [TimeInterval] {
        intervals
    }
}
