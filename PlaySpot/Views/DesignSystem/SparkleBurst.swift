// Views/DesignSystem/SparkleBurst.swift
// AR 미니게임 탭 시 14개 파티클이 80~140px 바깥으로 0.7s 동안 fly + rotate + scale + fade.
// Canvas + TimelineView(.animation) 으로 30fps 렌더 — 14 파티클이라 매우 가벼움.
// trigger 카운터를 외부에서 증가시키면 새 burst 가 그려진다.
// 디자인: README §4 AR Mini-game / screens-game.jsx SparkleBurst

import SwiftUI

struct SparkleBurst: View {
    /// 0 = 비활성 / 변경될 때마다 새 burst 트리거.
    var trigger: Int
    var radius: CGFloat = 120
    var particleCount: Int = 14
    var duration: Double = 0.7

    @State private var startTime: Date?

    private static let palette: [Color] = [
        .duoBee, .duoFox, .duoMacaw, .white
    ]

    private static let particles: [(angle: Double, dist: CGFloat, rot: Double, color: Color)] = {
        // 결정론적 — trigger 마다 같은 패턴이라도 시각적으로 충분히 다양함.
        var rng = SeededGen(seed: 42)
        return (0..<14).map { i in
            let baseAngle = Double(i) / 14.0 * .pi * 2.0
            let jitter = (rng.next() - 0.5) * 0.6
            let dist = 80 + rng.next() * 60          // 80–140
            let rot = (rng.next() - 0.5) * 720       // ±360deg
            let color = palette[Int(rng.next() * Double(palette.count)) % palette.count]
            return (baseAngle + jitter, CGFloat(dist), rot, color)
        }
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            Canvas { canvasCtx, size in
                let t: Double
                if let start = startTime {
                    let elapsed = ctx.date.timeIntervalSince(start)
                    t = min(1.0, elapsed / duration)
                } else {
                    t = 1.0
                }
                guard t < 1.0 else { return }

                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let ease = 1 - pow(1 - t, 3)
                let opacity = 1.0 - t
                let scale = 1.0 - t * 0.6

                for p in Self.particles {
                    let dx = cos(p.angle) * Double(p.dist) * ease
                    let dy = sin(p.angle) * Double(p.dist) * ease
                    let pt = CGPoint(x: center.x + dx, y: center.y + dy)
                    let rot = Angle.degrees(p.rot * ease)

                    canvasCtx.drawLayer { layer in
                        layer.translateBy(x: pt.x, y: pt.y)
                        layer.rotate(by: rot)
                        layer.scaleBy(x: scale, y: scale)
                        layer.opacity = opacity
                        layer.fill(
                            starPath(in: CGRect(x: -6, y: -6, width: 12, height: 12)),
                            with: .color(p.color)
                        )
                    }
                }
            }
        }
        .frame(width: radius * 2, height: radius * 2)
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            startTime = Date()
        }
    }

    private func starPath(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX, cy = rect.midY
        let outer: CGFloat = min(rect.width, rect.height) / 2
        let inner: CGFloat = outer * 0.4
        for i in 0..<10 {
            let r = (i.isMultiple(of: 2)) ? outer : inner
            let a = Double(i) * .pi / 5 - .pi / 2
            let pt = CGPoint(x: cx + cos(a) * Double(r), y: cy + sin(a) * Double(r))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// 결정론적 PRNG — 미리 계산된 파티클 패턴용.
private struct SeededGen {
    var state: UInt64
    init(seed: UInt64) { state = seed &* 2862933555777941757 &+ 3037000493 }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 32) / Double(UInt32.max)
    }
}

#if DEBUG
#Preview("SparkleBurst") {
    struct Demo: View {
        @State var count = 0
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                SparkleBurst(trigger: count)
                Button("Burst! (\(count))") { count += 1 }
                    .buttonStyle(.primary)
                    .frame(width: 200)
            }
        }
    }
    return Demo()
}
#endif
