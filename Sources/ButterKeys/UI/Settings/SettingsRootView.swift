import AppKit
import ButterKeysCore
import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case rules
    case dictionary
    case learning
    case applications
    case history
    case privacy
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .rules: "Rules"
        case .dictionary: "Dictionary"
        case .learning: "Learning"
        case .applications: "Applications"
        case .history: "History"
        case .privacy: "Privacy"
        case .advanced: "Advanced"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .rules: "text.badge.checkmark"
        case .dictionary: "character.book.closed"
        case .learning: "brain.head.profile"
        case .applications: "app.badge"
        case .history: "clock"
        case .privacy: "hand.raised"
        case .advanced: "slider.horizontal.3"
        }
    }
}

struct SettingsRootView: View {
    @Bindable var appState: AppState

    var body: some View {
        TabView {
            tab(SettingsSection.general) {
                GeneralSettingsView(appState: appState)
            }
            tab(SettingsSection.rules) {
                NavigationStack {
                    RulesSettingsView(appState: appState)
                }
            }
            tab(SettingsSection.dictionary) {
                NavigationStack {
                    DictionarySettingsView(appState: appState)
                }
            }
            tab(SettingsSection.learning) {
                LearningSettingsView(appState: appState)
            }
            tab(SettingsSection.applications) {
                NavigationStack {
                    ApplicationsSettingsView(appState: appState)
                }
            }
            tab(SettingsSection.history) {
                NavigationStack {
                    HistorySettingsView(appState: appState)
                }
            }
            tab(SettingsSection.privacy) {
                PrivacySettingsView(appState: appState)
            }
            tab(SettingsSection.advanced) {
                AdvancedSettingsView(appState: appState)
            }
        }
        .frame(width: 560, height: 460)
        .onAppear {
            appState.reload()
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.async {
                NSApp.windows
                    .filter(\.isVisible)
                    .forEach { $0.makeKeyAndOrderFront(nil) }
            }
        }
    }

    @ViewBuilder
    private func tab<Content: View>(
        _ section: SettingsSection,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .tabItem {
                Label(section.title, systemImage: section.systemImage)
            }
            .tag(section)
    }
}
