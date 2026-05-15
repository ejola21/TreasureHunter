// Views/MissionPlay/GameStatusBar.swift
import SwiftUI

struct GameStatusBar: View {
    let engine: GameEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            statusRow(icon: "exclamationmark.triangle.fill", color: .red,
                      label: "Mine", count: engine.mineCount)
            statusRow(icon: "star.fill", color: .yellow,
                      label: "Required", count: engine.mandatoryRemaining)
            statusRow(icon: "eye.slash.fill", color: .blue,
                      label: "Hidden", count: engine.hiddenOnMapCount)
            statusRow(icon: "scope", color: .purple,
                      label: "Stealth", count: engine.stealthOnARCount)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func statusRow(icon: String, color: Color, label: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            Text("\(count)")
                .font(.caption.bold())
                .foregroundColor(.primary)
        }
    }
}

#if DEBUG
#Preview("GameStatusBar") {
    let engine = GameEngine()
    engine.mineCount = 1
    engine.mandatoryRemaining = 4
    engine.hiddenOnMapCount = 1
    engine.stealthOnARCount = 0
    return GameStatusBar(engine: engine).padding()
}
#endif
