import Foundation

public struct ManualCorrectionDetector: Sendable {
    public static let maxTokenLength = 32

    private var deletedCharacters: [Character] = []
    private var pendingSource: String?

    public init() {}

    public mutating func reset() {
        deletedCharacters.removeAll(keepingCapacity: true)
        pendingSource = nil
    }

    public mutating func recordBackspace(removed: Character?) {
        guard let removed else { return }
        deletedCharacters.append(removed)
        if deletedCharacters.count > Self.maxTokenLength {
            deletedCharacters.removeFirst(deletedCharacters.count - Self.maxTokenLength)
        }
    }

    public mutating func recordRetypeStarted() {
        guard !deletedCharacters.isEmpty else { return }
        pendingSource = String(deletedCharacters.reversed())
        deletedCharacters.removeAll(keepingCapacity: true)
    }

    public mutating func evaluateBoundary(completedToken: String, appBundleID: String?) -> ManualCorrectionPair? {
        defer { pendingSource = nil }

        guard let source = pendingSource else { return nil }
        guard Self.isCompactToken(source), Self.isCompactToken(completedToken) else { return nil }
        guard source.caseInsensitiveCompare(completedToken) != .orderedSame else { return nil }

        return ManualCorrectionPair(
            source: source,
            replacement: completedToken,
            appBundleID: appBundleID
        )
    }

    public static func isCompactToken(_ token: String) -> Bool {
        guard !token.isEmpty, token.count <= maxTokenLength else { return false }
        guard !token.contains(where: \.isWhitespace) else { return false }
        return token.unicodeScalars.allSatisfy { scalar in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "-" || scalar == "'"
        }
    }
}
