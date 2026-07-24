import AppKit
import ButterKeysCore
import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState
    let permissionCoordinator: PermissionCoordinator

    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    private var copy: CopyProvider { appState.copy }

    var body: some View {
        Group {
            Text(headlineStatus)

            Text("Smoothed today: \(appState.smoothedToday)")

            if !appState.permissionsGranted {
                Text(permissionDetail)
                Text("Input Monitoring: \(appState.inputMonitoringGranted ? "on" : "off")")
                Text("Accessibility: \(appState.accessibilityGranted ? "on" : "off")")
            }

            if let last = appState.lastCorrection {
                LastCorrectionView(
                    source: last.source,
                    replacement: last.replacement,
                    copy: copy
                )
                Button("Protect “\(last.source)”") {
                    appState.protectWord(last.source)
                }
            }

            Divider()

            Button(copy.teachFromSelectionLabel) {
                TeachCapturePanel.present(appState: appState)
            }
            .disabled(!appState.permissionsGranted)

            Button(copy.undoLastLabel) {
                appState.undoLast()
            }
            .disabled(!appState.settings.enabled)

            Menu(copy.pauseCorrectionsTitle) {
                Button("Pause for 15 minutes") {
                    appState.pause(for: 15 * 60)
                }
                Button("Pause for 1 hour") {
                    appState.pause(for: 60 * 60)
                }
                Button("Pause until tomorrow") {
                    appState.pauseUntilTomorrow()
                }
                Button("Pause in this app") {
                    appState.pauseInCurrentApp()
                }
            }

            if appState.isPaused {
                Button("Resume smoothing") {
                    appState.resume()
                }
            }

            Button(appState.settings.enabled ? "Stop smoothing" : "Start smoothing") {
                appState.toggleEnabled()
            }

            Divider()

            if !appState.permissionsGranted {
                Button("Fix permissions…") {
                    syncPermissions()
                    permissionCoordinator.openMissingPermissionSettings()
                }

                if appState.inputMonitoringGranted && !appState.accessibilityGranted {
                    Button("Open Accessibility settings") {
                        permissionCoordinator.openAccessibilitySettings()
                    }
                }

                Button("Recheck permissions") {
                    syncPermissions()
                }
            }

            Button("Settings…") {
                openButterKeysSettings()
            }

            Button("Check for Updates…") {
                SparkleUpdateController.shared.checkForUpdates()
            }
            .disabled(!SparkleUpdateController.shared.canCheckForUpdates)

            Divider()

            Button(copy.quitLabel) {
                NSApplication.shared.terminate(nil)
            }
        }
        .font(.body)
        .onAppear {
            syncPermissions()
        }
    }

    private var headlineStatus: String {
        if !appState.permissionsGranted {
            return copy.permissionStatusSummary(
                inputMonitoring: appState.inputMonitoringGranted,
                accessibility: appState.accessibilityGranted
            )
        }
        return copy.monitoringStatus(appState.status)
    }

    private var permissionDetail: String {
        if appState.inputMonitoringGranted && !appState.accessibilityGranted {
            return "Enable Accessibility, then quit and reopen from Applications."
        }
        if !appState.inputMonitoringGranted {
            return "Enable Input Monitoring, then quit and reopen from Applications."
        }
        return "Grant both permissions, then quit and reopen from Applications."
    }

    private func syncPermissions() {
        let status = PermissionCoordinator.currentStatus()
        appState.updatePermissions(
            inputMonitoring: status.inputMonitoringGranted,
            accessibility: status.accessibilityGranted
        )
        permissionCoordinator.refresh()
    }

    private func openButterKeysSettings() {
        // Menu bar agents stay inactive by default; force activation so Settings comes forward.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        openSettings()

        DispatchQueue.main.async {
            NSApp.windows
                .filter(\.isVisible)
                .forEach { $0.makeKeyAndOrderFront(nil) }
        }
    }
}
