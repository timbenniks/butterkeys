import AppKit
import SwiftUI

struct ApplicationPicker: View {
    @Binding var bundleIdentifier: String
    @Binding var displayName: String

    @State private var runningApps: [RunningAppOption] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Running app", selection: selectedAppBinding) {
                Text("Custom…").tag("")
                ForEach(runningApps) { app in
                    Text(app.title).tag(app.bundleIdentifier)
                }
            }

            TextField("Bundle identifier", text: $bundleIdentifier)
                .textFieldStyle(.roundedBorder)

            TextField("Display name (optional)", text: $displayName)
                .textFieldStyle(.roundedBorder)
        }
        .onAppear {
            refreshRunningApps()
        }
    }

    private var selectedAppBinding: Binding<String> {
        Binding(
            get: { bundleIdentifier },
            set: { newValue in
                bundleIdentifier = newValue
                if let app = runningApps.first(where: { $0.bundleIdentifier == newValue }) {
                    displayName = app.localizedName
                }
            }
        )
    }

    private func refreshRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications
            .compactMap { app -> RunningAppOption? in
                guard let id = app.bundleIdentifier,
                      app.activationPolicy == .regular,
                      let name = app.localizedName else { return nil }
                return RunningAppOption(bundleIdentifier: id, localizedName: name)
            }
            .sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
    }
}

private struct RunningAppOption: Identifiable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    let localizedName: String

    var title: String { localizedName }
}
