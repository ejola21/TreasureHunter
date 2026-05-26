// Views/MissionPlay/ItemAcquiredPopup.swift
// Item Acquired V2 — 게임성 강화 쇼케이스 팝업.
// 구성:
//   ① 130pt 쇼케이스 헤더 — 회전 광선 2겹 + 할로 펄스 + 충격파 링 2개
//        + 별 스파클 7개 + 컨페티 18개 + 아이템 바운스 등장 + 키커
//   ② 본문 — 영문/한글 병기 타이틀 + 설명
//   ③ 오렌지 CTA — shimmer 애니메이션 + 캔디 press 피드백
//
// 시그니처 (alert: ItemAcquiredAlert, onOK: () -> Void) 유지 — GameEngine 호출부 변경 없음.
// 아이템 tint 는 itemIconName 으로부터 유도. Reduce Motion 시 무한 애니메이션 정지.
// 디자인: README §"Item Acquired Popup" / screens-v2.jsx ItemAcquiredPopupV2

import SwiftUI

struct ItemAcquiredPopup: View {
    let alert: ItemAcquiredAlert
    let onOK: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cardAppeared = false

    private var tint: Color { ItemTintResolver.tint(for: alert.itemIconName) }
    private var tintDeep: Color { ItemTintResolver.tintDeep(for: alert.itemIconName) }

    /// 영문 / 한글 타이틀 분리. alert.title 이 영어이고 alert.message 1행이 한글 헤더인
    /// 패턴이 GameEngine 에서 따로 들어오지 않으므로, 보여줄 한글 부제는 message 첫 줄로 대체.
    private var titleEN: String { alert.title }
    private var titleKO: String { ItemTintResolver.koreanTitle(for: alert.itemIconName) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 0) {
                ShowcaseHeader(
                    iconName: alert.itemIconName,
                    tint: tint,
                    reduceMotion: reduceMotion
                )

                ItemBody(
                    titleEN: titleEN,
                    titleKO: titleKO,
                    message: alert.message
                )

                ShimmerCandyButton(
                    titleEN: "OK",
                    titleKO: "확인",
                    tint: .duoFox,
                    deep: .duoFoxDeep,
                    reduceMotion: reduceMotion,
                    action: {
                        HapticService.shared.vibrate()
                        onOK()
                    }
                )
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
                .padding(.top, 6)
            }
            .frame(maxWidth: 300)
            .background(
                RoundedRectangle(cornerRadius: 20).fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20).stroke(Color.duoSwan2, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.55), radius: 18, x: 0, y: 18)
            .scaleEffect(cardAppeared ? 1 : 0.85)
            .opacity(cardAppeared ? 1 : 0)
            .animation(reduceMotion ? .easeOut(duration: 0.18)
                                    : .spring(response: 0.55, dampingFraction: 0.65),
                       value: cardAppeared)
        }
        .onAppear {
            cardAppeared = true
            HapticService.shared.success()
        }
        .transition(.opacity)
    }
}

// MARK: - 130pt 쇼케이스 헤더

private struct ShowcaseHeader: View {
    let iconName: String
    let tint: Color
    let reduceMotion: Bool

    @State private var haloPulse: CGFloat = 1
    @State private var itemAppeared = false
    @State private var bobOffset: CGFloat = 0
    @State private var bobScale: CGFloat = 1
    @State private var ring1Scale: CGFloat = 1
    @State private var ring1Opacity: Double = 0
    @State private var ring2Scale: CGFloat = 1
    @State private var ring2Opacity: Double = 0

