import Foundation

public enum CasePatternPreserver {
    public static func apply(pattern from: String, to target: String) -> String {
        guard !from.isEmpty, !target.isEmpty else { return target }

        if from == from.uppercased(), from.contains(where: \.isLetter) {
            return target.uppercased()
        }
        if from.first?.isUppercase == true, from.dropFirst().allSatisfy({ !$0.isLetter || $0.isLowercase }) {
            guard let first = target.first else { return target }
            return String(first).uppercased() + target.dropFirst().lowercased()
        }
        if from == from.lowercased() {
            return target.lowercased()
        }
        // Bizarre mixed case: prefer lowercase target rather than inventing a pattern.
        return target.lowercased()
    }
}

public enum DamerauLevenshtein {
    public static func distance(_ a: String, _ b: String, max: Int = 4) -> Int {
        let aChars = Array(a.lowercased())
        let bChars = Array(b.lowercased())
        let n = aChars.count
        let m = bChars.count
        if abs(n - m) > max { return max + 1 }
        if n == 0 { return m }
        if m == 0 { return n }

        var prev = Array(0...m)
        var curr = Array(repeating: 0, count: m + 1)
        var prevPrev = Array(repeating: 0, count: m + 1)

        for i in 1...n {
            curr[0] = i
            var rowMin = curr[0]
            for j in 1...m {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                var value = min(
                    prev[j] + 1,
                    curr[j - 1] + 1,
                    prev[j - 1] + cost
                )
                if i > 1, j > 1,
                   aChars[i - 1] == bChars[j - 2],
                   aChars[i - 2] == bChars[j - 1] {
                    value = min(value, prevPrev[j - 2] + cost)
                }
                curr[j] = value
                rowMin = min(rowMin, value)
            }
            if rowMin > max { return max + 1 }
            prevPrev = prev
            prev = curr
        }
        return prev[m]
    }
}
