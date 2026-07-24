import Foundation

public struct ExclusionPolicy: Sendable, Equatable {
    /// Always-off contexts: terminals, password managers, VMs / remote desktop.
    /// Coding apps are not excluded — they default to code-safe mode instead.
    public static let defaultExactBundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "com.1password.1password",
        "com.agilebits.onepassword7",
        "com.apple.keychainaccess",
        "com.github.wez.wezterm",
        "net.kovidgoyal.kitty",
        "com.parallels.desktop.console",
        "com.vmware.fusion",
        "com.microsoft.rdc.macos"
    ]

    public static let defaultPrefixBundleIDs: [String] = []

    public static let passwordManagerBundleIDs: Set<String> = [
        "com.1password.1password",
        "com.agilebits.onepassword7",
        "com.apple.keychainaccess"
    ]

    public static let codingAppBundleIDs: Set<String> = [
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92",
        "com.apple.dt.Xcode"
    ]

    public static let codingAppPrefixes: [String] = [
        "com.jetbrains."
    ]

    public let exactBundleIDs: Set<String>
    public let prefixBundleIDs: [String]

    public init(
        exactBundleIDs: Set<String> = ExclusionPolicy.defaultExactBundleIDs,
        prefixBundleIDs: [String] = ExclusionPolicy.defaultPrefixBundleIDs
    ) {
        self.exactBundleIDs = exactBundleIDs
        self.prefixBundleIDs = prefixBundleIDs
    }

    public func isExcluded(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty else { return false }

        if exactBundleIDs.contains(bundleIdentifier) {
            return true
        }

        return prefixBundleIDs.contains { bundleIdentifier.hasPrefix($0) }
    }

    public func isPasswordManager(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        return Self.passwordManagerBundleIDs.contains(bundleIdentifier)
    }

    public func isCodingApp(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty else { return false }
        if Self.codingAppBundleIDs.contains(bundleIdentifier) { return true }
        return Self.codingAppPrefixes.contains { bundleIdentifier.hasPrefix($0) }
    }
}