    var body: some View {
        ZStack {
            // 다크 라디얼 배경 (아이템 컬러 살짝 틴트)
            RadialGradient(
                colors: [
                    tint.opacity(0.20),
                    Color(hex: 0x1B1410).opacity(0.55),
                    Color(hex: 0x0D0907)
                ],
                center: .center, startRadius: 8, endRadius: 160
            )

            // 회전 광선 2겹 (TimelineView 로 60fps 회전)
            if !reduceMotion {
                RotatingRays(speed: 14, spokes: 12, color: Color(hex: 0xFFD66B), direction: 1)
                    .blendMode(.screen)
                RotatingRays(speed: 22, spokes: 7, color: .white.opacity(0.6), direction: -1)
                    .blendMode(.screen)
            }

            // 충격파 링 2개
            if !reduceMotion {
                ShockRing(color: tint).scaleEffect(ring1Scale).opacity(ring1Opacity)
                ShockRing(color: tint).scaleEffect(ring2Scale).opacity(ring2Opacity)
            }

            // 할로 펄스
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(0.80), tint.opacity(0.33), .clear],
                        center: .center, startRadius: 4, endRadius: 60
                    )
                )
                .frame(width: 105, height: 105)
                .scaleEffect(haloPulse)
                .opacity(reduceMotion ? 0.9 : 1)
                .blendMode(.screen)

            // 별 스파클 7개 (결정론적 배치)
            if !reduceMotion {
                ForEach(0..<7, id: \.self) { i in
                    Sparkle(seed: i)
                }
            }

            // 컨페티 18개 (위에서 떨어짐)
            if !reduceMotion {
                ForEach(0..<18, id: \.self) { i in
                    ConfettiPiece(seed: i)
                }
            }

            // 아이템 PNG — 등장 바운스 + 아이들 bob
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
                .shadow(color: tint.opacity(0.8), radius: 18)
                .shadow(color: .white.opacity(0.6), radius: 8)
                .shadow(color: .black.opacity(0.45), radius: 6, y: 6)
                .scaleEffect(itemAppeared ? bobScale : 0.1)
                .rotationEffect(.degrees(itemAppeared ? 0 : -30))
                .offset(y: bobOffset)

            // 키커 "ITEM ACQUIRED · 아이템 획득"
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    Text("✦")
                        .foregroundColor(Color(hex: 0xFFE066))
                        .opacity(itemAppeared ? 1 : 0)
                    Text("ITEM ACQUIRED · 아이템 획득")
                        .font(.duoDisplay(size: 9))
                        .kerning(0.16 * 9)
                        .foregroundColor(Color(hex: 0xFFE066))
                        .shadow(color: Color(hex: 0xFFC107).opacity(0.6), radius: 4)
                    Text("✦")
                        .foregroundColor(Color(hex: 0xFFE066))
                        .opacity(itemAppeared ? 1 : 0)
                }
                .padding(.bottom, 10)
            }
        }
        .frame(height: 130)
        .frame(maxWidth: .infinity)
        .clipped()
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        // 아이템 등장 + bob/scale 시작
        if reduceMotion {
            itemAppeared = true
            return
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.5)) {
            itemAppeared = true
        }
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
            bobOffset = -7
            bobScale = 1.04
        }
        // 할로 펄스
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
            haloPulse = 1.15
        }
        // 충격파 링 1: 즉시
        animateShockRing(scale: $ring1Scale, opacity: $ring1Opacity, delay: 0)
        // 충격파 링 2: 1.3초 딜레이
        animateShockRing(scale: $ring2Scale, opacity: $ring2Opacity, delay: 1.3)
    }

    private func animateShockRing(scale: Binding<CGFloat>,
                                  opacity: Binding<Double>,
                                  delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            scale.wrappedValue = 1
            opacity.wrappedValue = 0.9
            withAnimation(.easeOut(duration: 2.6).repeatForever(autoreverses: false)) {
                scale.wrappedValue = 2.2
                opacity.wrappedValue = 0
            }
        }
    }
}

// MARK: - 회전 광선 (AngularGradient + 중심 도넛 마스크)

private struct RotatingRays: View {
    /// 한 바퀴 시간 (초).
    var speed: Double
    /// 스파이크 수.
    var spokes: Int
    var color: Color
    /// +1 CW / -1 CCW.
    var direction: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let angle = (t.truncatingRemainder(dividingBy: speed)) / speed * 360.0 * direction

            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(stops: rayStops(spokes: spokes)),
                            center: .center
                        )
                    )
            }
            .rotationEffect(.degrees(angle))
            // 중앙 30% 도넛 마스크 — 중심부 광선 가림
            .mask(
                Circle()
                    .overlay(Circle().scale(0.30).blendMode(.destinationOut))
                    .compositingGroup()
            )
            .opacity(0.55)
        }
    }

    private func rayStops(spokes: Int) -> [Gradient.Stop] {
        let n = max(spokes, 1)
        var stops: [Gradient.Stop] = []
        for i in 0..<n {
            let center = Double(i) / Double(n)
            let half = 0.5 / Double(n) * 0.55
            let lo = max(0, center - half)
            let hi = min(1, center + half)
            stops.append(.init(color: .clear, location: lo))
            stops.append(.init(color: color, location: center))
            stops.append(.init(color: .clear, location: hi))
        }
        return stops
    }
}

// MARK: - 충격파 링

private struct ShockRing: View {
    var color: Color

    var body: some View {
        Circle()
            .strokeBorder(color.opacity(0.85), lineWidth: 2.5)
            .frame(width: 84, height: 84)
            .shadow(color: color.opacity(0.6), radius: 6)
    }
}

