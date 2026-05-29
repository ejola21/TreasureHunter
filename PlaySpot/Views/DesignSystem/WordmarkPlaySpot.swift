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
        switch variant {
        case .color:
            // 팝업/프리뷰 — 풀컬러 워드마크 (채움 연출 없음).
            Image(variant.assetName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        case .outline:
            fillingWordmark
        }
    }

    /// 미니게임 — 색이 아래에서 위로 차오르는 워드마크.
    /// 회색 베이스(로고 모양) 위로 Duo 테마 그린 그라데이션을 로고 모양으로 클립해
    /// progress 만큼 하단부터 reveal. 같은 에셋을 마스크로 재사용해 자기정렬.
    private var fillingWordmark: some View {
        let p = progress.clamped01
        let glowOpacity = max(0, (p - 0.5) * 2.0)  // >50% 부터 점등
        let logoShape = Image(variant.assetName)
            .resizable()
            .aspectRatio(contentMode: .fit)
        return logoShape
            // 베이스 — 채도 제거 + 어둡게 (아직 안 채워진 부분)
            .saturation(0)
            .brightness(-0.35)
            .opacity(0.55)
            .overlay {
                // 채움 — Duo 테마 그린 그라데이션, 로고 모양 클립 + 하단부터 progress 만큼 reveal
                LinearGradient(
                    colors: [.duoGreen750, .duoGreen500, .duoGreen400],
                    startPoint: .bottom, endPoint: .top
                )
                .mask { logoShape }
                .mask(alignment: .bottom) {
                    GeometryReader { geo in
                        Rectangle()
                            .frame(height: geo.size.height * p)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
                .shadow(color: Color.duoBee.opacity(0.6 * glowOpacity),
                        radius: 18 * glowOpacity, x: 0, y: 0)
                .shadow(color: Color.duoGreen400.opacity(0.4 * glowOpacity),
                        radius: 32 * glowOpacity, x: 0, y: 0)
            }
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
