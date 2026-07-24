import ButterKeysCore
import SwiftUI

/// Shared add/edit sheet for correction rules (smoothers).
struct RuleEditorSheet: View {
    enum Mode {
        case add
        case edit(CorrectionRuleRecord)

        var title: String {
            switch self {
            case .add: "New smoother"
            case .edit: "Edit smoother"
            }
        }
    }

    let mode: Mode
    let onCancel: () -> Void
    let onSave: (CorrectionRuleRecord) -> Void
    let onDelete: (() -> Void)?

    @State private var source: String
    @State private var replacement: String
    @State private var matchType: MatchType
    @State private var behaviour: RuleBehaviour
    @State private var enabled: Bool
    @State private var preserveCase: Bool
    @State private var caseSensitive: Bool
    @State private var scopeGlobal: Bool
    @State private var appBundleID: String
    @State private var validationError: String?

    init(
        mode: Mode,
        onCancel: @escaping () -> Void,
        onSave: @escaping (CorrectionRuleRecord) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.onCancel = onCancel
        self.onSave = onSave
        self.onDelete = onDelete

        switch mode {
        case .add:
            _source = State(initialValue: "")
            _replacement = State(initialValue: "")
            _matchType = State(initialValue: .word)
            _behaviour = State(initialValue: .automatic)
            _enabled = State(initialValue: true)
            _preserveCase = State(initialValue: true)
            _caseSensitive = State(initialValue: false)
            _scopeGlobal = State(initialValue: true)
            _appBundleID = State(initialValue: "")
        case .edit(let rule):
            _source = State(initialValue: rule.source)
            _replacement = State(initialValue: rule.replacement)
            _matchType = State(initialValue: rule.matchType)
            _behaviour = State(initialValue: rule.behaviour)
            _enabled = State(initialValue: rule.enabled)
            _preserveCase = State(initialValue: rule.preserveCase)
            _caseSensitive = State(initialValue: rule.caseSensitive)
            _scopeGlobal = State(initialValue: rule.appBundleID == nil)
            _appBundleID = State(initialValue: rule.appBundleID ?? "")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mode.title)
                .font(.headline)

            Form {
                TextField("Typed form", text: $source)
                TextField("Corrected form", text: $replacement)

                Picker("Match", selection: $matchType) {
                    ForEach(MatchType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Behaviour", selection: $behaviour) {
                    ForEach(RuleBehaviour.allCases) { value in
                        Text(value.displayName).tag(value)
                    }
                }

                Toggle("Enabled", isOn: $enabled)
                Toggle("Preserve capitalization", isOn: $preserveCase)
                Toggle("Case sensitive match", isOn: $caseSensitive)

                Toggle("All apps", isOn: $scopeGlobal)
                if !scopeGlobal {
                    TextField("App bundle ID", text: $appBundleID)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .formStyle(.grouped)
            .frame(maxHeight: 340)

            if let validationError {
                Text(validationError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                if let onDelete {
                    Button("Delete", role: .destructive, action: onDelete)
                }
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onChange(of: source) { _, newValue in
            if matchType == .word, newValue.contains(where: \.isWhitespace) {
                matchType = .phrase
            }
        }
    }

    private var canSave: Bool {
        TeachCapture.makeRule(source: source, replacement: replacement, behaviour: behaviour) != nil
            && (scopeGlobal || !appBundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func save() {
        guard var draft = TeachCapture.makeRule(
            source: source,
            replacement: replacement,
            behaviour: behaviour
        ) else {
            validationError = "Enter a short typed form and the corrected form."
            return
        }

        // Prefer the user's explicit match type when both are valid.
        draft.matchType = matchType
        draft.preserveCase = preserveCase
        draft.caseSensitive = caseSensitive
        draft.enabled = enabled
        draft.appBundleID = scopeGlobal
            ? nil
            : appBundleID.trimmingCharacters(in: .whitespacesAndNewlines)

        if case .edit(let existing) = mode {
            draft.id = existing.id
            draft.createdAt = existing.createdAt
            draft.updatedAt = Date()
        }

        onSave(draft)
    }
}
