// Views/DesignSystem/WordmarkPlaySpot.swift
// 미니게임 배경의 외곽선 PLAY SPOT 워드마크.
// progress 가 0→1 로 증가할수록 brightness 0.55→1.05, saturate 0.4→1.8, drop-shadow glow.
// 디자인: README §4 AR Mini-game / screens-game.jsx ScreenARFound

import SwiftUI

struct WordmarkPlaySpot: View {
    /// 0...1. 미니게임 진행률.
    var progress: Double = 0
    /// outline (검정 외곽) vs color (컬러 워드마크).
    var variant: Variant = .outline

    enum Variant {
        case outline   // playspot_logo (검정 외곽, 미니게임 배경)
        case color     // playspot_logo_color (Item Acquired 팝업)

        var assetName: String {
            switch self {
            case .outline: return "Minigame/playspot_logo"
            case .color:   return "Minigame/playspot_logo_color"
            }
        }
    }

    var body: some View {
        let brightness = 0.55 + (1.05 - 0.55) * progress.clamped01
        let saturation = 0.4 + (1.8 - 0.4) * progress.clamped01
        let glowOpacity = max(0, (progress.clamped01 - 0.5) * 2.0)  // >50% 부터 점등

        Image(variant.assetName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .brightness(brightness - 1.0)
            .saturation(saturation)
            .shadow(color: Color.duoBee.opacity(0.6 * glowOpacity),
                    radius: 18 * glowOpacity, x: 0, y: 0)
            .shadow(color: Color.duoFox.opacity(0.3 * glowOpacity),
                    radius: 32 * glowOpacity, x: 0, y: 0)
            .animation(.easeOut(duration: 0.25), value: progress)
    }
}

private extension Double {
    var clamped01: Double { min(1, max(0, self)) }
}

#if DEBUG
#Preview("Wordmark") {
    struct Demo: View {
        @State var p: Double = 0
        var body: some View {
            VStack(spacing: 16) {
                WordmarkPlaySpot(progress: p)
                    .frame(maxHeight: 220)
                Slider(value: $p, in: 0...1)
                Text("Progress: \(Int(p * 100))%")
                WordmarkPlaySpot(variant: .color)
                    .frame(maxHeight: 200)
            }
            .padding()
            .background(Color.black.opacity(0.85))
        }
    }
    return Demo()
}
#endif
