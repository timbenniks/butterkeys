import Foundation

public final class UserRejectionTracker: @unchecked Sendable {
    private let lock = NSLock()
    private var decisions: [String: UserPatternDecision] = [:]

    public init() {}

    public func record(_ decision: UserPatternDecision, source: String, replacement: String) {
        lock.lock()
        decisions[Self.pairKey(source: source, replacement: replacement)] = decision
        lock.unlock()
    }

    public func decision(for source: String, replacement: String) -> UserPatternDecision? {
        lock.lock()
        defer { lock.unlock() }
        return decisions[Self.pairKey(source: source, replacement: replacement)]
    }

    public func behaviour(for source: String, replacement: String) -> RuleBehaviour? {
        switch decision(for: source, replacement: replacement) {
        case .acceptAutomatic: return .automatic
        case .acceptSuggestOnly, .reject: return .suggestion
        case .never: return .never
        case nil: return nil
        }
    }

    public func isBlocked(source: String, replacement: String) -> Bool {
        behaviour(for: source, replacement: replacement) == .never
    }

    public func isSuggestOnly(source: String, replacement: String) -> Bool {
        switch decision(for: source, replacement: replacement) {
        case .acceptSuggestOnly, .reject: return true
        default: return false
        }
    }

    public func allDecisions() -> [String: UserPatternDecision] {
        lock.lock()
        defer { lock.unlock() }
        return decisions
    }

    public func remove(source: String, replacement: String) {
        lock.lock()
        decisions.removeValue(forKey: Self.pairKey(source: source, replacement: replacement))
        lock.unlock()
    }

    public func clear() {
        lock.lock()
        decisions.removeAll(keepingCapacity: true)
        lock.unlock()
    }

    private static func pairKey(source: String, replacement: String) -> String {
        "\(source.lowercased())→\(replacement.lowercased())"
    }
}
