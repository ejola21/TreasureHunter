// Views/MissionPlay/MiniGameView.swift
// 디자인 핸드오프 — AR-Touch / AR-Found mockup 매칭.
// 상단: 녹색 candy MAP 버튼 + 흰 pill 타이머 (가운데)
// 무대: PLAY SPOT 워드마크 + 손-폰 일러스트 (화면 꽉 차게) + SparkleBurst
// 하단: 라벨/진행도 + 흰 pill HUD 카드 (HINT · 떠있는 레이더 · 유효 반경)
// 게임 로직 (shakeGain / decay / completion) 은 보존.
import SwiftUI

struct MiniGameView: View {
    let item: MissionItem
    let engine: GameEngine
    @Environment(\.dismiss) private var dismiss
    @State private var motionService = AppState.shared.motionService

    @State private var progress: Double = 0
    @State private var isCompleted = false
    @State private var lastShakeFireTime: Date = .distantPast
    @State private var animationToggle = false
    @State private var elapsedSeconds: Int = 0
    @State private var sparkleTrigger: Int = 0

    private let tickInterval: TimeInterval = 0.1
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    private let shakeGain: Double = 15
    private let shakeCooldown: TimeInterval = 0.12
    private let decayPerTick: Double = 0.4

    private var isShakeMode: Bool { item.itemGame == 1 }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 워드마크 + 손-폰 일러스트 + 파티클 (화면 꽉 차게)
            stage
                .ignoresSafeArea()

            // 상단 + 하단 HUD
            VStack(spacing: 0) {
                topHUD
                Spacer()
                bottomHUD
            }

            // 미니게임 성공 → 힌트 공개 오버레이
            if isCompleted {
                hintRevealOverlay
                    .transition(.opacity)
            }
        }
        .statusBarHidden(true)
        .contentShape(Rectangle())
        .onAppear { motionService.startUpdates() }
        .onDisappear { motionService.stopUpdates() }
        .onChange(of: motionService.isShaking) { _, shaking in
            guard shaking, isShakeMode else { return }
            registerShake()
        }
        .onReceive(timer) { _ in tick() }
        .onTapGesture {
            #if targetEnvironment(simulator)
            registerShake()
            #else
            if !isShakeMode { registerShake() }
            #endif
        }
    }

    // MARK: - Stage (워드마크 + 일러스트 + 파티클 + 글로우)

    private var stage: some View {
        GeometryReader { geo in
            let illustrationSide = min(geo.size.width * 0.86, geo.size.height * 0.55)
            let wordmarkW = min(geo.size.width * 1.05, illustrationSide * 1.45)
            let sparkleR = illustrationSide * 0.85
            ZStack {
                // 외곽선 워드마크 — progress 에 따라 점등. 일러스트 뒤 큰 배경.
                WordmarkPlaySpot(progress: progress / 100, variant: .outline)
                    .frame(width: wordmarkW, height: wordmarkW * 0.75)

                // 글로우 halo (progress 50% 이상)
                if progress > 50 {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.duoBee.opacity(0.4), .clear],
                                center: .center, startRadius: 20, endRadius: sparkleR
                            )
                        )
                        .frame(width: sparkleR * 2, height: sparkleR * 2)
                        .blendMode(.screen)
                }

                // Sparkle burst — registerShake 마다 트리거
                SparkleBurst(trigger: sparkleTrigger, radius: sparkleR)

                // 손-폰 일러스트 (shake/touch × 0/1 토글) — 화면 꽉차게
                let asset = isShakeMode
                    ? "Minigame/\(animationToggle ? "shake_1" : "shake_0")"
                    : "Minigame/\(animationToggle ? "touch_1" : "touch_0")"
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: illustrationSide, height: illustrationSide)
                    .rotationEffect(.degrees(isShakeMode ? (animationToggle ? 6 : -6) : 0))
                    .opacity(shakeOverlayOpacity)
                    .animation(.easeInOut(duration: 0.18), value: animationToggle)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - HUD

    private var topHUD: some View {
        ZStack {
            // 가운데 — 흰 pill 타이머
            WhitePillTimer(seconds: elapsedSeconds / 10)

            // 좌측 — MAP 버튼 (candy 녹색)
            HStack {
                CandyIconButton(
                    systemImage: "map.fill",
                    size: 44,
                    tint: .duoGreen500,
                    fg: .white,
                    shadowColor: .duoGreen700
                ) {
                    dismiss()
                }
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 36)
    }

    private var bottomHUD: some View {
        VStack(spacing: 14) {
            // 라벨 + 진행도 (검정 배경 위)
            HStack(alignment: .firstTextBaseline) {
                Text(isShakeMode ? "흔드세요!" : "터치하세요!")
                    .font(.duoDisplay(size: 22))
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 6) {
                    Text("\(Int(progress))")
                        .font(.duoDisplay(size: 26))
                        .foregroundColor(.duoBee)
                    Text("/ 100")
                        .font(.duoDisplay(size: 22))
                        .foregroundColor(.duoSwan.opacity(0.55))
                }
            }
            .padding(.horizontal, 22)

            // 떠있는 레이더 + 흰 pill HUD 카드
            RadarPillHUD(
                leftLabel: "HINT",  leftValue: "0m",
                rightLabel: "유효 반경", rightValue: "100m"
            ) {
                ARRadar(size: 76)
            }
            .padding(.horizontal, 14)
        }
        .padding(.bottom, 18)
    }

    // MARK: - Hint 공개

    private var hintRevealOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 14) {
                ItemPin(item.itemType, size: 56, active: true, glow: true)
                DuoKicker(text: "Hint Revealed", color: .duoBee)
                Text(hintText)
                    .font(.duoBody(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                Button("확인 · OK") { dismiss() }
                    .buttonStyle(.orange)
                    .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.duoEel2))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.15), lineWidth: 2))
            .shadow(color: Color.black.opacity(0.5), radius: 24, x: 0, y: 8)
        }
    }

    private var hintText: String {
        let trimmed = item.info.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "(이 힌트는 비어 있습니다)" : trimmed
    }

    // MARK: - 로직

    private func registerShake() {
        guard !isCompleted else { return }
        let now = Date()
        guard now.timeIntervalSince(lastShakeFireTime) >= shakeCooldown else { return }
        lastShakeFireTime = now
        progress = min(progress + shakeGain, 100)
        sparkleTrigger += 1
        SoundService.shared.play(.gameTouch)
        checkCompletion()
    }

    private func tick() {
        elapsedSeconds += 1
        if !isCompleted, progress > 0 {
            progress = max(progress - decayPerTick, 0)
        }
        if elapsedSeconds % 3 == 0 {
            animationToggle.toggle()
        }
    }

    private func checkCompletion() {
        guard !isCompleted, progress >= 100 else { return }
        withAnimation { isCompleted = true }
        HapticService.shared.success()
        SoundService.shared.play(.gameFinish)
        try? engine.acquireItem(item)
    }

    private var shakeOverlayOpacity: Double {
        let remaining = 100 - progress
        if remaining > 20 { return 1.0 }
        return max(0.0, remaining / 20.0)
    }
}

#if DEBUG
#Preview("MiniGame - Shake") {
    var item = MissionItem.preview
    item.itemType = .simple
    item.itemGame = 1
    return MiniGameView(item: item, engine: GameEngine())
}

#Preview("MiniGame - Touch") {
    var item = MissionItem.preview
    item.itemType = .simple
    item.itemGame = 2
    return MiniGameView(item: item, engine: GameEngine())
}
#endif
