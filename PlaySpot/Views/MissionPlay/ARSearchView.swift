// Views/MissionPlay/ARSearchView.swift — Standalone AR Search 데모 화면 (`ar-search`)
// 디자인: 사용자 mockup (블루 테마) 기반 정확 매칭.
// 게임 엔진 비연결 — 그래픽/애니메이션 데모. 실제 플레이 화면은 ARGameView 가 담당.
import SwiftUI

struct ARSearchView: View {
    @State private var floatY: CGFloat = 0
    @State private var swayAngle: Double = -5
    @State private var popScale: CGFloat = 1.0
    @State private var glowRotation: Double = 0
    @State private var haloPulse: CGFloat = 1.0

    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            cameraBackground
                .ignoresSafeArea()

            // 핀 — 잔디/모래 경계 부근에 부유
            GeometryReader { geo in
                animatedStartPin
                    .position(x: geo.size.width * 0.36,
                              y: geo.size.height * 0.58)
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

    // MARK: - 상단 HUD (블루 그라데이션)

    private var topHUD: some View {
        HStack(spacing: 10) {
            // MAP 버튼 — dark teal/blue
            Button {
                (onClose ?? { dismiss() })()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("MAP")
                        .font(.duoDisplay(size: 13))
                        .kerning(0.6)
                }
                .foregroundColor(.white)
                .frame(width: 70, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: 0x1F6A8A))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)

            // 타이머 — 흰 카드 + 옅은 블루 보더 + 진한 블루 텍스트
            timerCard(seconds: 9 * 60)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 14)
        .background(
            LinearGradient(
                colors: [Color.duoMacaw, Color.duoMacawDeep],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private func timerCard(seconds: Int) -> some View {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        let formatted = String(format: "%02d:%02d:%02d", h, m, sec)

        return HStack(spacing: 3) {
            ForEach(Array(formatted.enumerated()), id: \.offset) { _, ch in
                if ch == ":" {
                    Text(":")
                        .font(.duoDisplay(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 10)
                } else {
                    Text(String(ch))
                        .font(.duoDisplay(size: 22))
                        .foregroundColor(Color.duoMacawDeep)
                        .frame(width: 22, height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color(hex: 0xB7E1F5), lineWidth: 1.5)
                        )
                }
            }
        }
    }

    // MARK: - 카메라 배경 — 3 레이어 일러스트

    private var cameraBackground: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .top) {
                // 하단 모래/땅
                Color(hex: 0x6E4A2B)
                    .ignoresSafeArea()

                // 잔디 (중간 ~75%)
                Color(hex: 0x4A8C3C)
                    .frame(height: h * 0.66)
                    .frame(maxWidth: .infinity, alignment: .top)

                // 하늘 (상단 ~22%)
                LinearGradient(
                    colors: [Color(hex: 0xA8D8E8), Color(hex: 0x88C4DE)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: h * 0.20)

                // 잔디↔모래 부드러운 곡선 경계
                SoftRidge()
                    .fill(Color(hex: 0xB68A55))
                    .frame(width: w, height: h * 0.20)
                    .offset(y: h * 0.55)

                // 둥근 나무들 (mockup 스타일)
                ForEach(Self.trees, id: \.id) { t in
                    StylizedTree(leafColor: t.leaf, trunkColor: t.trunk)
                        .frame(width: t.size, height: t.size * 1.5)
                        .position(x: w * t.x, y: h * t.y)
                }
            }
        }
    }

