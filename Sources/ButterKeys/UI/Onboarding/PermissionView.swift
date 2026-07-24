import AppKit
import ButterKeysCore
import SwiftUI

enum PermissionKind: String, CaseIterable, Identifiable {
    case inputMonitoring
    case accessibility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inputMonitoring: "Input Monitoring"
        case .accessibility: "Accessibility"
        }
    }

    var explanation: String {
        switch self {
        case .inputMonitoring:
            "ButterKeys needs Input Monitoring so it can notice typing mistakes across your apps.\n\nKeystrokes are processed locally and are not stored as a typing log."
        case .accessibility:
            "ButterKeys needs Accessibility permission so it can replace a typo with corrected text.\n\nIt only changes text for rules you teach (or high-confidence pattern modes you enable)."
        }
    }

    var settingsHint: String {
        switch self {
        case .inputMonitoring:
            "System Settings → Privacy & Security → Input Monitoring → enable ButterKeys."
        case .accessibility:
            "System Settings → Privacy & Security → Accessibility → enable ButterKeys.\n\nAfter enabling Accessibility, quit ButterKeys and launch it again."
        }
    }
}

struct PermissionView: View {
    @Bindable var appState: AppState
    let permissionCoordinator: PermissionCoordinator
    let kind: PermissionKind
    let onContinue: () -> Void

    private var isGranted: Bool {
        switch kind {
        case .inputMonitoring: appState.inputMonitoringGranted
        case .accessibility: appState.accessibilityGranted
        }
    }

    var body: some View {
        OnboardingStepContainer {
            VStack(alignment: .leading, spacing: 20) {
                Text(kind.title)
                    .font(.title.bold())

                Text(kind.explanation)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isGranted ? .green : .secondary)
                    Text(isGranted ? "Permission granted" : "Permission required")
                        .foregroundStyle(isGranted ? .primary : .secondary)
                }
                .padding(.vertical, 4)

                Text(kind.settingsHint)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Button("Open System Settings") {
                        openSettings()
                    }
                    .keyboardShortcut(.defaultAction)

                    Button("Check again") {
                        permissionCoordinator.refresh()
                        // Force AppState to pick up current status even if unchanged vs last poll.
                        let status = PermissionCoordinator.currentStatus()
                        appState.updatePermissions(
                            inputMonitoring: status.inputMonitoringGranted,
                            accessibility: status.accessibilityGranted
                        )
                    }
                }

                if kind == .accessibility, !isGranted {
                    Text("Running from Xcode? Grant permission to the DerivedData ButterKeys binary, then stop and run again.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                HStack {
                    Spacer()
                    Button(isGranted ? "Continue" : "Skip for now") {
                        onContinue()
                    }
                    .controlSize(.large)
                }
            }
        }
        .onAppear {
            permissionCoordinator.refresh()
            let status = PermissionCoordinator.currentStatus()
            appState.updatePermissions(
                inputMonitoring: status.inputMonitoringGranted,
                accessibility: status.accessibilityGranted
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissionCoordinator.refresh()
            let status = PermissionCoordinator.currentStatus()
            appState.updatePermissions(
                inputMonitoring: status.inputMonitoringGranted,
                accessibility: status.accessibilityGranted
            )
        }
    }

    private func openSettings() {
        switch kind {
        case .inputMonitoring:
            // One system prompt if never asked; otherwise opens Settings.
            _ = permissionCoordinator.requestInputMonitoring()
            permissionCoordinator.openInputMonitoringSettings()
        case .accessibility:
            permissionCoordinator.openAccessibilitySettings()
        }
    }
}
