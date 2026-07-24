import ButterKeysCore
import SwiftUI

struct WelcomeView: View {
    let copy: CopyProvider
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepContainer {
            VStack(spacing: 20) {
                Image("ButterKeysLogo")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 6)

                VStack(spacing: 8) {
                    Text("Welcome to ButterKeys")
                        .font(.largeTitle.bold())
                    Text("Typing, but smoother.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Text("ButterKeys quietly fixes the mistakes you teach it — plus a starter set of common slips — before your brain can stop them.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Button("Continue") {
                    onContinue()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            }
        }
    }
}

struct OnboardingStepContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 24) {
            content()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}
