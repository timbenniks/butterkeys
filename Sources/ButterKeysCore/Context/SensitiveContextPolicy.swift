import Foundation

public struct SensitiveContextEvaluation: Sendable, Equatable {
    public let monitoringStatus: MonitoringStatus
    public let applicationMode: ApplicationMode
    public let shouldProcessInput: Bool

    public init(
        monitoringStatus: MonitoringStatus,
        applicationMode: ApplicationMode,
        shouldProcessInput: Bool
    ) {
        self.monitoringStatus = monitoringStatus
        self.applicationMode = applicationMode
        self.shouldProcessInput = shouldProcessInput
    }
}

public struct SensitiveContextPolicy: Sendable {
    public let exclusionPolicy: ExclusionPolicy
    public let applicationProfile: ApplicationProfile

    public init(
        exclusionPolicy: ExclusionPolicy = ExclusionPolicy(),
        applicationProfile: ApplicationProfile = ApplicationProfile()
    ) {
        self.exclusionPolicy = exclusionPolicy
        self.applicationProfile = applicationProfile
    }

    public func evaluate(
        bundleIdentifier: String?,
        secureInputActive: Bool,
        focusedElementSecure: Bool?,
        userModeOverrides: [String: ApplicationMode] = [:]
    ) -> SensitiveContextEvaluation {
        if secureInputActive {
            return SensitiveContextEvaluation(
                monitoringStatus: .secureInput,
                applicationMode: .disabled,
                shouldProcessInput: false
            )
        }

        if focusedElementSecure == true {
            return SensitiveContextEvaluation(
                monitoringStatus: .paused,
                applicationMode: .disabled,
                shouldProcessInput: false
            )
        }

        if exclusionPolicy.isExcluded(bundleIdentifier: bundleIdentifier)
            || exclusionPolicy.isPasswordManager(bundleIdentifier: bundleIdentifier) {
            return SensitiveContextEvaluation(
                monitoringStatus: .excluded,
                applicationMode: .disabled,
                shouldProcessInput: false
            )
        }

        let mode = applicationProfile.mode(for: bundleIdentifier, userOverrides: userModeOverrides)
        if mode == .disabled {
            return SensitiveContextEvaluation(
                monitoringStatus: .excluded,
                applicationMode: .disabled,
                shouldProcessInput: false
            )
        }

        return SensitiveContextEvaluation(
            monitoringStatus: .smoothing,
            applicationMode: mode,
            shouldProcessInput: true
        )
    }
}
