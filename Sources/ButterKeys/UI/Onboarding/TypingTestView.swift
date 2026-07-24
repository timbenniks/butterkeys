import ButterKeysCore
import SwiftUI

struct TypingTestView: View {
    let copy: CopyProvider
    let permissionsGranted: Bool
    let onContinue: () -> Void

    @State private var testText = ""
    @State private var didDetectCorrection = false

    private let prompts = ["teh", "soem", "jsut", "gove me", "buidl", "writign", "int he app"]

    var body: some View {
        OnboardingStepContainer {
            VStack(alignment: .leading, spacing: 16) {
                Text("Try it out")
                    .font(.title.bold())

                Text("Try typing one of these common slips (seeded rules still catch them):")
                    .foregroundStyle(.secondary)

                FlowLayout(spacing: 8) {
                    ForEach(prompts, id: \.self) { prompt in
                        Text(prompt)
                            .font(.callout.monospaced())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.quaternary, in: Capsule())
                    }
                }

                TextEditor(text: $testText)
                    .font(.body)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(.quaternary)
                    )

                if !permissionsGranted {
                    Label(
                        "Grant permissions first — the global monitor will correct as you type once enabled.",
                        systemImage: "info.circle"
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                } else {
                    Text("The global monitor will correct typos as you type in this field.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if didDetectCorrection || looksCorrected {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Smooth.")
                            .font(.headline)
                        Text("ButterKeys is working.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }

                Spacer(minLength: 0)

                HStack {
                    Spacer()
                    Button("Finish") {
                        onContinue()
                    }
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
                }
            }
        }
        .onChange(of: testText) { _, newValue in
            if looksCorrected(in: newValue) {
                didDetectCorrection = true
            }
        }
    }

    private var looksCorrected: Bool {
        looksCorrected(in: testText)
    }

    private func looksCorrected(in text: String) -> Bool {
        let lowered = text.lowercased()
        return lowered.contains(" the ")
            || lowered.hasPrefix("the ")
            || lowered.contains(" some")
            || lowered.contains(" just")
            || lowered.contains(" give")
            || lowered.contains(" build")
            || lowered.contains(" writing")
            || lowered.contains("in the app")
    }
}

/// Simple horizontal flow for prompt chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var positions: [CGPoint] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
