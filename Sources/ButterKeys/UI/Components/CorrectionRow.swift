import SwiftUI

struct CorrectionRow<Trailing: View>: View {
    let source: String
    let replacement: String
    let confidence: Double?
    let subtitle: String?
    @ViewBuilder var trailing: () -> Trailing

    init(
        source: String,
        replacement: String,
        confidence: Double? = nil,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.source = source
        self.replacement = replacement
        self.confidence = confidence
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(source)
                    Image(systemName: "arrow.right")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text(replacement)
                }
                .font(.body)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let confidence {
                ConfidenceBadge(confidence: confidence)
            }

            trailing()
        }
        .padding(.vertical, 2)
    }
}

extension CorrectionRow where Trailing == EmptyView {
    init(
        source: String,
        replacement: String,
        confidence: Double? = nil,
        subtitle: String? = nil
    ) {
        self.init(
            source: source,
            replacement: replacement,
            confidence: confidence,
            subtitle: subtitle,
            trailing: { EmptyView() }
        )
    }
}
