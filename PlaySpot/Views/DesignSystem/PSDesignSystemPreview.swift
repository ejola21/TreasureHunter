// Views/DesignSystem/PSDesignSystemPreview.swift
// Phase 1 디자인 시스템 카탈로그 — 모든 컴포넌트를 한 화면에 모아 시뮬에서 한번에 검증.
// 본 화면은 프로덕션 진입점이 아님 — 개발 시 #Preview 또는 임시 라우팅으로 확인.

import SwiftUI

struct PSDesignSystemPreview: View {
    @State private var toggleOn = true
    @State private var toggleOff = false
    @State private var stepperVal = 45
    @State private var seg: SegTab = .popular
    @State private var backend = "REST"
    @State private var tab: MainTab = .missions
    @State private var minigameProgress: Double = 0.3

    enum SegTab: String, Identifiable, CaseIterable {
        case popular, new, near
        var id: String { rawValue }
        var label: String {
            switch self {
            case .popular: return "Popular"
            case .new:     return "New"
            case .near:    return "Near Me"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    title("Typography")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PlaySpot").font(.duoDisplay(size: 36)).foregroundColor(.duoEel2)
                        Text("미션 편집 · Mission Edit").font(.duoDisplay(size: 22)).foregroundColor(.duoEel)
                        DuoKicker(text: "Section 1, Unit 1")
                        Text("Body 14 · 한글 본문").font(.duoBody(size: 14)).foregroundColor(.duoWolf2)
                    }

                    title("Candy Buttons")
                    VStack(spacing: 10) {
                        Button("Mission Start!") {}.buttonStyle(.primary)
                        HStack(spacing: 10) {
                            Button("Info") {}.buttonStyle(.blue)
                            Button("Exit") {}.buttonStyle(.red)
                        }
                        HStack(spacing: 10) {
                            Button("XP") {}.buttonStyle(.orange)
                            Button("Quest") {}.buttonStyle(.purple)
                        }
                    }

                    title("Chips")
                    HStack(spacing: 6) {
                        DuoChip.green("12 plays")
                        DuoChip.red("2 fails")
                        DuoChip.orange("Beginner")
                        DuoChip.yellow("XP")
                        DuoChip.blue("INFO")
                        DuoChip.purple("Quest")
                    }

                    title("PSToggle")
                    HStack(spacing: 12) {
                        PSToggle(isOn: $toggleOn)
                        PSToggle(isOn: $toggleOff)
                        PSToggle(isOn: $toggleOn, tint: .duoFox, shadow: .duoFoxDeep)
                    }

                    title("DuoStepper")
                    HStack {
                        Text("발견 거리: \(stepperVal) m").font(.duoBody(size: 14))
                        Spacer()
                        DuoStepper(value: $stepperVal, range: 5...200, step: 5)
                    }

                    title("SegmentedTabs")
                    SegmentedTabs(
                        selection: $seg,
                        options: SegTab.allCases,
                        label: { $0.label }
                    )

                    title("SegBtnPair")
                    SegBtnPair(selection: $backend, options: [("Legacy", "Legacy"), ("REST", "REST")])

                    title("Card + FormGroup")
                    FormGroup(title: "ACCOUNT") {
                        FormRow(label: "User ID", value: "Guest@2026")
                        FormRow(label: "Login", link: true, isLast: true) {}
                    }

                    title("Fox Mascot")
                    HStack(spacing: 16) {
                        FoxMascot(pose: .wave, size: 48)
                        FoxMascot(pose: .sit, size: 48)
                        FoxMascot(pose: .think, size: 48)
                        FoxMascot(pose: .cheer, size: 48)
                    }

                    title("Item Pins")
                    HStack(spacing: 12) {
                        ItemPin(.start, size: 48)
                        ItemPin(.end, size: 48)
                        ItemPin(.mine, size: 48, active: true)
                        ItemPin(.quiz, size: 48, glow: true)
                        ItemPin(.simple, size: 48)
                    }

                    title("Digit Clock")
                    HStack(spacing: 16) {
                        DigitClock(seconds: 5)
                        DigitClock(seconds: 540, style: .dark).padding(6).background(Color.duoEel2)
                    }

                    title("Wordmark (interactive)")
                    VStack(spacing: 8) {
                        WordmarkPlaySpot(progress: minigameProgress)
                            .frame(height: 160)
                            .padding(.horizontal)
                            .background(Color.black)
                            .cornerRadius(12)
                        Slider(value: $minigameProgress, in: 0...1)
                    }

                    title("HUD Gradients")
                    VStack(spacing: 8) {
                        LinearGradient.hudTeal.frame(height: 56).cornerRadius(8)
                        LinearGradient.hudDark.frame(height: 56).cornerRadius(8)
                    }

                    title("AR Radar")
                    HStack(spacing: 16) {
                        ARRadar(size: 64, angle: 35)
                        ARRadar(size: 80, angle: 120, blip: CGPoint(x: 0.8, y: 0.2))
                        ARRadar(size: 48, angle: -30)
                    }
                    .padding()
                    .background(LinearGradient.hudTeal)
                    .cornerRadius(12)

                    title("Pulse Ring (player position)")
                    HStack(spacing: 60) {
                        ZStack {
                            PulseRing()
                            Circle().fill(Color.duoMacaw).frame(width: 24, height: 24)
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        }
                        ZStack {
                            PulseRing(color: .duoCardinal, size: 28, rings: 3)
                            Circle().fill(Color.duoCardinal).frame(width: 28, height: 28)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)

                    title("Sparkle Burst (tap to fire)")
                    SparkleBurstDemo()

                    Spacer(minLength: 40)
                }
                .padding(16)
            }
            .background(Color.duoSnow)

            BottomNav5(active: $tab)
        }
    }

    private func title(_ s: String) -> some View {
        Text(s).font(.duoDisplay(size: 14)).foregroundColor(.duoEel)
    }
}

private struct SparkleBurstDemo: View {
    @State private var trigger = 0
    var body: some View {
        ZStack {
            Color.black.frame(height: 220).cornerRadius(12)
            SparkleBurst(trigger: trigger, radius: 110)
            Button("BURST! (\(trigger))") { trigger += 1 }
                .buttonStyle(.orange)
                .frame(width: 180)
        }
    }
}

#if DEBUG
#Preview("Design System") {
    PSDesignSystemPreview()
}
#endif
