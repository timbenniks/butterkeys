import ButterKeysCore
import SwiftUI

struct MenuBarStatusIcon: View {
    let status: MonitoringStatus
    let permissionsGranted: Bool

    var body: some View {
        Image("MenuBarIcon")
            .resizable()
            .interpolation(.high)
            .frame(width: 18, height: 18)
            .opacity(iconOpacity)
            .overlay(alignment: .bottomTrailing) {
                if let badge {
                    Image(systemName: badge)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.primary)
                        .padding(1)
                        .background(.background.opacity(0.9), in: Circle())
                        .offset(x: 2, y: 2)
                }
            }
            .accessibilityLabel(accessibilityLabel)
    }

    private var iconOpacity: Double {
        switch status {
        case .paused, .resting, .disabled, .excluded:
            return 0.55
        default:
            return 1
        }
    }

    private var badge: String? {
        if !permissionsGranted || status == .needsPermission {
            return "exclamationmark.circle.fill"
        }
        switch status {
        case .paused, .resting, .disabled, .excluded:
            return "pause.circle.fill"
        case .secureInput:
            return "lock.fill"
        case .smoothing, .needsPermission:
            return nil
        }
    }

    private var accessibilityLabel: String {
        CopyProvider(butterLevel: .plain).monitoringStatus(status)
    }
}
