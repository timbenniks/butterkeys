import ButterKeysCore
import SwiftUI

struct HistorySettingsView: View {
    @Bindable var appState: AppState

    private var copy: CopyProvider { appState.copy }

    var body: some View {
        Group {
            if appState.history.isEmpty {
                EmptyStateView(
                    title: copy.historyEmptyTitle,
                    subtitle: copy.historyEmptySubtitle,
                    systemImage: "clock.arrow.circlepath"
                )
            } else {
                List(appState.history) { entry in
                    CorrectionRow(
                        source: entry.source,
                        replacement: entry.replacement,
                        confidence: entry.confidence,
                        subtitle: historySubtitle(entry)
                    )
                    .opacity(entry.wasUndone ? 0.5 : 1)
                    .contextMenu {
                        Button("Protect “\(entry.source)”") {
                            appState.protectWord(entry.source)
                        }
                        Button("Add “\(entry.source)” to My words") {
                            _ = appState.addCustomWord(entry.source, category: .dictionary)
                        }
                    }
                }
            }
        }
        .navigationTitle(copy.correctionHistoryTitle)
    }

    private func historySubtitle(_ entry: CorrectionHistoryRecord) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        var parts = [formatter.localizedString(for: entry.createdAt, relativeTo: Date())]
        if entry.wasUndone { parts.append("undone") }
        if let app = entry.appBundleID { parts.append(app) }
        return parts.joined(separator: " · ")
    }
}
