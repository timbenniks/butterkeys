import Foundation

public enum TextReplacementResult: Sendable, Equatable {
    case success(CorrectionTransaction)
    case failure(TextReplacementFailure)
}

public enum TextReplacementFailure: Sendable, Equatable {
    case invalidPlan
    case emissionFailed
}

public struct TextReplacementExecutor: Sendable {
    private let emitter: SyntheticEventEmitter

    public init(emitter: SyntheticEventEmitter) {
        self.emitter = emitter
    }

    public func execute(
        plan: CorrectionTransactionPlan,
        strategyID: String,
        confidence: Double,
        appBundleID: String?
    ) -> TextReplacementResult {
        guard plan.isValid else {
            return .failure(.invalidPlan)
        }

        guard emitter.emitReplacement(
            original: plan.original,
            replacement: plan.replacement,
            boundary: plan.boundary
        ) else {
            return .failure(.emissionFailed)
        }

        let transaction = CorrectionTransaction(
            original: plan.original,
            replacement: plan.replacement,
            affectedCharacterCount: plan.original.count,
            boundary: plan.boundary,
            appBundleID: appBundleID,
            strategyID: strategyID,
            confidence: confidence,
            usedClipboard: false
        )
        return .success(transaction)
    }

    public func execute(
        candidate: CorrectionCandidate,
        boundary: Character?,
        appBundleID: String?
    ) -> TextReplacementResult {
        execute(
            plan: .forward(from: candidate, boundary: boundary),
            strategyID: candidate.strategyID,
            confidence: candidate.confidence,
            appBundleID: appBundleID
        )
    }

    public func executeReverse(
        transaction: CorrectionTransaction
    ) -> TextReplacementResult {
        execute(
            plan: .reverse(from: transaction),
            strategyID: transaction.strategyID,
            confidence: transaction.confidence,
            appBundleID: transaction.appBundleID
        )
    }

}
