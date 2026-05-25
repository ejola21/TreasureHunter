// Views/DesignSystem/PulseRing.swift
// 플레이어 위치 / AR 핀 / 튜토리얼 핀 펄스 효과.
// scale 0.6→2.4, opacity 0.55→0, 1.8s ease-out infinite.
// 디자인: README §"animation specs" Pulse ring

import SwiftUI

struct PulseRing: View {
    var color: Color = .duoMacaw
    var size: CGFloat = 24
    var rings: Int = 2
    var duration: Double = 1.8

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<rings, id: \.self) { i in
                    let phase = ((t + Double(i) * (duration / Double(rings))).truncatingRemainder(dividingBy: duration)) / duration
                    let scale = 0.6 + (2.4 - 0.6) * phase
                    let opacity = 0.55 * (1 - phase)
                    Circle()
                        .stroke(color, lineWidth: 3)
                        .frame(width: size, height: size)
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
            }
            .frame(width: size * 2.4, height: size * 2.4)
        }
    }
}

#if DEBUG
#Preview("PulseRing") {
    VStack(spacing: 60) {
        ZStack {
            PulseRing()
            Circle().fill(Color.duoMacaw).frame(width: 24, height: 24)
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
        }
        ZStack {
            PulseRing(color: .duoCardinal, size: 32, rings: 3)
            Circle().fill(Color.duoCardinal).frame(width: 32, height: 32)
        }
    }
    .padding(60)
    .background(Color.duoSnow)
}
#endif
