import Foundation

public final class RuleCache: @unchecked Sendable {
    public static let shared = RuleCache()

    private let lock = NSLock()
    private var _rules: [CorrectionRuleRecord]

    private init() {
        _rules = DefaultRulesLoader.loadRecords()
    }

    public var rules: [CorrectionRuleRecord] {
        lock.lock()
        defer { lock.unlock() }
        return _rules
    }

    public func update(_ rules: [CorrectionRuleRecord]) {
        lock.lock()
        defer { lock.unlock() }
        _rules = rules
    }

}

enum StrategySupport {
    static let scorer = CandidateScorer()

    static func fastKeyIntervalBoost(_ timings: [TimeInterval], threshold: TimeInterval = 0.06) -> Double {
        guard timings.count >= 2 else { return 0 }
        for index in 1..<timings.count where timings[index] > timings[index - 1] {
            let interval = timings[index] - timings[index - 1]
            if interval > 0, interval <= threshold { return 0.08 }
        }
        return 0
    }

    static func sameMultiset(_ a: String, _ b: String) -> Bool {
        multiset(a) == multiset(b)
    }

    static func multiset(_ text: String) -> [Character: Int] {
        var counts: [Character: Int] = [:]
        for char in text.lowercased() {
            counts[char, default: 0] += 1
        }
        return counts
    }

    static func wholeWordMatch(_ token: String, _ pattern: String) -> Bool {
        token.lowercased() == pattern.lowercased()
    }

    static func phraseMatch(_ phrase: String, _ pattern: String) -> Bool {
        phrase.lowercased() == pattern.lowercased()
    }

    static func appliesToApp(_ rule: CorrectionRuleRecord, bundleID: String?) -> Bool {
        guard let scoped = rule.appBundleID else { return true }
        return scoped == bundleID
    }

    static func replacement(
        for rule: CorrectionRuleRecord,
        matched: String
    ) -> String {
        rule.preserveCase
            ? CasePatternPreserver.apply(pattern: matched, to: rule.replacement)
            : rule.replacement
    }
}
