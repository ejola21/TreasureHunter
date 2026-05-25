// AR/ARItemView.swift — Phase 4 candy 핀 (6가지 애니메이션)
// 디자인: design_handoff_playspot_redesign/README.md §3 AR Searching
// 6 애니메이션:
//   (a) Float: -12pt 위아래 (spring 2.2s)
//   (b) Sway: ±5° 좌우 회전 (2.8s)
//   (c) Pop: 1.08x scale (2.2s)
//   (d) Pulse rings: 2개 노란 원, 0.7→2.0 페이드 (1.6s)
//   (e) Conic gradient 글로우 회전 (3.6s)
//   (f) Sparkle 3개 위로 떠올랐다 사라짐 (1.4s)
import SwiftUI

struct ARItemView: View {
    let item: MissionItem
    let isAcquired: Bool
    var isHiddenByShowType: Bool = false

    @State private var floatY: CGFloat = 0
    @State private var swayAngle: Double = -5
    @State private var popScale: CGFloat = 1.0
    @State private var glowRotation: Double = 0

    var body: some View {
        ZStack {
            // (e) 회전하는 conic gradient 글로우 — bee 색 호
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.duoBee.opacity(0), location: 0.0),
                            .init(color: Color.duoBee.opacity(0.55), location: 0.18),
                            .init(color: Color.duoBee.opacity(0), location: 0.4)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    lineWidth: 14
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(glowRotation))
                .blur(radius: 2)
                .opacity(isAcquired ? 0 : 1)

            // (d) 펄스 링 2개
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                Canvas { canvasCtx, size in
                    guard !isAcquired else { return }
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    let duration = 1.6
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let baseSize: CGFloat = 70
                    for i in 0..<2 {
                        let offset = Double(i) * (duration / 2)
                        let phase = ((t + offset).truncatingRemainder(dividingBy: duration)) / duration
                        let scale = 0.7 + (2.0 - 0.7) * phase
                        let opacity = 1.0 - phase

                        var path = Path()
                        let d = baseSize * scale
                        path.addEllipse(in: CGRect(
                            x: center.x - d / 2,
                            y: center.y - d / 2,
                            width: d, height: d
                        ))
                        canvasCtx.stroke(
                            path,
                            with: .color(Color.duoBee.opacity(opacity * 0.7)),
                            lineWidth: 2.5
                        )
                    }
                }
            }
            .frame(width: 200, height: 200)
            .allowsHitTesting(false)

            // (f) Sparkle 입자 3개 — 위로 떠올랐다 사라짐
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                Canvas { canvasCtx, size in
                    guard !isAcquired else { return }
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    let duration = 1.4
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let positions: [(dx: CGFloat, dy: CGFloat)] = [
                        (-22, 4), (0, -8), (22, 6)
                    ]
                    for (idx, p) in positions.enumerated() {
                        let offset = Double(idx) * (duration / 3)
                        let phase = ((t + offset).truncatingRemainder(dividingBy: duration)) / duration
                        let rise = CGFloat(phase) * 60
                        let opacity = (1.0 - phase) * (phase < 0.1 ? phase * 10 : 1.0)
                        let scale = 0.6 + 0.6 * (1.0 - phase)

                        canvasCtx.drawLayer { layer in
                            layer.translateBy(
                                x: center.x + p.dx,
                                y: center.y + p.dy - rise
                            )
                            layer.scaleBy(x: scale, y: scale)
                            layer.opacity = opacity
                            layer.fill(
                                Self.sparklePath(size: 8),
                                with: .color(Color.duoBee)
                            )
                        }
                    }
                }
            }
            .frame(width: 200, height: 200)
            .allowsHitTesting(false)

            // 핀 본체 — (a) float + (b) sway + (c) pop 합성
            ZStack(alignment: .topTrailing) {
                Image(item.arIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 108)
                    .opacity(isAcquired ? 0.4 : 1.0)
                    .shadow(color: Color.duoBee.opacity(0.5), radius: 12)

                if item.isMandatory {
                    StarBadge(size: 26)
                        .offset(x: 8, y: -6)
                }
            }
            .scaleEffect(popScale)
            .rotationEffect(.degrees(swayAngle))
            .offset(y: floatY)
        }
        .frame(width: 200, height: 200)
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        guard !isAcquired else { return }
        // (a) Float
        withAnimation(.spring(response: 2.2, dampingFraction: 0.55).repeatForever(autoreverses: true)) {
            floatY = -12
        }
        // (b) Sway
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            swayAngle = 5
        }
        // (c) Pop
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            popScale = 1.08
        }
        // (e) Conic gradient 회전
        withAnimation(.linear(duration: 3.6).repeatForever(autoreverses: false)) {
            glowRotation = 360
        }
    }

    private static func sparklePath(size: CGFloat) -> Path {
        var p = Path()
        let half = size / 2
        let mid = size * 0.18
        p.move(to: CGPoint(x: half, y: 0))
        p.addLine(to: CGPoint(x: half + mid, y: half - mid))
        p.addLine(to: CGPoint(x: size, y: half))
        p.addLine(to: CGPoint(x: half + mid, y: half + mid))
        p.addLine(to: CGPoint(x: half, y: size))
        p.addLine(to: CGPoint(x: half - mid, y: half + mid))
        p.addLine(to: CGPoint(x: 0, y: half))
        p.addLine(to: CGPoint(x: half - mid, y: half - mid))
        p.closeSubpath()
        return p
    }
}

/// 필수 아이템 표시용 노란 별 뱃지.
private struct StarBadge: View {
    var size: CGFloat = 22
    var body: some View {
        ZStack {
            Circle().fill(Color.duoBee)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.5, weight: .heavy))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

#if DEBUG
#Preview("ARItem") {
    HStack(spacing: 24) {
        ARItemView(item: .preview, isAcquired: false)
        ARItemView(item: .preview, isAcquired: true)
    }
    .padding()
    .background(Color.black)
}
#endif
