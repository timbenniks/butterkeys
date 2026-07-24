import ButterKeysCore
import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var appState: AppState

    private var copy: CopyProvider { appState.copy }

    private let reportURL = URL(string: "https://github.com/timbenniks/butterkeys/issues/new/choose")!
    private let privacyURL = URL(string: "https://github.com/timbenniks/butterkeys/blob/main/docs/privacy/PRIVACY.md")!

    var body: some View {
        Form {
            Section {
                Toggle("Enable ButterKeys", isOn: enabledBinding)
                Toggle("Launch at login", isOn: launchAtLoginBinding)
            }

            Section(copy.automaticCorrectionsTitle) {
                Picker("Auto-correct", selection: confidenceBinding) {
                    ForEach(ConfidencePreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }

                Text(appState.settings.confidencePreset.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LabeledContent("Teach shortcut") {
                    Text(appState.settings.teachShortcut)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Undo shortcut") {
                    Text(appState.settings.undoShortcut)
                        .foregroundStyle(.secondary)
                }

                Toggle("Show correction feedback", isOn: feedbackBinding)
                Toggle("Play subtle correction sound", isOn: soundBinding)
            }

            Section(copy.correctionHistoryTitle) {
                Toggle("Keep limited correction history", isOn: historyBinding)

                if appState.settings.keepHistory {
                    Stepper(
                        "Retention: \(appState.settings.historyRetentionDays) days",
                        value: retentionBinding,
                        in: 7...90,
                        step: 1
                    )
                }
            }

            Section("Personality") {
                Picker("Butter level", selection: butterLevelBinding) {
                    ForEach(ButterLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
            }

            Section("Updates") {
                Button("Check for Updates…") {
                    SparkleUpdateController.shared.checkForUpdates()
                }
                .disabled(!SparkleUpdateController.shared.canCheckForUpdates)

                Text("Update checks only contact the release feed. Typing data never leaves this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("About") {
                HStack(spacing: 12) {
                    Image("ButterKeysLogo")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ButterKeys")
                            .font(.headline)
                        Text("Typing, but smoother.")
                            .foregroundStyle(.secondary)
                        Text("Version \(AppVersion.display)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Link("Privacy", destination: privacyURL)
                Link("Report a problem", destination: reportURL)
            }
        }
        .formStyle(.grouped)
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.enabled },
            set: { appState.settings.enabled = $0; appState.applySettings() }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.launchAtLogin },
            set: { appState.settings.launchAtLogin = $0; appState.applySettings() }
        )
    }

    private var confidenceBinding: Binding<ConfidencePreset> {
        Binding(
            get: { appState.settings.confidencePreset },
            set: { appState.settings.confidencePreset = $0; appState.applySettings() }
        )
    }

    private var feedbackBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.showCorrectionFeedback },
            set: { appState.settings.showCorrectionFeedback = $0; appState.applySettings() }
        )
    }

    private var soundBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.playCorrectionSound },
            set: { appState.settings.playCorrectionSound = $0; appState.applySettings() }
        )
    }

    private var historyBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.keepHistory },
            set: { appState.settings.keepHistory = $0; appState.applySettings() }
        )
    }

    private var retentionBinding: Binding<Int> {
        Binding(
            get: { appState.settings.historyRetentionDays },
            set: { appState.settings.historyRetentionDays = $0; appState.applySettings() }
        )
    }

    private var butterLevelBinding: Binding<ButterLevel> {
        Binding(
            get: { appState.settings.butterLevel },
            set: { appState.settings.butterLevel = $0; appState.applySettings() }
        )
    }
}
