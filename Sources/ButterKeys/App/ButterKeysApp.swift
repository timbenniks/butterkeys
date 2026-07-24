import AppKit
import ButterKeysCore
import SwiftUI

@main
struct ButterKeysApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var session: AppSession

    init() {
        let session = AppSession()
        _session = State(initialValue: session)
        AppDelegate.session = session
        // Start Sparkle early so scheduled checks work; never passes typing data.
        _ = SparkleUpdateController.shared
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                appState: session.appState,
                permissionCoordinator: session.permissionCoordinator
            )
        } label: {
            MenuBarStatusIcon(
                status: session.appState.status,
                permissionsGranted: session.appState.permissionsGranted
            )
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsRootView(appState: session.appState)
        }

        Window("Welcome to ButterKeys", id: WindowCoordinator.onboardingWindowID) {
            OnboardingFlow(
                appState: session.appState,
                permissionCoordinator: session.permissionCoordinator
            )
            .frame(minWidth: 520, minHeight: 600)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

@MainActor
final class AppSession {
    let appState: AppState
    let engineController: EngineController
    let permissionCoordinator: PermissionCoordinator

    init() {
        let database = DatabaseManager.shared
        let state = AppState(database: database)
        let engine = EngineController(appState: state, database: database)
        state.attachEngine(engine)
        appState = state
        engineController = engine
        permissionCoordinator = PermissionCoordinator()
    }

    func bootstrap() {
        appState.reload()
        engineController.bootstrap()
        permissionCoordinator.startPolling { [weak appState, weak engineController] status in
            Task { @MainActor in
                guard let appState, let engineController else { return }
                appState.updatePermissions(
                    inputMonitoring: status.inputMonitoringGranted,
                    accessibility: status.accessibilityGranted
                )
                engineController.updatePermissionState(granted: status.allGranted)
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var session: AppSession?
    private var onboardingWindow: NSWindow?
    private var windowCloseObserver: NSObjectProtocol?
    private var correctionObserver: NSObjectProtocol?
    private var teachShortcutObserver: NSObjectProtocol?
    private var teachRuleObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let session = Self.session else { return }
        session.bootstrap()

        // Register with TCC immediately so ButterKeys appears under Input Monitoring.
        session.permissionCoordinator.registerInputMonitoringWithTCC()

        windowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                let hasKeyWindow = NSApp.windows.contains { $0.isVisible && $0.canBecomeKey }
                if !hasKeyWindow {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }

        correctionObserver = NotificationCenter.default.addObserver(
            forName: .butterKeysDidApplyCorrection,
            object: nil,
            queue: .main
        ) { note in
            guard let source = note.userInfo?["source"] as? String,
                  let replacement = note.userInfo?["replacement"] as? String,
                  let session = AppDelegate.session
            else { return }
            CorrectionFeedback.present(
                source: source,
                replacement: replacement,
                settings: session.appState.settings,
                copy: session.appState.copy
            )
        }

        teachShortcutObserver = NotificationCenter.default.addObserver(
            forName: .butterKeysTeachShortcut,
            object: nil,
            queue: .main
        ) { _ in
            guard let session = AppDelegate.session else { return }
            TeachCapturePanel.present(appState: session.appState)
        }

        teachRuleObserver = NotificationCenter.default.addObserver(
            forName: .butterKeysDidTeachRule,
            object: nil,
            queue: .main
        ) { note in
            guard let source = note.userInfo?["source"] as? String,
                  let replacement = note.userInfo?["replacement"] as? String,
                  let session = AppDelegate.session
            else { return }
            CorrectionFeedback.presentTaught(
                source: source,
                replacement: replacement,
                settings: session.appState.settings,
                copy: session.appState.copy
            )
        }

        // Stay a menu-bar agent, but briefly allow activation so the welcome window can front.
        if !session.appState.settings.onboardingCompleted {
            showOnboarding(session: session)
        }
    }

    private func showOnboarding(session: AppSession) {
        if onboardingWindow != nil { return }

        NSApp.setActivationPolicy(.regular)

        let root = OnboardingFlow(
            appState: session.appState,
            permissionCoordinator: session.permissionCoordinator
        )
        .frame(width: 520, height: 600)

        let hosting = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Welcome to ButterKeys"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.setContentSize(NSSize(width: 520, height: 600))
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }
}
