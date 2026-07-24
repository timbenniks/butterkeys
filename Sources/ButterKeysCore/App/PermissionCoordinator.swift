import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import IOKit.hid
import OSLog

public struct PermissionStatus: Sendable, Equatable {
    public let inputMonitoringGranted: Bool
    public let accessibilityGranted: Bool

    public var allGranted: Bool {
        inputMonitoringGranted && accessibilityGranted
    }

    public init(inputMonitoringGranted: Bool, accessibilityGranted: Bool) {
        self.inputMonitoringGranted = inputMonitoringGranted
        self.accessibilityGranted = accessibilityGranted
    }
}

@MainActor
public final class PermissionCoordinator {
    public typealias Handler = @Sendable (PermissionStatus) -> Void

    private var pollTimer: Timer?
    private let pollInterval: TimeInterval
    private var onChange: Handler?
    private var lastStatus: PermissionStatus?
    private let logger = Logger(subsystem: "com.timbeniks.ButterKeys", category: "Permissions")

    public init(pollInterval: TimeInterval = 1.5) {
        self.pollInterval = pollInterval
    }

    public static func currentStatus() -> PermissionStatus {
        PermissionStatus(
            inputMonitoringGranted: isInputMonitoringGranted(),
            accessibilityGranted: isAccessibilityGranted()
        )
    }

    public static func isInputMonitoringGranted() -> Bool {
        // Prefer CG preflight; fall back to IOHID.
        if CGPreflightListenEventAccess() {
            return true
        }
        return IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
    }

    public static func isAccessibilityGranted() -> Bool {
        AXIsProcessTrusted()
    }

    public func startPolling(onChange: @escaping Handler) {
        self.onChange = onChange
        pollTimer?.invalidate()
        deliverCurrentStatus()

        pollTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.deliverCurrentStatus()
            }
        }
        if let pollTimer {
            RunLoop.main.add(pollTimer, forMode: .common)
        }
    }

    public func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
        onChange = nil
    }

    public func refresh() {
        // Always notify so UI can sync after the user toggles System Settings.
        let status = Self.currentStatus()
        lastStatus = status
        onChange?(status)
        logger.debug(
            "Permissions input=\(status.inputMonitoringGranted, privacy: .public) accessibility=\(status.accessibilityGranted, privacy: .public)"
        )
    }

    private func deliverCurrentStatus() {
        let status = Self.currentStatus()
        guard status != lastStatus else { return }
        lastStatus = status
        onChange?(status)
        logger.info(
            "Permission change input=\(status.inputMonitoringGranted, privacy: .public) accessibility=\(status.accessibilityGranted, privacy: .public)"
        )
    }

    /// Registers with TCC so ButterKeys appears in Input Monitoring.
    /// Safe to call on every launch; shows the system prompt only when needed.
    public func registerInputMonitoringWithTCC() {
        if Self.isInputMonitoringGranted() {
            logger.info("Input Monitoring already granted")
            return
        }
        // This is what makes the app show up in System Settings → Input Monitoring.
        let approved = CGRequestListenEventAccess()
        logger.info("CGRequestListenEventAccess returned \(approved, privacy: .public)")
        refresh()
    }

    /// Ask for Input Monitoring once. If already denied, opens System Settings instead.
    @discardableResult
    public func requestInputMonitoring() -> Bool {
        if Self.isInputMonitoringGranted() {
            return true
        }

        // Shows the system prompt the first time and registers the app in the list.
        let prompted = CGRequestListenEventAccess()
        refresh()
        if prompted || Self.isInputMonitoringGranted() {
            return Self.isInputMonitoringGranted()
        }

        openInputMonitoringSettings()
        return false
    }

    /// Accessibility cannot be granted via prompt reliably for already-running apps.
    /// Open System Settings and ask the user to enable ButterKeys, then relaunch.
    @discardableResult
    public func requestAccessibility() -> Bool {
        if Self.isAccessibilityGranted() {
            return true
        }

        // Avoid AXTrustedCheckOptionPrompt — it is flaky and can spam kernel task-port errors.
        openAccessibilitySettings()
        return false
    }

    public func openInputMonitoringSettings() {
        openPrivacyPane(candidates: [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ListenEvent",
            "x-apple.systempreferences:com.apple.Settings.PrivacySecurity.extension?Privacy_ListenEvent"
        ])
    }

    public func openAccessibilitySettings() {
        openPrivacyPane(candidates: [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.Settings.PrivacySecurity.extension?Privacy_Accessibility"
        ])
    }

    /// Opens the most relevant privacy pane for whatever is still missing.
    public func openMissingPermissionSettings() {
        let status = Self.currentStatus()
        if !status.inputMonitoringGranted {
            openInputMonitoringSettings()
        } else if !status.accessibilityGranted {
            openAccessibilitySettings()
        } else {
            openAccessibilitySettings()
        }
    }

    // MARK: - Private

    private func openPrivacyPane(candidates: [String]) {
        NSApp.activate(ignoringOtherApps: true)

        for candidate in candidates {
            guard let url = URL(string: candidate) else { continue }
            if NSWorkspace.shared.open(url) {
                logger.info("Opened System Settings via \(candidate, privacy: .public)")
                return
            }
        }

        // Last resort: open Privacy & Security root.
        if let fallback = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            NSWorkspace.shared.open(fallback)
            logger.warning("Fell back to Privacy & Security root pane")
        }
    }
}
