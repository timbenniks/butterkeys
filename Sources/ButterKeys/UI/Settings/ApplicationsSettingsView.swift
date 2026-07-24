import ButterKeysCore
import SwiftUI

struct ApplicationsSettingsView: View {
    @Bindable var appState: AppState

    @State private var editorMode: ApplicationEditorSheet.Mode?
    @State private var policyPendingDelete: ApplicationPolicyRecord?
    @State private var searchText = ""

    private var copy: CopyProvider { appState.copy }

    private var filteredPolicies: [ApplicationPolicyRecord] {
        let sorted = appState.applicationPolicies.sorted {
            ($0.displayName ?? $0.bundleIdentifier)
                .localizedCaseInsensitiveCompare($1.displayName ?? $1.bundleIdentifier) == .orderedAscending
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sorted }
        return sorted.filter {
            $0.bundleIdentifier.localizedCaseInsensitiveContains(query)
                || ($0.displayName?.localizedCaseInsensitiveContains(query) ?? false)
                || $0.mode.displayName.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        Form {
            Section {
                Text("Control how ButterKeys behaves per app. Coding apps default to code-safe; terminals and password managers stay off.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Add app") {
                    editorMode = .add
                }
                .buttonStyle(.borderedProminent)
            }

            if appState.applicationPolicies.isEmpty {
                Section {
                    EmptyStateView(
                        title: copy.applicationsEmptyTitle,
                        subtitle: copy.applicationsEmptySubtitle,
                        systemImage: "app.badge",
                        actionTitle: "Add app",
                        action: { editorMode = .add }
                    )
                    .listRowBackground(Color.clear)
                    .frame(minHeight: 220)
                }
            } else {
                Section {
                    TextField("Search apps", text: $searchText)
                        .textFieldStyle(.roundedBorder)

                    if filteredPolicies.isEmpty {
                        Text("No matches")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredPolicies) { policy in
                            policyRow(policy)
                        }
                    }
                } header: {
                    Text("App policies (\(appState.applicationPolicies.count))")
                }
            }
        }
        .formStyle(.grouped)
        .sheet(item: $editorMode) { mode in
            ApplicationEditorSheet(
                mode: mode,
                onCancel: { editorMode = nil },
                onSave: { policy in
                    appState.saveApplicationPolicy(policy)
                    editorMode = nil
                },
                onDelete: {
                    if case .edit(let policy) = mode {
                        policyPendingDelete = policy
                    }
                }
            )
        }
        .confirmationDialog(
            "Remove this app policy?",
            isPresented: Binding(
                get: { policyPendingDelete != nil },
                set: { if !$0 { policyPendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let policy = policyPendingDelete {
                    appState.deleteApplicationPolicy(id: policy.id)
                    policyPendingDelete = nil
                    editorMode = nil
                }
            }
            Button("Cancel", role: .cancel) {
                policyPendingDelete = nil
            }
        } message: {
            if let policy = policyPendingDelete {
                Text(policy.displayName ?? policy.bundleIdentifier)
            }
        }
    }

    private func policyRow(_ policy: ApplicationPolicyRecord) -> some View {
        HStack(spacing: 10) {
            Button {
                editorMode = .edit(policy)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(policy.displayName ?? policy.bundleIdentifier)
                    Text(policy.bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Picker("", selection: modeBinding(policy)) {
                ForEach(ApplicationMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .labelsHidden()
            .frame(width: 120)

            Button("Edit") {
                editorMode = .edit(policy)
            }
            .controlSize(.small)

            Button("Remove", role: .destructive) {
                policyPendingDelete = policy
            }
            .controlSize(.small)
        }
        .contextMenu {
            Button("Edit") { editorMode = .edit(policy) }
            Divider()
            Button("Remove", role: .destructive) {
                policyPendingDelete = policy
            }
        }
    }

    private func modeBinding(_ policy: ApplicationPolicyRecord) -> Binding<ApplicationMode> {
        Binding(
            get: { policy.mode },
            set: { newMode in
                var updated = policy
                updated.mode = newMode
                updated.updatedAt = Date()
                appState.saveApplicationPolicy(updated)
            }
        )
    }
}

private struct ApplicationEditorSheet: View {
    enum Mode: Identifiable {
        case add
        case edit(ApplicationPolicyRecord)

        var id: String {
            switch self {
            case .add: "add"
            case .edit(let policy): policy.id
            }
        }

        var title: String {
            switch self {
            case .add: "Add app"
            case .edit: "Edit app"
            }
        }
    }

    let mode: Mode
    let onCancel: () -> Void
    let onSave: (ApplicationPolicyRecord) -> Void
    let onDelete: (() -> Void)?

    @State private var bundleIdentifier: String
    @State private var displayName: String
    @State private var selectedMode: ApplicationMode
    @State private var enabled: Bool

    init(
        mode: Mode,
        onCancel: @escaping () -> Void,
        onSave: @escaping (ApplicationPolicyRecord) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.onCancel = onCancel
        self.onSave = onSave
        self.onDelete = onDelete

        switch mode {
        case .add:
            _bundleIdentifier = State(initialValue: "")
            _displayName = State(initialValue: "")
            _selectedMode = State(initialValue: .prose)
            _enabled = State(initialValue: true)
        case .edit(let policy):
            _bundleIdentifier = State(initialValue: policy.bundleIdentifier)
            _displayName = State(initialValue: policy.displayName ?? "")
            _selectedMode = State(initialValue: policy.mode)
            _enabled = State(initialValue: policy.enabled)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mode.title)
                .font(.headline)

            ApplicationPicker(
                bundleIdentifier: $bundleIdentifier,
                displayName: $displayName
            )

            Picker("Mode", selection: $selectedMode) {
                ForEach(ApplicationMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            Toggle("Enabled", isOn: $enabled)

            HStack {
                if let onDelete {
                    Button("Remove", role: .destructive, action: onDelete)
                }
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    private func save() {
        let bundle = bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !bundle.isEmpty else { return }
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .add:
            onSave(
                ApplicationPolicyRecord(
                    bundleIdentifier: bundle,
                    displayName: name.isEmpty ? nil : name,
                    mode: selectedMode,
                    enabled: enabled
                )
            )
        case .edit(let existing):
            var updated = existing
            updated.bundleIdentifier = bundle
            updated.displayName = name.isEmpty ? nil : name
            updated.mode = selectedMode
            updated.enabled = enabled
            updated.updatedAt = Date()
            onSave(updated)
        }
    }
}