// MARK: - 별 스파클 (8각 별)

private struct Sparkle: View {
    let seed: Int

    @State private var scale: CGFloat = 0
    @State private var rotate: Double = 0

    /// 결정론적 위치 — seed 마다 다른 배치 (대략 원 둘레).
    private var position: CGPoint {
        let positions: [CGPoint] = [
            CGPoint(x: -82, y: -32), CGPoint(x: 78, y: -28),
            CGPoint(x: -52, y: 36), CGPoint(x: 60, y: 38),
            CGPoint(x: 0, y: -50),  CGPoint(x: -34, y: -8),
            CGPoint(x: 92, y: 6)
        ]
        return positions[seed % positions.count]
    }

    private var size: CGFloat {
        [9.0, 11.0, 7.0, 12.0, 10.0, 8.0, 11.0][seed % 7]
    }

    private var delay: Double {
        [0.0, 0.4, 0.8, 1.1, 0.2, 0.6, 1.4][seed % 7]
    }

    var body: some View {
        EightPointStar()
            .fill(Color(hex: 0xFFF7CC))
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotate))
            .shadow(color: Color(hex: 0xFFE066).opacity(0.8), radius: 4)
            .offset(x: position.x, y: position.y)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                        scale = 1.2
                        rotate = 20
                    }
                }
            }
    }
}

private struct EightPointStar: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX, cy = rect.midY
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.36
        for i in 0..<16 {
            let r = i.isMultiple(of: 2) ? outer : inner
            let a = Double(i) * .pi / 8 - .pi / 2
            let pt = CGPoint(x: cx + cos(a) * Double(r), y: cy + sin(a) * Double(r))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - 컨페티 조각

private struct ConfettiPiece: View {
    let seed: Int

    @State private var y: CGFloat = -10
    @State private var rotate: Double = 0

    private static let palette: [Color] = [
        .duoBee, .duoFox, .duoCardinal, .duoGreen500, .duoMacaw, .duoBeetle
    ]

    private var color: Color { Self.palette[seed % Self.palette.count] }
    private var isCircle: Bool { seed.isMultiple(of: 3) }
    private var size: CGFloat { CGFloat(5 + (seed % 4) * 2) }
    private var startX: CGFloat {
        // -120 ~ +120 범위에 결정론적 분포
        let bucket = seed % 12
        return CGFloat(bucket - 6) * 22
    }
    private var duration: Double {
        1.8 + Double(seed % 8) * 0.18
    }
    private var delay: Double {
        Double(seed % 6) * 0.25
    }

    var body: some View {
        Group {
            if isCircle {
                Circle().fill(color).frame(width: size, height: size)
            } else {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(color)
                    .frame(width: size, height: size * 1.2)
            }
        }
        .rotationEffect(.degrees(rotate))
        .offset(x: startX, y: y)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: duration).repeatForever(autoreverses: false)) {
                    y = 140
                    rotate = 540
                }
            }
        }
    }
}

// MARK: - 본문

private struct ItemBody: View {
    let titleEN: String
    let titleKO: String
    let message: String

    var body: some View {
        VStack(spacing: 6) {
            Text(titleEN)
                .font(.duoDisplay(size: 18))
                .foregroundColor(.duoEel2)
                .multilineTextAlignment(.center)

            if !titleKO.isEmpty {
                Text(titleKO)
                    .font(.duoDisplay(size: 13))
                    .foregroundColor(.duoWolf2)
                    .multilineTextAlignment(.center)
            }

            Text(message)
                .font(.duoBody(size: 12))
                .foregroundColor(.duoWolf2)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 4)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 4)
    }
}

// MARK: - shimmer 가 있는 캔디 버튼

private struct ShimmerCandyButton: View {
    let titleEN: String
    let titleKO: String
    let tint: Color
    let deep: Color
    let reduceMotion: Bool
    let action: () -> Void

    @State private var pressed = false
    @State private var shimmerX: CGFloat = -1.4

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Text("\(titleKO) · \(titleEN)")
                    .font(.duoDisplay(size: 16))
                    .kerning(0.04 * 16)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: DuoRadius.lg).fill(tint)
                    )
                    .overlay(
                        // shimmer — 흰 사선 그라데이션, mask 로 버튼 영역에만 표시
                        GeometryReader { geo in
                            let w = geo.size.width
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.55), .clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                            .frame(width: w * 0.55)
                            .offset(x: w * shimmerX)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: DuoRadius.lg))
                        .allowsHitTesting(false)
                    )
                    .offset(y: pressed ? 4 : 0)
                    .background(
                        RoundedRectangle(cornerRadius: DuoRadius.lg)
                            .fill(deep)
                            .frame(height: pressed ? 48 : 52)
                    )
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
        .animation(.easeOut(duration: 0.08), value: pressed)
        .onAppear {
            guard !reduceMotion else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: false)) {
                    shimmerX = 1.6
                }
            }
        }
    }
}

