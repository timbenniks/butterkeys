import ButterKeysCore
import SwiftUI

struct DictionarySettingsView: View {
    @Bindable var appState: AppState

    @State private var draftProtected = ""
    @State private var draftDictionary = ""
    @State private var draftName = ""
    @State private var editorMode: WordEditorSheet.Mode?
    @State private var wordPendingDelete: CustomWordRecord?

    var body: some View {
        Form {
            Section {
                Text("Your words sit on top of the bundled English list. Add anything ButterKeys should leave alone — or treat as real.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            wordSection(
                title: "Protected",
                subtitle: "Never auto-correct these (Dutch words, jargon, false positives).",
                category: .protected,
                draft: $draftProtected
            )

            wordSection(
                title: "My words",
                subtitle: "Count as real words for scoring (product names, niche terms).",
                category: .dictionary,
                draft: $draftDictionary
            )

            wordSection(
                title: "Names",
                subtitle: "People and place names — valid and harder to overwrite.",
                category: .name,
                draft: $draftName
            )
        }
        .formStyle(.grouped)
        .sheet(item: $editorMode) { mode in
            WordEditorSheet(
                mode: mode,
                onCancel: { editorMode = nil },
                onSave: { record in
                    let ok = appState.saveCustomWord(record)
                    if ok { editorMode = nil }
                    return ok
                },
                onDelete: {
                    if case .edit(let record) = mode {
                        wordPendingDelete = record
                    }
                }
            )
        }
        .confirmationDialog(
            "Delete this word?",
            isPresented: Binding(
                get: { wordPendingDelete != nil },
                set: { if !$0 { wordPendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let record = wordPendingDelete {
                    appState.deleteCustomWord(id: record.id)
                    wordPendingDelete = nil
                    editorMode = nil
                }
            }
            Button("Cancel", role: .cancel) {
                wordPendingDelete = nil
            }
        } message: {
            if let record = wordPendingDelete {
                Text("“\(record.word)” will be removed from your dictionary.")
            }
        }
    }

    @ViewBuilder
    private func wordSection(
        title: String,
        subtitle: String,
        category: CustomWordCategory,
        draft: Binding<String>
    ) -> some View {
        Section {
            HStack(spacing: 8) {
                TextField("Add a word…", text: draft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { add(draft, category: category) }

                Button("Add") {
                    add(draft, category: category)
                }
                .disabled(AppState.normalizeCustomWord(draft.wrappedValue) == nil)
            }

            let words = appState.customWords(in: category)
            if words.isEmpty {
                Text("None yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(words) { record in
                    HStack {
                        Button {
                            editorMode = .edit(record)
                        } label: {
                            Text(record.word)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button("Edit") {
                            editorMode = .edit(record)
                        }
                        .controlSize(.small)

                        Button("Remove", role: .destructive) {
                            wordPendingDelete = record
                        }
                        .controlSize(.small)
                    }
                    .contextMenu {
                        Button("Edit") { editorMode = .edit(record) }
                        Menu("Move to") {
                            ForEach(CustomWordCategory.allCases) { destination in
                                Button(destination.displayName) {
                                    var updated = record
                                    updated.category = destination.rawValue
                                    _ = appState.saveCustomWord(updated)
                                }
                                .disabled(destination == category)
                            }
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            wordPendingDelete = record
                        }
                    }
                }
            }
        } header: {
            Text(title)
        } footer: {
            Text(subtitle)
        }
    }

    private func add(_ draft: Binding<String>, category: CustomWordCategory) {
        if appState.addCustomWord(draft.wrappedValue, category: category) {
            draft.wrappedValue = ""
        }
    }
}
