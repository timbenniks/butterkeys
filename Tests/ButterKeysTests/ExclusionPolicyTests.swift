import ButterKeysCore
import Testing

@Suite("Exclusion policy")
struct ExclusionPolicyTests {
    private let policy = SensitiveContextPolicy()

    @Test("Terminals remain excluded", arguments: [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
    ])
    func excludedTerminals(bundleID: String) {
        #expect(ExclusionPolicy().isExcluded(bundleIdentifier: bundleID))
        let evaluation = policy.evaluate(bundleIdentifier: bundleID, secureInputActive: false, focusedElementSecure: false)
        #expect(!evaluation.shouldProcessInput)
        #expect(evaluation.applicationMode == .disabled)
        #expect(evaluation.monitoringStatus == .excluded)
    }

    @Test("Coding apps are code-safe by default", arguments: [
        "com.apple.dt.Xcode",
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92",
        "com.jetbrains.intellij",
    ])
    func codingAppsCodeSafe(bundleID: String) {
        #expect(!ExclusionPolicy().isExcluded(bundleIdentifier: bundleID))
        let evaluation = policy.evaluate(bundleIdentifier: bundleID, secureInputActive: false, focusedElementSecure: false)
        #expect(evaluation.shouldProcessInput)
        #expect(evaluation.applicationMode == .codeSafe)
        #expect(evaluation.monitoringStatus == .smoothing)
    }

    @Test("Notes and Mail are not excluded", arguments: [
        "com.apple.Notes",
        "com.apple.mail",
        "com.apple.MobileSMS",
    ])
    func proseApps(bundleID: String) {
        #expect(!ExclusionPolicy().isExcluded(bundleIdentifier: bundleID))
        let evaluation = policy.evaluate(bundleIdentifier: bundleID, secureInputActive: false, focusedElementSecure: false)
        #expect(evaluation.shouldProcessInput)
        #expect(evaluation.applicationMode == .prose)
        #expect(evaluation.monitoringStatus == .smoothing)
    }

    @Test("Secure input disables processing")
    func secureInput() {
        let evaluation = policy.evaluate(
            bundleIdentifier: "com.apple.Notes",
            secureInputActive: true,
            focusedElementSecure: false
        )
        #expect(!evaluation.shouldProcessInput)
        #expect(evaluation.monitoringStatus == .secureInput)
    }

    @Test("Secure focused element disables processing")
    func secureFocusedElement() {
        let evaluation = policy.evaluate(
            bundleIdentifier: "com.apple.Notes",
            secureInputActive: false,
            focusedElementSecure: true
        )
        #expect(!evaluation.shouldProcessInput)
        #expect(evaluation.monitoringStatus == .paused)
    }

    @Test("Password managers are excluded")
    func passwordManagers() {
        let exclusion = ExclusionPolicy()
        #expect(exclusion.isPasswordManager(bundleIdentifier: "com.1password.1password"))
        #expect(exclusion.isExcluded(bundleIdentifier: "com.agilebits.onepassword7"))
    }

    @Test("Prose correction available after switching from excluded app")
    func switchingBackToNotes() {
        let terminal = policy.evaluate(
            bundleIdentifier: "com.apple.Terminal",
            secureInputActive: false,
            focusedElementSecure: false
        )
        let notes = policy.evaluate(
            bundleIdentifier: "com.apple.Notes",
            secureInputActive: false,
            focusedElementSecure: false
        )

        #expect(!terminal.shouldProcessInput)
        #expect(notes.shouldProcessInput)
        #expect(notes.applicationMode == .prose)
    }
}
