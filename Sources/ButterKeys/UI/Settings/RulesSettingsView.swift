import AppKit
import ButterKeysCore
import SwiftUI
import UniformTypeIdentifiers

struct RulesSettingsView: View {
    @Bindable var appState: AppState

    @State private var searchText = ""
    @State private var editorMode: RuleEditorSheet.Mode?
    @State private var rulePendingDelete: CorrectionRuleRecord?
    @State private var ioError: String?

    private var copy: CopyProvider { appState.copy }

    private var filteredRules: [CorrectionRuleRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return appState.rules }
        return appState.rules.filter {
            $0.source.localizedCaseInsensitiveContains(query)
                || $0.replacement.localizedCaseInsensitiveContains(query)
                || ($0.appBundleID?.localizedCaseInsensitiveContains(query) ?? false)
                || $0.behaviour.displayName.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        Form {
            Section {
                Text("Smoothers are the pairs ButterKeys applies automatically (or as suggestions). Teach with ⌃⌥T, or manage them here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Button("Add smoother") {
                        editorMode = .add
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Import") { importRules() }
                    Button("Export") { exportRules() }
                        .disabled(appState.rules.isEmpty)
                }
            }

            if appState.rules.isEmpty {
                Section {
                    EmptyStateView(
                        title: copy.rulesEmptyTitle,
                        subtitle: copy.rulesEmptySubtitle,
                        systemImage: "text.badge.checkmark",
                        actionTitle: "Add smoother",
                        action: { editorMode = .add }
                    )
                    .listRowBackground(Color.clear)
                    .frame(minHeight: 220)
                }
            } else {
                Section {
                    TextField("Search smoothers", text: $searchText)
                        .textFieldStyle(.roundedBorder)

                    if filteredRules.isEmpty {
                        Text("No matches")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredRules) { rule in
                            ruleRow(rule)
                        }
                    }
                } header: {
                    Text("Your smoothers (\(appState.rules.count))")
                }
            }
        }
        .formStyle(.grouped)
        .sheet(item: $editorMode) { mode in
            RuleEditorSheet(
                mode: mode,
                onCancel: { editorMode = nil },
                onSave: { rule in
                    appState.saveRule(rule)
                    editorMode = nil
                },
                onDelete: {
                    if case .edit(let rule) = mode {
                        rulePendingDelete = rule
                    }
                }
            )
        }
        .confirmationDialog(
            "Delete this smoother?",
            isPresented: Binding(
                get: { rulePendingDelete != nil },
                set: { if !$0 { rulePendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let rule = rulePendingDelete {
                    appState.deleteRule(id: rule.id)
                    rulePendingDelete = nil
                    editorMode = nil
                }
            }
            Button("Cancel", role: .cancel) {
                rulePendingDelete = nil
            }
        } message: {
            if let rule = rulePendingDelete {
                Text("\(rule.source) → \(rule.replacement) will be removed.")
            }
        }
        .alert("Could not import or export", isPresented: Binding(
            get: { ioError != nil },
            set: { if !$0 { ioError = nil } }
        )) {
            Button("OK", role: .cancel) { ioError = nil }
        } message: {
            Text(ioError ?? "")
        }
    }

    private func ruleRow(_ rule: CorrectionRuleRecord) -> some View {
        HStack(spacing: 10) {
            Button {
                editorMode = .edit(rule)
            } label: {
                CorrectionRow(
                    source: rule.source,
                    replacement: rule.replacement,
                    confidence: nil,
                    subtitle: ruleSubtitle(rule)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Toggle("", isOn: ruleEnabledBinding(rule))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)

            Button("Edit") {
                editorMode = .edit(rule)
            }
            .controlSize(.small)

            Button("Remove", role: .destructive) {
                rulePendingDelete = rule
            }
            .controlSize(.small)
        }
        .contextMenu {
            Button("Edit") { editorMode = .edit(rule) }
            Button("Duplicate") { duplicate(rule) }
            Divider()
            Button("Delete", role: .destructive) {
                rulePendingDelete = rule
            }
        }
    }

    private func ruleSubtitle(_ rule: CorrectionRuleRecord) -> String {
        var parts = [rule.matchType.displayName, rule.behaviour.displayName]
        if !rule.enabled { parts.append("Off") }
        if let app = rule.appBundleID { parts.append(app) }
        return parts.joined(separator: " · ")
    }

    private func ruleEnabledBinding(_ rule: CorrectionRuleRecord) -> Binding<Bool> {
        Binding(
            get: { rule.enabled },
            set: { newValue in
                var updated = rule
                updated.enabled = newValue
                updated.updatedAt = Date()
                appState.saveRule(updated)
            }
        )
    }

    private func duplicate(_ rule: CorrectionRuleRecord) {
        let copy = CorrectionRuleRecord(
            source: rule.source,
            replacement: rule.replacement,
            matchType: rule.matchType,
            preserveCase: rule.preserveCase,
            caseSensitive: rule.caseSensitive,
            appBundleID: rule.appBundleID,
            applicationMode: rule.applicationMode,
            behaviour: rule.behaviour,
            enabled: rule.enabled
        )
        editorMode = .edit(copy)
    }

    private func exportRules() {
        do {
            let data = try appState.exportRulesJSON(includeLearned: false)
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "butterkeys-rules.json"
            if panel.runModal() == .OK, let url = panel.url {
                try data.write(to: url)
            }
        } catch {
            ioError = error.localizedDescription
        }
    }

    private func importRules() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            try appState.importRulesJSON(data)
        } catch {
            ioError = error.localizedDescription
        }
    }
}

extension RuleEditorSheet.Mode: Identifiable {
    var id: String {
        switch self {
        case .add: "add"
        case .edit(let rule): rule.id
        }
    }
}
