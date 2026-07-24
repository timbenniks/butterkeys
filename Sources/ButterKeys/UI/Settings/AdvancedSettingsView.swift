import ButterKeysCore
import SwiftUI

struct AdvancedSettingsView: View {
    @Bindable var appState: AppState
    @State private var copiedDiagnostics = false

    var body: some View {
        Form {
            Section("Replacement") {
                Toggle("Clipboard fallback", isOn: clipboardBinding)
            }

            Section("Diagnostics") {
                Toggle("Debug logging", isOn: debugBinding)

                LabeledContent("Event tap") {
                    Text(tapLabel)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Frontmost app") {
                    Text(appState.engineFrontmostBundleID)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                LabeledContent("App mode") {
                    Text(appState.engineApplicationModeLabel)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Last correction") {
                    if let last = appState.lastCorrection {
                        Text("\(last.source) → \(last.replacement)")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("none")
                            .foregroundStyle(.secondary)
                    }
                }

                Button(copiedDiagnostics ? "Copied" : "Copy redacted diagnostics") {
                    appState.copyDiagnosticsToPasteboard()
                    copiedDiagnostics = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copiedDiagnostics = false
                    }
                }

                Text("Diagnostics never include sentences or raw keystrokes — only compact correction pairs and status.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Status") {
                LabeledContent("Monitoring") {
                    Text(appState.copy.monitoringStatus(appState.status))
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Input Monitoring") {
                    Text(appState.inputMonitoringGranted ? "Granted" : "Required")
                        .foregroundStyle(appState.inputMonitoringGranted ? .green : .secondary)
                }
                LabeledContent("Accessibility") {
                    Text(appState.accessibilityGranted ? "Granted" : "Required")
                        .foregroundStyle(appState.accessibilityGranted ? .green : .secondary)
                }
                LabeledContent("Version") {
                    Text(AppVersion.display)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var tapLabel: String {
        guard let state = appState.engineEventTapState else { return "—" }
        switch state {
        case .running: return "Running"
        case .paused: return "Paused"
        case .stopped: return "Stopped"
        }
    }

    private var clipboardBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.clipboardFallbackEnabled },
            set: { appState.settings.clipboardFallbackEnabled = $0; appState.applySettings() }
        )
    }

    private var debugBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.debugLogging },
            set: { appState.settings.debugLogging = $0; appState.applySettings() }
        )
    }
}
