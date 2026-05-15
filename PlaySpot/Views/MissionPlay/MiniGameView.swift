// Views/MissionPlay/MiniGameView.swift
import SwiftUI

/// 레거시 GamePlayAlert 포팅: 흔들면 progress가 차오르고 쉬면 떨어진다.
/// - 배경: 흑백 Play Spot 로고 + 손에 든 폰(SHAKE) 일러스트
/// - 위 레이어: 컬러 로고를 아래에서부터 progress 비율만큼 잘라서 표시 → "주황색이 차오르는" 효과
struct MiniGameView: View {
    let item: MissionItem
    let engine: GameEngine
    @Environment(\.dismiss) private var dismiss
    @State private var motionService = AppState.shared.motionService

    /// 0...100. 흔들면 += shakeGain, 매 tick마다 -1.
    @State private var progress: Double = 0
    @State private var isCompleted = false
    @State private var lastShakeFireTime: Date = .distantPast
    @State private var animationToggle = false
    @State private var elapsedSeconds: Int = 0

    /// 0.1초 tick. 레거시 GamePlayAlert.updateTime과 동일 주기.
    private let tickInterval: TimeInterval = 0.1
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    /// 한 번의 shake로 더해지는 양. 레거시 level 5~8 + 체감 난이도 완화로 상향.
    private let shakeGain: Double = 15
    /// shake 입력 디바운스 (연속 가속도에 중복 카운트 방지)
    private let shakeCooldown: TimeInterval = 0.12
    /// 매 tick(0.1초)마다 감소량. 레거시 -1을 -0.4로 완화.
    private let decayPerTick: Double = 0.4

    private var isShakeMode: Bool { item.itemGame == 1 }

    var body: some View {
        ZStack {
            // 검은 배경 (레거시 GamePlayAlert는 시스템 알럿 위에 떠서 dimmed 배경)
            Color.black.ignoresSafeArea()

            // 중앙 게임 영역
            GeometryReader { geo in
                let stageWidth = min(geo.size.width - 40, 320)
                let logoHeight = stageWidth * 0.95
                let shakeHeight = stageWidth * 0.95

                VStack(spacing: 0) {
                    Spacer(minLength: 24)
                    ZStack {
                        // Play Spot 로고: 흑백(기본) + 컬러(아래에서 progress만큼 노출)
                        logoStack(width: stageWidth, height: logoHeight)

                        // 손에 든 폰(SHAKE) — 진행도가 100에 가까울수록 페이드 아웃 (레거시 modeView.alpha)
                        shakeIllustration(width: shakeHeight, height: shakeHeight)
                            .opacity(shakeOverlayOpacity)
                    }
                    .frame(width: stageWidth, height: logoHeight)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }

            // 상단 크롬: 닫기 + 플립 카운터
            VStack {
                topChrome
                Spacer()
                bottomBar
            }

            // 미니게임 성공 → 힌트 공개 오버레이 (레거시: 시스템 알럿으로 success_message 표시)
            if isCompleted {
                hintRevealOverlay
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
            // 레거시: type 0(터치 모드)일 때만 탭으로 진행. shake 모드면 무시.
            if !isShakeMode { registerShake() }
        }
    }

    /// 미니게임 성공 후 힌트(item.info) 공개. 사용자가 확인 누르면 화면 닫힘.
    private var hintRevealOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Hint")
                    .font(.title2.bold())
                    .foregroundColor(.orange)
                Text(hintText)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                Button {
                    dismiss()
                } label: {
                    Text("OK")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(white: 0.12))
            )
            .padding(.horizontal, 32)
        }
    }

    private var hintText: String {
        let trimmed = item.info.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "(이 힌트는 비어 있습니다)" : trimmed
    }

    // MARK: - 시각 컴포넌트

    private func logoStack(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            // 흑백 로고 (basicImg)
            Image("Game/logo_noshadow_black")
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)

            // 컬러 로고를 아래에서 progress 비율만큼만 노출.
            // 레거시: croppedVerticalImage로 잘라 setFrame. SwiftUI에선 mask로 동일 효과.
            Image("Game/logo_noshadow")
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
                .mask(alignment: .bottom) {
                    Rectangle()
                        .frame(width: width, height: height * fillRatio)
                }
                .animation(.easeOut(duration: 0.15), value: progress)
        }
    }

    private func shakeIllustration(width: CGFloat, height: CGFloat) -> some View {
        // 레거시: 0.3초마다 game_shake / game_shake1 토글
        let asset = animationToggle ? "Game/game_shake1" : "Game/game_shake"
        return Image(asset)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
    }

    private var topChrome: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "map.fill")
                        .foregroundColor(.white)
                    Text("Map")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer()

            flipCounter
                .padding(.trailing, 60) // 시각적 좌우 균형
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
    }

    private var flipCounter: some View {
        HStack(spacing: 2) {
            ForEach(Array(timeString.enumerated()), id: \.offset) { _, ch in
                Text(String(ch))
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.black)
                            .overlay(
                                Rectangle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(height: 1)
                            )
                    )
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            Text(isShakeMode ? "흔드세요!" : "탭하세요!")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 2)
            Spacer()
            Text("\(Int(progress)) / 100")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.55))
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: - 로직

    private func registerShake() {
        guard !isCompleted else { return }
        let now = Date()
        guard now.timeIntervalSince(lastShakeFireTime) >= shakeCooldown else { return }
        lastShakeFireTime = now
        progress = min(progress + shakeGain, 100)
        SoundService.shared.play(.gameTouch)
        // 같은 tick 안에서 decay가 먼저 일어나면 99.x로 깎여 완료가 영원히 안 되는 문제 방지 →
        // shake 직후에 곧바로 완료 판정한다.
        checkCompletion()
    }

    private func tick() {
        elapsedSeconds += 1
        // 레거시: timeCount-- 매 tick. 체감 완화를 위해 decayPerTick(<1) 만큼 감소.
        if !isCompleted, progress > 0 {
            progress = max(progress - decayPerTick, 0)
        }
        // 흔들 일러스트 토글 (레거시는 매 3 tick마다)
        if elapsedSeconds % 3 == 0 {
            animationToggle.toggle()
        }
    }

    private func checkCompletion() {
        guard !isCompleted, progress >= 100 else { return }
        isCompleted = true
        HapticService.shared.success()
        SoundService.shared.play(.gameFinish)
        try? engine.acquireItem(item)
    }

    private var fillRatio: CGFloat { CGFloat(progress / 100) }

    /// 진행도가 80을 넘으면 손-폰 일러스트가 페이드 아웃 (레거시: timeCount < 20일 때만 보임의 반대 — progress가 차오를수록 가려진다)
    private var shakeOverlayOpacity: Double {
        let remaining = 100 - progress
        if remaining > 20 { return 1.0 }
        return max(0.0, remaining / 20.0)
    }

    /// 경과 시간(0.1초 tick 기준)을 6자리 HHMMSS 형식으로.
    private var timeString: String {
        let secs = elapsedSeconds / 10
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        return String(format: "%02d%02d%02d", h, m, s)
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
