import AppKit
import ButterKeysCore
import SwiftUI
import UniformTypeIdentifiers

struct PrivacySettingsView: View {
    @Bindable var appState: AppState
    @State private var confirmDeleteAll = false
    @State private var exportError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your typing stays on your Mac.")
                    .font(.title2.bold())

                Text("ButterKeys processes a small amount of recent typing locally so it can detect recurring mistakes.")
                    .foregroundStyle(.secondary)

                Group {
                    privacyRow(
                        "No cloud processing",
                        "Corrections run entirely on your Mac. No typing data is sent to servers."
                    )
                    privacyRow(
                        "No full-sentence storage",
                        "ButterKeys does not persist complete sentences or raw keystroke logs."
                    )
                    privacyRow(
                        "Secure fields respected",
                        "Password fields and secure input automatically pause monitoring."
                    )
                    privacyRow(
                        "Limited history",
                        appState.settings.keepHistory
                            ? "Compact correction pairs are kept for up to \(appState.settings.historyRetentionDays) days."
                            : "Correction history is disabled."
                    )
                }

                Divider()

                Text("Stored locally")
                    .font(.headline)

                Text("User rules, learned typo pairs, aggregated pattern statistics, application policies, and settings.")
                    .foregroundStyle(.secondary)

                Divider()

                Text("Data tools")
                    .font(.headline)

                HStack {
                    Button("Open data folder") { appState.openDataFolder() }
                    Button("Export learned rules") { exportRules() }
                }

                HStack {
                    Button("Delete history") { appState.clearHistory() }
                    Button("Delete learned data") { appState.clearLearnedData() }
                }

                Button("Delete all ButterKeys data", role: .destructive) {
                    confirmDeleteAll = true
                }

                if let exportError {
                    Text(exportError)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .confirmationDialog(
            "Delete all ButterKeys data?",
            isPresented: $confirmDeleteAll,
            titleVisibility: .visible
        ) {
            Button("Delete all ButterKeys data", role: .destructive) {
                appState.deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes rules, history, learned patterns, and resets defaults. This cannot be undone.")
        }
    }

    private func privacyRow(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.body.weight(.medium))
            Text(detail)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func exportRules() {
        do {
            let data = try appState.exportRulesJSON()
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "butterkeys-export.json"
            if panel.runModal() == .OK, let url = panel.url {
                try data.write(to: url)
                exportError = nil
            }
        } catch {
            exportError = error.localizedDescription
        }
    }
}
