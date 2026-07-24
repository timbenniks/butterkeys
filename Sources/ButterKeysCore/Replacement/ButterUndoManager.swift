import Foundation

public final class ButterUndoManager: @unchecked Sendable {
    private let lock = NSLock()
    private let executor: TextReplacementExecutor
    private let historyRepository: CorrectionHistoryRepository?
    private var lastTransaction: CorrectionTransaction?
    private let transactionLifetime: TimeInterval

    public init(
        executor: TextReplacementExecutor,
        historyRepository: CorrectionHistoryRepository? = nil,
        transactionLifetime: TimeInterval = 300
    ) {
        self.executor = executor
        self.historyRepository = historyRepository
        self.transactionLifetime = transactionLifetime
    }

    public var canUndo: Bool {
        lock.lock()
        defer { lock.unlock() }
        return validTransaction() != nil
    }

    public func record(_ transaction: CorrectionTransaction) {
        lock.lock()
        lastTransaction = transaction
        lock.unlock()
    }

    @discardableResult
    public func performUndo() -> Bool {
        lock.lock()
        guard let transaction = validTransaction() else {
            lock.unlock()
            return false
        }
        lastTransaction = nil
        lock.unlock()

        switch executor.executeReverse(transaction: transaction) {
        case .success:
            if let historyRepository {
                try? historyRepository.markUndone(id: transaction.id)
            }
            return true
        case .failure:
            lock.lock()
            lastTransaction = transaction
            lock.unlock()
            return false
        }
    }

    public func clear() {
        lock.lock()
        lastTransaction = nil
        lock.unlock()
    }

    private func validTransaction() -> CorrectionTransaction? {
        guard let transaction = lastTransaction else { return nil }
        if Date().timeIntervalSince(transaction.timestamp) > transactionLifetime {
            lastTransaction = nil
            return nil
        }
        return transaction
    }
}
