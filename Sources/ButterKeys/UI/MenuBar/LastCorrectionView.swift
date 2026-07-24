import ButterKeysCore
import SwiftUI

struct LastCorrectionView: View {
    let source: String
    let replacement: String
    let copy: CopyProvider

    var body: some View {
        Text("\(copy.lastCorrectionTitle): \(copy.lastCorrectionLabel(source: source, replacement: replacement))")
            .font(.body)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}
