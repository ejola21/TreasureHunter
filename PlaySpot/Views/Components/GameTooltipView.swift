// Views/Components/GameTooltipView.swift
import SwiftUI
import TipKit

struct GameTooltip: Tip {
    var title: Text { Text("Tip") }
    var message: Text? { Text("Tap items on the map or use AR view to interact with them.") }
}

struct GameTooltipView: View {
    let text: String

    var body: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
            Text(text)
                .font(.caption)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

#if DEBUG
#Preview("Tooltip") {
    VStack(spacing: 12) {
        GameTooltipView(text: "Tap items on the map to interact.")
        GameTooltipView(text: "Hint: 31253m")
    }
    .padding()
}
#endif