// MARK: - 아이템 tint 유도 + 한글 부제

private enum ItemTintResolver {
    /// itemIconName 의 마지막 `i_` 토큰을 보고 컬러를 매핑.
    /// (alert 모델에 itemType 이 안 실려와도 동작.)
    static func tint(for iconName: String) -> Color {
        switch token(from: iconName) {
        case "start", "timeoutstart":           return .duoMacaw
        case "end", "timeoutend", "solution":   return .duoGreen500
        case "simple":                          return .duoBee
        case "quiz", "quiz20", "mine":          return .duoCardinal
        case "random", "coupon":                return .duoBeetle
        case "radarar", "radarmap", "radarall",
             "radarmine", "radarblack":         return .duoMacaw
        default:                                return .duoFox
        }
    }

    static func tintDeep(for iconName: String) -> Color {
        switch token(from: iconName) {
        case "start", "timeoutstart":           return Color(hex: 0x0084C2)
        case "end", "timeoutend", "solution":   return .duoGreen700
        case "simple":                          return .duoBeeDeep
        case "quiz", "quiz20", "mine":          return Color(hex: 0xD33333)
        case "random", "coupon":                return .duoBeetleDeep
        default:                                return .duoFoxDeep
        }
    }

    /// "Items/i_start" → "start"
    private static func token(from iconName: String) -> String {
        guard let last = iconName.split(separator: "/").last else { return "" }
        let stripped = last.hasPrefix("i_") ? String(last.dropFirst(2)) : String(last)
        return stripped.lowercased()
    }

    /// alert.message 에 한글 부제가 없을 때 보조로 쓰는 매핑.
    static func koreanTitle(for iconName: String) -> String {
        switch token(from: iconName) {
        case "start":         return "시작 아이템 획득!"
        case "end":           return "도착 아이템 획득!"
        case "simple":        return "힌트 아이템 획득!"
        case "quiz", "quiz20":return "퀴즈 아이템 획득!"
        case "timeoutstart":  return "런 스타트 획득!"
        case "timeoutend":    return "런 엔드 획득!"
        case "solution":      return "솔루션 아이템 획득!"
        case "radarar":       return "스텔스 레이더 획득!"
        case "radarmap":      return "맵 레이더 획득!"
        case "radarmine":     return "지뢰 레이더 획득!"
        case "radarall":      return "올 레이더 획득!"
        case "random":        return "갬블링 아이템 획득!"
        case "mine":          return "지뢰 아이템 획득!"
        case "coupon":        return "쿠폰 아이템 획득!"
        default:              return "아이템 획득!"
        }
    }
}

#if DEBUG
#Preview("Start") {
    ZStack {
        Color.duoEel2.ignoresSafeArea()
        ItemAcquiredPopup(
            alert: ItemAcquiredAlert(
                title: "Start Item acquired!",
                message: "If you touch OK, the item will be released Mission.\n확인을 누르면 미션이 시작됩니다.",
                itemIconName: "Items/i_start"
            ),
            onOK: {}
        )
    }
}

#Preview("Hint") {
    ZStack {
        Color.duoEel2.ignoresSafeArea()
        ItemAcquiredPopup(
            alert: ItemAcquiredAlert(
                title: "Hint acquired!",
                message: "You can now see a hint about this mission.\n미션에 대한 힌트를 확인할 수 있어요.",
                itemIconName: "Items/i_simple"
            ),
            onOK: {}
        )
    }
}

#Preview("Quiz") {
    ZStack {
        Color.duoEel2.ignoresSafeArea()
        ItemAcquiredPopup(
            alert: ItemAcquiredAlert(
                title: "Quiz acquired!",
                message: "Solve the quiz to unlock the next clue.\n퀴즈를 풀고 다음 단서를 잠금 해제하세요.",
                itemIconName: "Items/i_quiz"
            ),
            onOK: {}
        )
    }
}

#Preview("End") {
    ZStack {
        Color.duoEel2.ignoresSafeArea()
        ItemAcquiredPopup(
            alert: ItemAcquiredAlert(
                title: "End Item acquired!",
                message: "Mission complete! Great job.\n미션 완료! 수고하셨어요.",
                itemIconName: "Items/i_end"
            ),
            onOK: {}
        )
    }
}
#endif
