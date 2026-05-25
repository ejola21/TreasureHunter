// Views/Help/TutorialView.swift — 3-step 인터랙티브 온보딩
// 디자인: README §17 / screens-meta.jsx ScreenTutorial
// SKIP + 3-dot progress + X close / step title / 미니 데모 / Fox + 말풍선 / BACK·NEXT / LET'S PLAY!
// 기존 TutorialPagerView (정적 PNG 슬라이드) 대체.

import SwiftUI

private struct TutorialStep {
    let kicker: String
    let title: String
    let body: String
    let pinKind: ItemType
    let pose: FoxPose
}

struct TutorialView: View {
    @State private var step: Int = 0
    @Environment(\.dismiss) private var dismiss

    private static let steps: [TutorialStep] = [
        TutorialStep(kicker: "STEP 1",
                     title: "지도에서 아이템 찾기",
                     body: "근처에 숨겨진 아이템 핀이 지도에 표시돼요. 가까이 다가가면 활성화!",
                     pinKind: .start, pose: .wave),
        TutorialStep(kicker: "STEP 2",
                     title: "AR로 흔들고 터치하기",
                     body: "거리 안에 들어가면 카메라를 켜고 화면을 흔들거나 탭해서 아이템을 획득해요.",
                     pinKind: .quiz, pose: .think),
        TutorialStep(kicker: "STEP 3",
                     title: "퀴즈 풀고 클리어!",
                     body: "필수 아이템을 모두 획득하면 미션 완료! 보상과 뱃지를 받아보세요.",
                     pinKind: .end, pose: .cheer)
    ]

    private var currentStep: TutorialStep { Self.steps[step] }
    private var isLast: Bool { step == Self.steps.count - 1 }
    private var isFirst: Bool { step == 0 }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 12)
            titleSection
            Spacer(minLength: 12)
            demoCard
            Spacer(minLength: 16)
            mascotBubble
            Spacer(minLength: 16)
            navButtons
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.duoSnow.ignoresSafeArea())
    }

    // MARK: - 상단 (SKIP / 3-dot progress / X)

    private var topBar: some View {
        HStack(spacing: 12) {
            Button("SKIP") { dismiss() }
                .font(.duoDisplay(size: 11))
                .kerning(0.66)
                .foregroundColor(.duoHare)

            Spacer()

            HStack(spacing: 6) {
                ForEach(0..<Self.steps.count, id: \.self) { i in
                    Capsule()
                        .fill(i == step ? Color.duoMacaw : Color.duoSwan)
                        .frame(width: i == step ? 22 : 8, height: 6)
                        .animation(.easeOut(duration: 0.18), value: step)
                }
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.duoHare)
                    .frame(width: 28, height: 28)
            }
        }
    }

    // MARK: - 타이틀

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            DuoKicker(text: currentStep.kicker, color: .duoFoxDeep)
            Text(currentStep.title)
                .font(.duoDisplay(size: 24))
                .foregroundColor(.duoEel2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 데모 카드 (펄스 핀 + 안내 손가락)

    private var demoCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: 0xE7EED4))
                .frame(maxWidth: .infinity)
                .frame(height: 220)

            VStack {
                Spacer()
                // 핀 + Pulse ring
                ZStack {
                    PulseRing(color: .duoBee, size: 28)
                    ItemPin(currentStep.pinKind, size: 56, active: true, glow: true)
                }
                Spacer()
            }

            VStack {
                HStack {
                    Spacer()
                    Image(systemName: step == 1 ? "hand.tap.fill" : "hand.point.up.fill")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(.duoFoxDeep)
                        .rotationEffect(.degrees(step == 1 ? 0 : -25))
                        .offset(x: -40, y: 30)
                }
                Spacer()
            }
        }
    }

    // MARK: - Fox + 말풍선

    private var mascotBubble: some View {
        HStack(alignment: .bottom, spacing: 10) {
            FoxMascot(pose: currentStep.pose, size: 56)
            Text(currentStep.body)
                .font(.duoBody(size: 13, weight: .semibold))
                .foregroundColor(.duoWolf2)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.duoSwan2, lineWidth: 2))
        }
    }

    // MARK: - 네비게이션 버튼 (BACK / NEXT 또는 LET'S PLAY!)

    private var navButtons: some View {
        HStack(spacing: 10) {
            if !isFirst {
                Button("BACK") {
                    withAnimation(.easeOut(duration: 0.18)) { step -= 1 }
                }
                .buttonStyle(CandyButtonStyle(tint: .white, shadowColor: .duoSwan2))
                .overlay(
                    Text("BACK")
                        .font(.duoDisplay(size: 14))
                        .kerning(0.84)
                        .textCase(.uppercase)
                        .foregroundColor(.duoWolf)
                )
                .frame(maxWidth: .infinity)
            }
            if isLast {
                Button("LET'S PLAY!") { dismiss() }
                    .buttonStyle(.primary)
                    .frame(maxWidth: .infinity)
            } else {
                Button("NEXT") {
                    withAnimation(.easeOut(duration: 0.18)) { step += 1 }
                }
                .buttonStyle(.blue)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#if DEBUG
#Preview("Tutorial") { TutorialView() }
#endif
