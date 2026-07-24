import ButterKeysCore
import SwiftUI

struct PrivacyExplanationView: View {
    let copy: CopyProvider
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepContainer {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your typing stays on your Mac.")
                    .font(.title.bold())

                Text("ButterKeys processes a small amount of recent typing locally so it can detect recurring mistakes.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 12) {
                    privacyBullet("It does not send your typing anywhere, store complete sentences, or monitor secure password fields.")
                    privacyBullet("When learning is enabled, ButterKeys saves small correction pairs such as “soem” → “some”.")
                }

                Text("Your words are not going into the cloud, the fridge, or anywhere else.")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .italic()

                Spacer(minLength: 0)

                HStack {
                    Spacer()
                    Button("Continue") {
                        onContinue()
                    }
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
                }
            }
        }
    }

    private func privacyBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
