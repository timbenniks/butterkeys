import ButterKeysCore
import SwiftUI

struct WordEditorSheet: View {
    enum Mode {
        case add(CustomWordCategory)
        case edit(CustomWordRecord)

        var title: String {
            switch self {
            case .add: "Add word"
            case .edit: "Edit word"
            }
        }
    }

    let mode: Mode
    let onCancel: () -> Void
    let onSave: (CustomWordRecord) -> Bool
    let onDelete: (() -> Void)?

    @State private var word: String
    @State private var category: CustomWordCategory
    @State private var errorMessage: String?

    init(
        mode: Mode,
        onCancel: @escaping () -> Void,
        onSave: @escaping (CustomWordRecord) -> Bool,
        onDelete: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.onCancel = onCancel
        self.onSave = onSave
        self.onDelete = onDelete

        switch mode {
        case .add(let category):
            _word = State(initialValue: "")
            _category = State(initialValue: category)
        case .edit(let record):
            _word = State(initialValue: record.word)
            _category = State(initialValue: CustomWordCategory(rawValue: record.category) ?? .dictionary)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mode.title)
                .font(.headline)

            TextField("Word", text: $word)
                .textFieldStyle(.roundedBorder)

            Picker("List", selection: $category) {
                ForEach(CustomWordCategory.allCases) { value in
                    Text(value.displayName).tag(value)
                }
            }
            .pickerStyle(.segmented)

            Text(categoryHint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let errorMessage {
                Text(errorMessage)
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
                    .disabled(AppState.normalizeCustomWord(word) == nil)
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    private var categoryHint: String {
        switch category {
        case .protected:
            "Never auto-correct this word."
        case .dictionary:
            "Treat as a real word for scoring."
        case .name:
            "People / place names — valid and harder to overwrite."
        }
    }

    private func save() {
        guard let normalized = AppState.normalizeCustomWord(word) else {
            errorMessage = "Use letters, apostrophes, or hyphens only."
            return
        }

        var record: CustomWordRecord
        switch mode {
        case .add:
            record = CustomWordRecord(word: normalized, category: category.rawValue)
        case .edit(let existing):
            record = existing
            record.word = normalized
            record.category = category.rawValue
        }

        guard onSave(record) else {
            errorMessage = "Could not save that word."
            return
        }
    }
}

extension WordEditorSheet.Mode: Identifiable {
    var id: String {
        switch self {
        case .add(let category): "add-\(category.rawValue)"
        case .edit(let record): record.id
        }
    }
}
