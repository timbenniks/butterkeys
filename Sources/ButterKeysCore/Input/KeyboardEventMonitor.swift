import AppKit
import CoreGraphics
import Foundation
import OSLog

public final class KeyboardEventMonitor: NSObject, @unchecked Sendable {
    public enum State: Sendable, Equatable {
        case stopped
        case running
        case paused
    }

    private let logger = Logger(subsystem: "com.timbeniks.ButterKeys", category: "KeyboardEventMonitor")
    private let processor: KeyboardEventProcessor
    private let eventMask: CGEventMask = (
        (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
            | (1 << CGEventType.tapDisabledByTimeout.rawValue)
            | (1 << CGEventType.tapDisabledByUserInput.rawValue)
    )

    private var monitorThread: Thread?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var state: State = .stopped
    private let stateLock = NSLock()

    public init(processor: KeyboardEventProcessor) {
        self.processor = processor
        super.init()
    }

    public var currentState: State {
        stateLock.lock()
        defer { stateLock.unlock() }
        return state
    }

    public func start() {
        stateLock.lock()
        guard state == .stopped else {
            stateLock.unlock()
            return
        }
        state = .running
        stateLock.unlock()

        let thread = Thread { [weak self] in
            self?.runMonitorLoop()
        }
        thread.name = "com.timbeniks.ButterKeys.keyboard-monitor"
        monitorThread = thread
        thread.start()
    }

    public func stop() {
        stateLock.lock()
        state = .stopped
        stateLock.unlock()

        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource {
            CFRunLoopSourceInvalidate(runLoopSource)
        }

        if let monitorThread {
            perform(#selector(stopRunLoop), on: monitorThread, with: nil, waitUntilDone: true)
        }

        eventTap = nil
        runLoopSource = nil
        monitorThread = nil
    }

    public func pause() {
        stateLock.lock()
        guard state == .running else {
            stateLock.unlock()
            return
        }
        state = .paused
        stateLock.unlock()
        processor.pause()
    }

    public func resume() {
        stateLock.lock()
        guard state == .paused else {
            stateLock.unlock()
            return
        }
        state = .running
        stateLock.unlock()
        processor.resume()
    }

    @objc private func stopRunLoop() {
        CFRunLoopStop(CFRunLoopGetCurrent())
    }

    private func runMonitorLoop() {
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard
            let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .listenOnly,
                eventsOfInterest: eventMask,
                callback: Self.eventTapCallback,
                userInfo: refcon
            )
        else {
            logger.error("Failed to create keyboard event tap")
            stateLock.lock()
            state = .stopped
            stateLock.unlock()
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
        logger.debug("Keyboard event tap started")
        CFRunLoopRun()
        logger.debug("Keyboard event tap thread exiting")
    }

    private func reenableTap() {
        guard let eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: true)
        logger.notice("Re-enabled keyboard event tap after disable")
    }

    fileprivate func handle(eventType: CGEventType, event: CGEvent) {
        switch eventType {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            reenableTap()
            return
        default:
            break
        }

        stateLock.lock()
        let paused = state != .running
        stateLock.unlock()
        if paused { return }

        let normalizedType: KeyEventType?
        switch eventType {
        case .keyDown: normalizedType = .keyDown
        case .keyUp: normalizedType = .keyUp
        case .flagsChanged: normalizedType = .flagsChanged
        default: normalizedType = nil
        }

        guard let normalizedType else { return }
        let normalized = NormalizedKeyEvent.from(event, type: normalizedType)
        processor.enqueue(normalized)
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else { return Unmanaged.passUnretained(event) }

        let monitor = Unmanaged<KeyboardEventMonitor>.fromOpaque(userInfo).takeUnretainedValue()
        monitor.handle(eventType: type, event: event)
        return Unmanaged.passUnretained(event)
    }
}
