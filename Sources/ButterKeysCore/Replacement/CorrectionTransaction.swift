import Foundation

public struct CorrectionTransactionPlan: Sendable, Equatable {
    public let original: String
    public let replacement: String
    public let boundary: Character?

    public init(original: String, replacement: String, boundary: Character?) {
        self.original = original
        self.replacement = replacement
        self.boundary = boundary
    }

    public var deleteCount: Int {
        original.count + (boundary != nil ? 1 : 0)
    }

    public var insertText: String {
        guard let boundary else { return replacement }
        return replacement + String(boundary)
    }

    public var isValid: Bool {
        !original.isEmpty
            && !replacement.isEmpty
            && original != replacement
            && deleteCount > 0
    }

    public static func forward(from candidate: CorrectionCandidate, boundary: Character?) -> CorrectionTransactionPlan {
        CorrectionTransactionPlan(
            original: candidate.original,
            replacement: candidate.replacement,
            boundary: boundary
        )
    }

    public static func reverse(from transaction: CorrectionTransaction) -> CorrectionTransactionPlan {
        CorrectionTransactionPlan(
            original: transaction.replacement,
            replacement: transaction.original,
            boundary: transaction.boundary
        )
    }
}

public struct CorrectionTransaction: Sendable, Equatable, Identifiable {
    public let id: String
    public let original: String
    public let replacement: String
    public let affectedCharacterCount: Int
    public let boundary: Character?
    public let appBundleID: String?
    public let timestamp: Date
    public let strategyID: String
    public let confidence: Double
    public let usedClipboard: Bool

    public init(
        id: String = UUID().uuidString,
        original: String,
        replacement: String,
        affectedCharacterCount: Int,
        boundary: Character?,
        appBundleID: String?,
        timestamp: Date = Date(),
        strategyID: String,
        confidence: Double,
        usedClipboard: Bool = false
    ) {
        self.id = id
        self.original = original
        self.replacement = replacement
        self.affectedCharacterCount = affectedCharacterCount
        self.boundary = boundary
        self.appBundleID = appBundleID
        self.timestamp = timestamp
        self.strategyID = strategyID
        self.confidence = confidence
        self.usedClipboard = usedClipboard
    }

    public var plan: CorrectionTransactionPlan {
        CorrectionTransactionPlan(original: original, replacement: replacement, boundary: boundary)
    }

    public static func from(
        candidate: CorrectionCandidate,
        boundary: Character?,
        appBundleID: String?,
        usedClipboard: Bool = false
    ) -> CorrectionTransaction {
        CorrectionTransaction(
            original: candidate.original,
            replacement: candidate.replacement,
            affectedCharacterCount: candidate.original.count,
            boundary: boundary,
            appBundleID: appBundleID,
            strategyID: candidate.strategyID,
            confidence: candidate.confidence,
            usedClipboard: usedClipboard
        )
    }

    public func historyRecord(wasUndone: Bool = false) -> CorrectionHistoryRecord {
        CorrectionHistoryRecord(
            id: id,
            source: original,
            replacement: replacement,
            correctionType: strategyID,
            appBundleID: appBundleID,
            confidence: confidence,
            wasUndone: wasUndone,
            createdAt: timestamp
        )
    }
}
