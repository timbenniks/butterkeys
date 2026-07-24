import Carbon
import Foundation
import OSLog

public final class InputSourceMonitor: @unchecked Sendable {
    public typealias Handler = @Sendable () -> Void

    private let logger = Logger(subsystem: "com.timbeniks.ButterKeys", category: "InputSourceMonitor")
    private var observerToken: UnsafeMutableRawPointer?
    private let handler: Handler

    public init(onInputSourceChanged: @escaping Handler) {
        self.handler = onInputSourceChanged
    }

    deinit {
        stop()
    }

    public func start() {
        guard observerToken == nil else { return }

        let token = Unmanaged.passUnretained(self).toOpaque()
        observerToken = token

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDistributedCenter(),
            token,
            { _, observer, _, _, _ in
                guard let observer else { return }
                let monitor = Unmanaged<InputSourceMonitor>.fromOpaque(observer).takeUnretainedValue()
                monitor.logger.debug("Keyboard input source changed")
                monitor.handler()
            },
            kTISNotifySelectedKeyboardInputSourceChanged as CFString,
            nil,
            .deliverImmediately
        )
    }

    public func stop() {
        guard let token = observerToken else { return }
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDistributedCenter(),
            token,
            CFNotificationName(kTISNotifySelectedKeyboardInputSourceChanged as CFString),
            nil
        )
        observerToken = nil
    }
}
