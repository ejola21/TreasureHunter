// Views/DesignSystem/ARRadar.swift
// 64×64 컴퍼스 위젯 — radial green gradient + 동심원 + sweep + needle + center hub + blip.
// TimelineView(.animation) 으로 60fps 회전. CPU 비용은 낮음.
// 디자인: README §"Radar (AR HUD)" / screens-game.jsx ARRadar

import SwiftUI

struct ARRadar: View {
    var size: CGFloat = 64
    /// 노란 needle 회전각 (도). 0 = 위, 시계방향 +.
    var angle: Double = 35
    /// blip 위치 (0…1 비율, x: 좌상단 0,0 기준).
    var blip: CGPoint = CGPoint(x: 0.18, y: 0.68)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            // 6초 한 바퀴 (linear)
            let sweepRot = (t.truncatingRemainder(dividingBy: 6)) / 6.0 * 360.0

            ZStack {
                // 디스크 + 외곽 보더
                Circle()
                    .fill(RadialGradient.radarDisc)
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .overlay(Circle().inset(by: 3).stroke(Color.black.opacity(0.35), lineWidth: 2))

                // 동심원 2개
                Circle().inset(by: size * 0.18)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                Circle().inset(by: size * 0.32)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)

                // 십자 (40% opacity, 1px)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: size / 2))
                    p.addLine(to: CGPoint(x: size, y: size / 2))
                    p.move(to: CGPoint(x: size / 2, y: 0))
                    p.addLine(to: CGPoint(x: size / 2, y: size))
                }
                .stroke(Color.white.opacity(0.4), lineWidth: 1)

                // sweep — conic gradient 70deg 페이드, 6s rotate
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.radarGreenLight.opacity(0.6), location: 0),
                                .init(color: .clear, location: 0.20)
                            ]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        )
                    )
                    .rotationEffect(.degrees(sweepRot))

                // Needle — 노란 화살표 (위쪽에서 angle 회전). fill + stroke 합성.
                ZStack {
                    Needle().fill(Color.duoBee)
                    Needle().stroke(Color.duoBeeDeep, lineWidth: 1)
                }
                .frame(width: 6, height: size * 0.4)
                .offset(y: -size * 0.18)
                .rotationEffect(.degrees(angle))
                .shadow(color: Color.duoBee.opacity(0.6), radius: 3)

                // 중앙 hub
                Circle().fill(Color.duoBee)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(Color.duoEel2, lineWidth: 1.5))
                    .shadow(color: Color.duoBee.opacity(0.7), radius: 4)

                // Blip — 흰 점 + 글로우
                Circle().fill(Color.white)
                    .frame(width: 5, height: 5)
                    .shadow(color: Color.white.opacity(0.9), radius: 4)
                    .position(x: blip.x * size, y: blip.y * size)
            }
            .frame(width: size, height: size)
        }
    }
}

private struct Needle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // 화살촉 (위쪽 삼각형) + 샤프트 (아래 길쭉한 사각형)
        p.move(to: CGPoint(x: w / 2, y: 0))
        p.addLine(to: CGPoint(x: w, y: h * 0.25))
        p.addLine(to: CGPoint(x: w * 0.66, y: h * 0.25))
        p.addLine(to: CGPoint(x: w * 0.66, y: h))
        p.addLine(to: CGPoint(x: w * 0.33, y: h))
        p.addLine(to: CGPoint(x: w * 0.33, y: h * 0.25))
        p.addLine(to: CGPoint(x: 0, y: h * 0.25))
        p.closeSubpath()
        return p
    }
}

#if DEBUG
#Preview("ARRadar") {
    VStack(spacing: 24) {
        ARRadar(size: 64, angle: 35)
        ARRadar(size: 96, angle: 120, blip: CGPoint(x: 0.8, y: 0.2))
        ARRadar(size: 48, angle: -30)
    }
    .padding()
    .background(LinearGradient.hudTeal)
}
#endif
