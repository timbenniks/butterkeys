import AppKit
import ButterKeysCore
import SwiftUI

/// Floating panel for teaching a typo → correction pair from the current selection.
@MainActor
enum TeachCapturePanel {
    private static var panel: NSPanel?
    private static var selectionCapture = SelectionCapture()

    static func present(appState: AppState) {
        let snapshot = selectionCapture.snapshot()
        let source = snapshot?.text ?? ""

        let root = TeachCaptureView(
            initialSource: source,
            copy: appState.copy,
            onCancel: { dismiss() },
            onSave: { source, replacement in
                guard let rule = appState.upsertTaughtRule(
                    source: source,
                    replacement: replacement
                ) else {
                    return false
                }

                let replaced = selectionCapture.replaceRetainedSelection(with: rule.replacement)
                if !replaced {
                    selectionCapture.clear()
                }

                NotificationCenter.default.post(
                    name: .butterKeysDidTeachRule,
                    object: nil,
                    userInfo: [
                        "source": rule.source,
                        "replacement": rule.replacement,
                        "replacedSelection": replaced
                    ]
                )
                dismiss()
                return true
            }
        )

        let hosting = NSHostingController(rootView: root)
        let panel = ensurePanel()
        panel.contentViewController = hosting
        panel.setContentSize(NSSize(width: 360, height: 210))

        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let x = visible.midX - 180
            let y = visible.midY - 80
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        NSApp.setActivationPolicy(.regular)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.panel = panel
    }

    private static func dismiss() {
        panel?.orderOut(nil)
        selectionCapture.clear()

        let hasKeyWindow = NSApp.windows.contains { $0.isVisible && $0.canBecomeKey && $0 !== panel }
        if !hasKeyWindow {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private static func ensurePanel() -> NSPanel {
        if let panel {
            return panel
        }
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 210),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "Teach ButterKeys"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        return panel
    }
}

private struct TeachCaptureView: View {
    let copy: CopyProvider
    let onCancel: () -> Void
    let onSave: (String, String) -> Bool

    @State private var source: String
    @State private var replacement: String
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case source
        case replacement
    }

    init(
        initialSource: String,
        copy: CopyProvider,
        onCancel: @escaping () -> Void,
        onSave: @escaping (String, String) -> Bool
    ) {
        self.copy = copy
        self.onCancel = onCancel
        self.onSave = onSave
        _source = State(initialValue: initialSource)
        _replacement = State(initialValue: "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(copy.teachPanelTitle)
                .font(.headline)

            Text(copy.teachPanelSubtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            TextField(copy.teachSourcePlaceholder, text: $source)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .source)

            TextField(copy.teachReplacementPlaceholder, text: $replacement)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .replacement)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button(copy.teachSaveLabel) {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear {
            focusedField = source.isEmpty ? .source : .replacement
        }
    }

    private var canSave: Bool {
        TeachCapture.makeRule(source: source, replacement: replacement) != nil
    }

    private func save() {
        guard onSave(source, replacement) else {
            errorMessage = copy.teachInvalidPairMessage
            return
        }
    }
}
