// Views/MissionPlay/ARSearchView.swift — Standalone AR Search 데모 화면 (`ar-search`)
// 디자인: design_handoff_playspot_redesign/README.md §3 AR Searching
// 게임 엔진 비연결 — 그래픽/애니메이션 데모. 실제 플레이 화면은 ARGameView 가 담당.
// 모든 색상은 DuoTokens 의 Color extension 만 사용.
import SwiftUI

struct ARSearchView: View {
    // 핀 애니메이션 상태
    @State private var floatY: CGFloat = 0
    @State private var swayAngle: Double = -5
    @State private var popScale: CGFloat = 1.0
    @State private var glowRotation: Double = 0

    // 진입/닫기
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            cameraBackground
                .ignoresSafeArea()

            // 핀 — 화면 40% 지점에 부유
            GeometryReader { geo in
                animatedStartPin
                    .position(x: geo.size.width * 0.5,
                              y: geo.size.height * 0.42)
            }

            VStack(spacing: 0) {
                topHUD
                Spacer()
                bottomHUD
            }
        }
        .statusBarHidden(true)
        .onAppear { startAnimations() }
    }

    // MARK: - 상단 HUD (green-500 → green-700 그라데이션)

    private var topHUD: some View {
        HStack(spacing: 8) {
            // MAP 버튼 — 64×36 dark teal
            Button {
                (onClose ?? { dismiss() })()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("MAP")
                        .font(.duoDisplay(size: 12))
                        .kerning(0.6)
                }
                .foregroundColor(.white)
                .frame(width: 64, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10).fill(Color.hudDarkEnd)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)

            Spacer(minLength: 4)

            // 가운데: 흰색 카드 타이머 00:09:00 — 1.5px 흰 보더, 그림자 없음
            DigitClock(
                seconds: 9 * 60,
                style: .light,
                digitFontSize: 18,
                digitWidth: 18,
                digitHeight: 28
            )

            Spacer(minLength: 4)

            // 우측 — 좌측 MAP 64pt 와 시각 균형 (보이지 않는 placeholder)
            Color.clear.frame(width: 64, height: 36)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                colors: [Color.duoGreen500, Color.duoGreen700],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - 카메라 뷰 배경 (RadialGradient + 나무 실루엣)

    private var cameraBackground: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: 0x6FA356), Color(hex: 0x1B3815)],
                center: .center,
                startRadius: 40,
                endRadius: 520
            )

            // 절차적 나무 실루엣 — 좌우에 3그루씩
            GeometryReader { geo in
                ForEach(Self.treePositions, id: \.self) { p in
                    TreeSilhouette()
                        .fill(Color(hex: 0x0E2009).opacity(0.55))
                        .frame(width: p.size, height: p.size * 1.4)
                        .position(x: geo.size.width * p.x,
                                  y: geo.size.height * p.y)
                }
            }
        }
    }

    private static let treePositions: [TreeAnchor] = [
        TreeAnchor(x: 0.08, y: 0.55, size: 140),
        TreeAnchor(x: 0.92, y: 0.58, size: 160),
        TreeAnchor(x: 0.20, y: 0.72, size: 110),
        TreeAnchor(x: 0.80, y: 0.74, size: 120),
        TreeAnchor(x: 0.40, y: 0.85, size: 80),
        TreeAnchor(x: 0.65, y: 0.88, size: 90)
    ]

    // MARK: - 애니메이션 핀 (a~f)

    private var animatedStartPin: some View {
        ZStack {
            // (e) 회전하는 conic gradient 글로우 링
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.duoBee.opacity(0.0), location: 0.0),
                            .init(color: Color.duoBee.opacity(0.55), location: 0.18),
                            .init(color: Color.duoBee.opacity(0.0), location: 0.4)
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

            // (d) 펄스 링 2개 — TimelineView 로 0.7→2.0 페이드
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                Canvas { canvasCtx, size in
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
                        let diameter = baseSize * scale
                        path.addEllipse(in: CGRect(
                            x: center.x - diameter / 2,
                            y: center.y - diameter / 2,
                            width: diameter,
                            height: diameter
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

            // (f) 노란 sparkle 입자 3개 — 위로 떠올랐다 사라짐
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                Canvas { canvasCtx, size in
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
            Image("Items/i_start")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 67)
                .shadow(color: Color.duoBee.opacity(0.5), radius: 12)
                .scaleEffect(popScale)
                .rotationEffect(.degrees(swayAngle))
                .offset(y: floatY)
        }
        .frame(width: 200, height: 200)
    }

    private func startAnimations() {
        // (a) Float — -12pt 위아래, 2.2s spring autoreverse
        withAnimation(.spring(response: 2.2, dampingFraction: 0.55).repeatForever(autoreverses: true)) {
            floatY = -12
        }
        // (b) Sway — -5° ↔ +5°, 2.8s
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            swayAngle = 5
        }
        // (c) Pop — 1.0 ↔ 1.08, 2.2s
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            popScale = 1.08
        }
        // (e) Conic gradient 회전 — 3.6s linear infinite
        withAnimation(.linear(duration: 3.6).repeatForever(autoreverses: false)) {
            glowRotation = 360
        }
    }

    // MARK: - 하단 AR HUD (hudDark: #1A5E69 → #0E3A42)

    private var bottomHUD: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                // 좌 — 시작 깃발 + "Start / 2m"
                infoStack(
                    iconName: "flag.fill",
                    iconTint: .duoMacaw,
                    label: "Start",
                    value: "2m",
                    valueColor: .duoBee
                )
                .frame(maxWidth: .infinity)

                // 중앙 — 빈 자리 (떠있는 레이더 자리)
                Spacer().frame(width: 80)

                // 우 — 지도 핀 + "유효 반경 / 100m"
                infoStack(
                    iconName: "mappin.and.ellipse",
                    iconTint: .duoGreen500,
                    label: "유효 반경",
                    value: "100m",
                    valueColor: .duoMacaw,
                    alignment: .trailing
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .frame(height: 88)
            .background(LinearGradient.hudDark.ignoresSafeArea(edges: .bottom))

            // 떠있는 레이더 — 위로 -32 offset, 64pt 디스크
            floatingRadar
                .offset(y: -32)
        }
    }

    private func infoStack(iconName: String,
                           iconTint: Color,
                           label: String,
                           value: String,
                           valueColor: Color,
                           alignment: HorizontalAlignment = .leading) -> some View {
        HStack(spacing: 10) {
            if alignment == .leading {
                Image(systemName: iconName)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(iconTint)
                    .shadow(color: iconTint.opacity(0.6), radius: 4)
            }
            VStack(alignment: alignment, spacing: 2) {
                Text(label)
                    .font(.duoDisplay(size: 12))
                    .foregroundColor(.white.opacity(0.85))
                Text(value)
                    .font(.duoDisplay(size: 14))
                    .foregroundColor(valueColor)
            }
            if alignment == .trailing {
                Image(systemName: iconName)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(iconTint)
                    .shadow(color: iconTint.opacity(0.6), radius: 4)
            }
        }
    }

    // 64pt 녹색 레이더 디스크 — sweep + 화살표 needle + 중앙 hub
    private var floatingRadar: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            ZStack {
                Circle()
                    .fill(RadialGradient.radarDisc)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .overlay(Circle().inset(by: 3).stroke(Color.black.opacity(0.3), lineWidth: 1.5))

                // 동심원 + 십자
                Circle().inset(by: 12).stroke(Color.white.opacity(0.35), lineWidth: 1)
                Circle().inset(by: 22).stroke(Color.white.opacity(0.3), lineWidth: 1)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 32)); p.addLine(to: CGPoint(x: 64, y: 32))
                    p.move(to: CGPoint(x: 32, y: 0)); p.addLine(to: CGPoint(x: 32, y: 64))
                }
                .stroke(Color.white.opacity(0.35), lineWidth: 1)

                // Sweep — 6s linear
                let sweepRot = (ctx.date.timeIntervalSinceReferenceDate
                                .truncatingRemainder(dividingBy: 6)) / 6.0 * 360.0
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.radarGreenLight.opacity(0.55), location: 0),
                                .init(color: .clear, location: 0.22)
                            ]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        )
                    )
                    .rotationEffect(.degrees(sweepRot))

                // 화살표 needle (북동 35°)
                NeedleArrow()
                    .fill(Color.duoBee)
                    .frame(width: 8, height: 26)
                    .offset(y: -10)
                    .rotationEffect(.degrees(35))
                    .shadow(color: Color.duoBee.opacity(0.7), radius: 3)

                // 중앙 hub
                Circle().fill(Color.duoBee)
                    .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(Color.duoEel2, lineWidth: 1.2))
            }
            .frame(width: 64, height: 64)
            .shadow(color: Color.black.opacity(0.45), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - 입자 / 화살표 / 나무 Shape

private extension ARSearchView {
    static func sparklePath(size: CGFloat) -> Path {
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

private struct TreeAnchor: Hashable {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
}

/// 단순 절차적 침엽수 실루엣 — 3단 삼각형 + 줄기.
private struct TreeSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let cx = w / 2
        let trunkW = w * 0.16

        // 줄기
        p.addRect(CGRect(x: cx - trunkW / 2, y: h * 0.85,
                          width: trunkW, height: h * 0.15))

        // 3단 삼각형 (위로 갈수록 좁아짐)
        for i in 0..<3 {
            let topY = h * (0.05 + 0.20 * CGFloat(i))
            let baseY = h * (0.40 + 0.20 * CGFloat(i))
            let scale = 1.0 - 0.15 * CGFloat(i)
            let halfBase = w / 2 * scale
            p.move(to: CGPoint(x: cx, y: topY))
            p.addLine(to: CGPoint(x: cx + halfBase, y: baseY))
            p.addLine(to: CGPoint(x: cx - halfBase, y: baseY))
            p.closeSubpath()
        }
        return p
    }
}

private struct NeedleArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // 화살촉
        p.move(to: CGPoint(x: w / 2, y: 0))
        p.addLine(to: CGPoint(x: w, y: h * 0.3))
        p.addLine(to: CGPoint(x: w * 0.66, y: h * 0.3))
        // 샤프트
        p.addLine(to: CGPoint(x: w * 0.66, y: h))
        p.addLine(to: CGPoint(x: w * 0.33, y: h))
        p.addLine(to: CGPoint(x: w * 0.33, y: h * 0.3))
        p.addLine(to: CGPoint(x: 0, y: h * 0.3))
        p.closeSubpath()
        return p
    }
}

#if DEBUG
#Preview("ARSearch") {
    ARSearchView()
}
#endif
