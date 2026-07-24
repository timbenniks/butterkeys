import ButterKeysCore
import SwiftUI

struct LearningSettingsView: View {
    @Bindable var appState: AppState

    private var copy: CopyProvider { appState.copy }

    var body: some View {
        Form {
            Section("Teach first") {
                Text("Select a typo and press \(appState.settings.teachShortcut) to save a smoother. That is the most reliable way to grow your dictionary.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button(copy.teachFromSelectionLabel) {
                    TeachCapturePanel.present(appState: appState)
                }
            }

            Section("Background learning") {
                Toggle("Learn from manual corrections", isOn: manualBinding)
                Toggle("Learn motor patterns", isOn: motorBinding)

                Stepper(
                    "Suggestion threshold: \(appState.settings.learningRepetitionThreshold) repetitions",
                    value: thresholdBinding,
                    in: 2...10
                )

                Text("Repeated backspace-and-retype fixes can become suggestions. Accepting one adds a real rule.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if appState.pendingSuggestions.isEmpty {
                Section {
                    EmptyStateView(
                        title: copy.learningEmptyTitle,
                        subtitle: copy.learningEmptySubtitle,
                        systemImage: "brain.head.profile"
                    )
                    .listRowBackground(Color.clear)
                }
            } else {
                Section("Pending suggestions") {
                    ForEach(appState.pendingSuggestions) { suggestion in
                        VStack(alignment: .leading, spacing: 8) {
                            CorrectionRow(
                                source: suggestion.source,
                                replacement: suggestion.replacement,
                                confidence: suggestion.confidence,
                                subtitle: "Observed \(suggestion.observedCount) times"
                            )

                            Text(copy.pendingSuggestionPrompt(
                                source: suggestion.source,
                                replacement: suggestion.replacement
                            ))
                            .font(.callout)
                            .foregroundStyle(.secondary)

                            HStack {
                                Button("Apply automatically") {
                                    appState.acceptSuggestionAutomatic(id: suggestion.id)
                                }
                                Button("Suggest only") {
                                    appState.acceptSuggestionOnly(id: suggestion.id)
                                }
                                Button("Dismiss", role: .cancel) {
                                    appState.rejectSuggestion(id: suggestion.id)
                                }
                            }
                            .controlSize(.small)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var manualBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.learnFromManualCorrections },
            set: { appState.settings.learnFromManualCorrections = $0; appState.applySettings() }
        )
    }

    private var motorBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.learnMotorPatterns },
            set: { appState.settings.learnMotorPatterns = $0; appState.applySettings() }
        )
    }

    private var thresholdBinding: Binding<Int> {
        Binding(
            get: { appState.settings.learningRepetitionThreshold },
            set: { appState.settings.learningRepetitionThreshold = $0; appState.applySettings() }
        )
    }
}
