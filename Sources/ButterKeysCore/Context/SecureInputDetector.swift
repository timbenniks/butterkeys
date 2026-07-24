import Carbon
import Foundation
import OSLog

public final class SecureInputDetector: @unchecked Sendable {
    private let logger = Logger(subsystem: "com.timbeniks.ButterKeys", category: "SecureInputDetector")
    private let lock = NSLock()
    private var timer: DispatchSourceTimer?
    private var isSecureInputEnabled = false

    public init() {}

    deinit {
        stopPeriodicChecks()
    }

    public var secureInputActive: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isSecureInputEnabled
    }

    @discardableResult
    public func checkNow() -> Bool {
        let enabled = IsSecureEventInputEnabled()
        lock.lock()
        let changed = enabled != isSecureInputEnabled
        isSecureInputEnabled = enabled
        lock.unlock()

        if changed {
            logger.debug("Secure event input state changed")
        }
        return enabled
    }

    public func startPeriodicChecks(interval: TimeInterval = 0.5, queue: DispatchQueue = .global(qos: .utility)) {
        stopPeriodicChecks()

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [weak self] in
            _ = self?.checkNow()
        }
        timer.resume()

        lock.lock()
        self.timer = timer
        lock.unlock()
    }

    public func stopPeriodicChecks() {
        lock.lock()
        timer?.cancel()
        timer = nil
        lock.unlock()
    }
}
