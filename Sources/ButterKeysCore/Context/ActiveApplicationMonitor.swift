import AppKit
import Foundation
import OSLog

public struct ActiveApplicationInfo: Sendable, Equatable {
    public let bundleIdentifier: String?
    public let localizedName: String?

    public init(bundleIdentifier: String?, localizedName: String?) {
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
    }
}

public final class ActiveApplicationMonitor: @unchecked Sendable {
    public typealias Handler = @Sendable (ActiveApplicationInfo) -> Void

    private let logger = Logger(subsystem: "com.timbeniks.ButterKeys", category: "ActiveApplicationMonitor")
    private let handler: Handler
    private var observer: NSObjectProtocol?
    private let lock = NSLock()
    private var current: ActiveApplicationInfo

    public init(onActiveApplicationChanged: @escaping Handler) {
        self.handler = onActiveApplicationChanged
        self.current = Self.frontmostApplicationInfo()
    }

    deinit {
        stop()
    }

    public var currentApplication: ActiveApplicationInfo {
        lock.lock()
        defer { lock.unlock() }
        return current
    }

    public func start() {
        guard observer == nil else { return }

        refreshFrontmostApplication(notify: true)

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.refreshFrontmostApplication(notify: true)
        }
    }

    public func stop() {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            self.observer = nil
        }
    }

    public func refresh() {
        refreshFrontmostApplication(notify: false)
    }

    private func refreshFrontmostApplication(notify: Bool) {
        let info = Self.frontmostApplicationInfo()

        lock.lock()
        let changed = info != current
        current = info
        lock.unlock()

        if changed {
            logger.debug("Active application changed")
            if notify {
                handler(info)
            }
        }
    }

    private static func frontmostApplicationInfo() -> ActiveApplicationInfo {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return ActiveApplicationInfo(bundleIdentifier: nil, localizedName: nil)
        }
        return ActiveApplicationInfo(
            bundleIdentifier: app.bundleIdentifier,
            localizedName: app.localizedName
        )
    }
}
