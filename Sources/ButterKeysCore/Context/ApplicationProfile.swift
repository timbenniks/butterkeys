import Foundation

public struct ApplicationProfile: Sendable, Equatable {
    public static let defaultModes: [String: ApplicationMode] = [
        "com.apple.mail": .prose,
        "com.apple.MobileSMS": .prose,
        "com.apple.Notes": .prose,
        "com.apple.Safari": .prose,
        "com.tinyspeck.slackmacgap": .prose,
        "com.openai.chat": .prose,
        // Coding apps: explicit / high-confidence rules only (no phrase restructuring).
        "com.microsoft.VSCode": .codeSafe,
        "com.todesktop.230313mzl4w4u92": .codeSafe,
        "com.apple.dt.Xcode": .codeSafe,
        // Still disabled by default.
        "com.apple.Terminal": .disabled,
        "com.googlecode.iterm2": .disabled,
        "dev.warp.Warp-Stable": .disabled,
        "com.1password.1password": .disabled,
        "com.agilebits.onepassword7": .disabled,
        "com.apple.keychainaccess": .disabled
    ]

    public let defaultModes: [String: ApplicationMode]
    public let unknownDefault: ApplicationMode

    public init(
        defaultModes: [String: ApplicationMode] = ApplicationProfile.defaultModes,
        unknownDefault: ApplicationMode = .prose
    ) {
        self.defaultModes = defaultModes
        self.unknownDefault = unknownDefault
    }

    public func mode(
        for bundleIdentifier: String?,
        userOverrides: [String: ApplicationMode] = [:]
    ) -> ApplicationMode {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty else {
            return unknownDefault
        }

        if let override = userOverrides[bundleIdentifier] {
            return override
        }

        if let defaultMode = defaultModes[bundleIdentifier] {
            return defaultMode
        }

        if ExclusionPolicy().isCodingApp(bundleIdentifier: bundleIdentifier) {
            return .codeSafe
        }

        return unknownDefault
    }
}
