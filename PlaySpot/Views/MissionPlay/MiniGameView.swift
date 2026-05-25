// Views/MissionPlay/MiniGameView.swift
// Phase 4 — Candy 디자인.
// 외곽선 PLAY SPOT 워드마크 (progress 0→100 에 따라 brightness/saturate/glow 증가)
//   + shake_0/1 or touch_0/1 일러스트 토글
//   + SparkleBurst (tap 마다 진행도 + 파티클)
//   + Hint reveal overlay (성공 시).
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

            // 워드마크 + 손-폰 일러스트 + 파티클
            stage
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 상단 + 하단 HUD
            VStack {
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
        ZStack {
            // 외곽선 워드마크 — progress 에 따라 점등.
            WordmarkPlaySpot(progress: progress / 100, variant: .outline)
                .frame(maxWidth: 280, maxHeight: 200)
                .padding(.top, 80)

            // 글로우 halo (progress 50% 이상)
            if progress > 50 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.duoBee.opacity(0.35), .clear],
                            center: .center, startRadius: 20, endRadius: 160
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blendMode(.screen)
            }

            // 손-폰 일러스트 (shake/touch × 0/1 토글)
            let asset = isShakeMode
                ? "Minigame/\(animationToggle ? "shake_1" : "shake_0")"
                : "Minigame/\(animationToggle ? "touch_1" : "touch_0")"
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(isShakeMode ? (animationToggle ? 6 : -6) : 0))
                .offset(y: 40)
                .opacity(shakeOverlayOpacity)
                .animation(.easeInOut(duration: 0.18), value: animationToggle)

            // Sparkle burst — registerShake 마다 트리거
            SparkleBurst(trigger: sparkleTrigger, radius: 140)
                .offset(y: 40)
        }
    }

    // MARK: - HUD

    private var topHUD: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "map.fill")
                    Text("MAP")
                        .font(.duoDisplay(size: 13))
                        .kerning(0.6)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10).fill(Color.hudDarkEnd)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                )
            }

            Spacer()

            DigitClock(seconds: elapsedSeconds / 10, style: .dark,
                       digitFontSize: 16, digitWidth: 16, digitHeight: 26)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var bottomHUD: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(isShakeMode ? "흔드세요!" : "터치하세요!")
                    .font(.duoDisplay(size: 14))
                    .foregroundColor(.white)
                Text(isShakeMode ? "Shake!" : "Tap!")
                    .font(.duoBody(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            HStack(spacing: 2) {
                Text("\(Int(progress))")
                    .font(.duoDisplay(size: 18))
                    .foregroundColor(.duoBee)
                Text("/ 100")
                    .font(.duoDisplay(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(LinearGradient.hudDark)
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
