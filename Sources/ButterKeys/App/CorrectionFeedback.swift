import AppKit
import ButterKeysCore
import SwiftUI

/// Subtle on-screen + optional sound feedback for automatic corrections.
@MainActor
enum CorrectionFeedback {
    private static var panel: NSPanel?
    private static var hideWorkItem: DispatchWorkItem?

    static func present(
        source: String,
        replacement: String,
        settings: AppSettings,
        copy: CopyProvider
    ) {
        if settings.playCorrectionSound {
            playSound()
        }
        if settings.showCorrectionFeedback {
            showHUD(
                title: copy.correctionAppliedFeedback(),
                detail: copy.correctionPairFeedback(source: source, replacement: replacement)
            )
        }
    }

    static func presentTaught(
        source: String,
        replacement: String,
        settings: AppSettings,
        copy: CopyProvider
    ) {
        if settings.playCorrectionSound {
            playSound()
        }
        showHUD(
            title: copy.teachSavedFeedback(source: source, replacement: replacement),
            detail: copy.correctionPairFeedback(source: source, replacement: replacement)
        )
    }

    private static func playSound() {
        // Quiet system sound; never block typing.
        if let sound = NSSound(named: "Tink") ?? NSSound(contentsOf: URL(fileURLWithPath: "/System/Library/Sounds/Tink.aiff"), byReference: true) {
            sound.volume = 0.45
            sound.play()
        }
    }

    private static func showHUD(title: String, detail: String) {
        hideWorkItem?.cancel()

        let panel = ensurePanel()
        let hosting = NSHostingView(
            rootView: FeedbackHUDView(title: title, detail: detail)
        )
        hosting.frame = NSRect(x: 0, y: 0, width: 280, height: 64)
        panel.contentView = hosting
        panel.setContentSize(hosting.frame.size)

        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let x = visible.midX - hosting.frame.width / 2
            let y = visible.minY + 28
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFrontRegardless()

        let work = DispatchWorkItem {
            panel.orderOut(nil)
        }
        hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4, execute: work)
    }

    private static func ensurePanel() -> NSPanel {
        if let panel {
            return panel
        }
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 64),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        self.panel = panel
        return panel
    }
}

private struct FeedbackHUDView: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.callout.weight(.semibold))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
    }
}
