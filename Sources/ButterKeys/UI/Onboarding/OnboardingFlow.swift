import ButterKeysCore
import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case privacy
    case inputMonitoring
    case accessibility
    case typingTest
    case ready
}

struct OnboardingFlow: View {
    @Bindable var appState: AppState
    let permissionCoordinator: PermissionCoordinator

    @Environment(\.dismiss) private var dismiss
    @State private var step: OnboardingStep = .welcome

    private var copy: CopyProvider { appState.copy }

    var body: some View {
        Group {
            switch step {
            case .welcome:
                WelcomeView(copy: copy) {
                    step = .privacy
                }
            case .privacy:
                PrivacyExplanationView(copy: copy) {
                    step = .inputMonitoring
                }
            case .inputMonitoring:
                PermissionView(
                    appState: appState,
                    permissionCoordinator: permissionCoordinator,
                    kind: .inputMonitoring
                ) {
                    step = .accessibility
                }
            case .accessibility:
                PermissionView(
                    appState: appState,
                    permissionCoordinator: permissionCoordinator,
                    kind: .accessibility
                ) {
                    step = .typingTest
                }
            case .typingTest:
                TypingTestView(
                    copy: copy,
                    permissionsGranted: appState.permissionsGranted
                ) {
                    step = .ready
                }
            case .ready:
                readyView
            }
        }
        .frame(width: 520, height: 600)
    }

    private var readyView: some View {
        OnboardingStepContainer {
            VStack(spacing: 20) {
                Image("ButterKeysLogo")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text(copy.onboardingReady)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("ButterKeys lives in your menu bar. Select a typo and press ⌃⌥T to teach a smoother — or open Settings anytime.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Button("Get started") {
                    appState.completeOnboarding()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            }
        }
    }
}