    private struct TreePlacement: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let leaf: Color
        let trunk: Color
    }

    private static let trees: [TreePlacement] = [
        // 위쪽 row — 큰 나무 (멀리 보이는 듯)
        TreePlacement(x: 0.15, y: 0.30, size: 200, leaf: Color(hex: 0x5A9A4A), trunk: Color(hex: 0x6E4A2B)),
        TreePlacement(x: 0.55, y: 0.26, size: 240, leaf: Color(hex: 0x4A8C3C), trunk: Color(hex: 0x6E4A2B)),
        TreePlacement(x: 0.88, y: 0.32, size: 180, leaf: Color(hex: 0x5A9A4A), trunk: Color(hex: 0x6E4A2B)),
        // 가운데 — 작은 나무
        TreePlacement(x: 0.70, y: 0.50, size: 110, leaf: Color(hex: 0x7CB55E), trunk: Color(hex: 0x8B5A30))
    ]

    // MARK: - 애니메이션 핀

    private var animatedStartPin: some View {
        ZStack {
            // 노란 halo 디스크 (mockup 의 핀 아래 큰 원)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.duoBee.opacity(0.55), Color.duoBee.opacity(0.05), .clear],
                        center: .center, startRadius: 5, endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(haloPulse)
                .blendMode(.screen)

            // (e) 회전하는 conic 글로우
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.duoBee.opacity(0), location: 0.0),
                            .init(color: Color.duoBee.opacity(0.7), location: 0.16),
                            .init(color: Color.duoBee.opacity(0), location: 0.38)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    lineWidth: 16
                )
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(glowRotation))
                .blur(radius: 2.5)

            // (d) 펄스 링 2개
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
                        let d = baseSize * scale
                        path.addEllipse(in: CGRect(
                            x: center.x - d / 2,
                            y: center.y - d / 2,
                            width: d, height: d
                        ))
                        canvasCtx.stroke(
                            path,
                            with: .color(Color.duoBee.opacity(opacity * 0.75)),
                            lineWidth: 2.5
                        )
                    }
                }
            }
            .frame(width: 200, height: 200)
            .allowsHitTesting(false)

            // (f) Sparkle
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                Canvas { canvasCtx, size in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    let duration = 1.4
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let positions: [(dx: CGFloat, dy: CGFloat)] = [
                        (-26, 6), (4, -10), (24, 8)
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

            // 핀 본체 (a + b + c)
            ZStack(alignment: .topTrailing) {
                Image("Items/i_start")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 77)
                    .shadow(color: Color.duoBee.opacity(0.5), radius: 12)

                // 필수 별 뱃지
                ZStack {
                    Circle().fill(Color.duoBee)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(.white)
                }
                .frame(width: 28, height: 28)
                .offset(x: 12, y: -4)
            }
            .scaleEffect(popScale)
            .rotationEffect(.degrees(swayAngle))
            .offset(y: floatY)
        }
        .frame(width: 220, height: 220)
    }

    private func startAnimations() {
        withAnimation(.spring(response: 2.2, dampingFraction: 0.55).repeatForever(autoreverses: true)) {
            floatY = -12
        }
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            swayAngle = 5
        }
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            popScale = 1.08
        }
        withAnimation(.linear(duration: 3.6).repeatForever(autoreverses: false)) {
            glowRotation = 360
        }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            haloPulse = 1.18
        }
    }

    // MARK: - 하단 HUD

    private var bottomHUD: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                // 좌 — 깃발 outline + "Start / 2m" (값 노란)
                HStack(spacing: 12) {
                    Image(systemName: "flag")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Start")
                            .font(.duoDisplay(size: 16))
                            .foregroundColor(.white)
                        Text("2m")
                            .font(.duoDisplay(size: 22))
                            .foregroundColor(Color.duoBee)
                    }
                }
                .padding(.leading, 18)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer().frame(width: 90)

                // 우 — 마커 + "유효 반경 / 100m" (값 노란)
                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("유효 반경")
                            .font(.duoDisplay(size: 14))
                            .foregroundColor(.white)
                        Text("100m")
                            .font(.duoDisplay(size: 22))
                            .foregroundColor(Color.duoBee)
                    }
                    // 녹색 마커 with disc base
                    ZStack {
                        Ellipse()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 30, height: 10)
                            .offset(y: 14)
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundStyle(.white, Color.duoGreen500)
                    }
                }
                .padding(.trailing, 18)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(height: 96)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x1A5E69), Color(hex: 0x0B2A32)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            )

            // 떠있는 레이더
            floatingRadar
                .offset(y: -34)
        }
    }

    private var floatingRadar: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            ZStack {
                Circle()
                    .fill(RadialGradient.radarDisc)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                    .overlay(Circle().inset(by: 3).stroke(Color.black.opacity(0.3), lineWidth: 1.5))

                Circle().inset(by: 12).stroke(Color.white.opacity(0.35), lineWidth: 1)
                Circle().inset(by: 22).stroke(Color.white.opacity(0.3), lineWidth: 1)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 36)); p.addLine(to: CGPoint(x: 72, y: 36))
                    p.move(to: CGPoint(x: 36, y: 0)); p.addLine(to: CGPoint(x: 36, y: 72))
                }
                .stroke(Color.white.opacity(0.35), lineWidth: 1)

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

                NeedleArrow()
                    .fill(Color.duoBee)
                    .frame(width: 9, height: 30)
                    .offset(y: -11)
                    .rotationEffect(.degrees(35))
                    .shadow(color: Color.duoBee.opacity(0.7), radius: 3)

                Circle().fill(Color.duoBee)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.duoEel2, lineWidth: 1.2))
            }
            .frame(width: 72, height: 72)
            .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Shapes

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

/// 잔디↔모래 경계의 부드러운 능선.
private struct SoftRidge: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.height * 0.3))
        p.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.4),
            control1: CGPoint(x: rect.width * 0.3, y: 0),
            control2: CGPoint(x: rect.width * 0.7, y: rect.height * 0.6)
        )
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.closeSubpath()
        return p
    }
}

/// Mockup 스타일 둥근 나무 — 줄기 + 3개 둥근 잎 클러스터.
private struct StylizedTree: View {
    let leafColor: Color
    let trunkColor: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // 줄기
                Rectangle()
                    .fill(trunkColor)
                    .frame(width: w * 0.10, height: h * 0.55)
                    .position(x: w / 2, y: h * 0.62)

                // 큰 둥근 잎 (위)
                Ellipse()
                    .fill(leafColor)
                    .frame(width: w * 1.0, height: h * 0.42)
                    .position(x: w / 2, y: h * 0.20)

                // 중간 잎 (왼쪽)
                Ellipse()
                    .fill(leafColor.opacity(0.92))
                    .frame(width: w * 0.65, height: h * 0.28)
                    .position(x: w * 0.28, y: h * 0.32)

                // 중간 잎 (오른쪽)
                Ellipse()
                    .fill(leafColor.opacity(0.92))
                    .frame(width: w * 0.70, height: h * 0.30)
                    .position(x: w * 0.72, y: h * 0.30)

                // 작은 잎 (아래쪽)
                Ellipse()
                    .fill(leafColor.opacity(0.7))
                    .frame(width: w * 0.50, height: h * 0.18)
                    .position(x: w / 2, y: h * 0.50)
            }
        }
    }
}

private struct NeedleArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w / 2, y: 0))
        p.addLine(to: CGPoint(x: w, y: h * 0.3))
        p.addLine(to: CGPoint(x: w * 0.66, y: h * 0.3))
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
