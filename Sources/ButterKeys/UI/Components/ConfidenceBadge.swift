import SwiftUI

struct ConfidenceBadge: View {
    let confidence: Double

    var body: some View {
        Text(label)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }

    private var label: String {
        String(format: "%.0f%%", confidence * 100)
    }

    private var tint: Color {
        switch confidence {
        case 0.9...: .green
        case 0.75..<0.9: .mint
        case 0.6..<0.75: .orange
        default: .secondary
        }
    }
}
