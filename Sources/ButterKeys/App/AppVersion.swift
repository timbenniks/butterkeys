import Foundation

/// Reads marketing / build versions from the main bundle Info.plist.
public enum AppVersion {
    public static var marketing: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    public static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    public static var display: String {
        "\(marketing) (\(build))"
    }
}
