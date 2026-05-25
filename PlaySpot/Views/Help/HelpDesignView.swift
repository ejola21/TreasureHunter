// Views/Help/HelpDesignView.swift — Mission Design 5-step 가이드
// 디자인: README §16 / screens-tutorial.jsx ScreenDesignGuide
// purple hero + 5 DesignStep (numbered circle + title/body + 미니 visual icon) + purple CandyButton CTA.

import SwiftUI

private struct DesignStep: Identifiable {
    let id: Int
    let title: String
    let body: String
    let icon: String
    let tint: Color
}

struct HelpDesignView: View {
    var onStartDesign: () -> Void

    private static let steps: [DesignStep] = [
        DesignStep(id: 1, title: "지도에 아이템 배치",
                   body: "지도를 길게 눌러 시작/끝/퀴즈/지뢰 등 아이템을 놓아보세요.",
                   icon: "map.fill", tint: .duoGreen500),
        DesignStep(id: 2, title: "아이템 탭해서 설정",
                   body: "필수 여부·발견 거리·표시 방식(숨김/Stealth) 등을 조정.",
                   icon: "slider.horizontal.3", tint: .duoMacaw),
        DesignStep(id: 3, title: "미션 메타 정보 입력",
                   body: "제목·장소·설명·시간 제한·뱃지 이미지를 채워주세요.",
                   icon: "doc.text.fill", tint: .duoFox),
        DesignStep(id: 4, title: "테스트 플레이",
                   body: "내 디자인 목록에서 ‘테스트’ 버튼으로 직접 플레이해보세요.",
                   icon: "play.fill", tint: .duoBeetle),
        DesignStep(id: 5, title: "업로드 — 신중하게!",
                   body: "공개 후 직접 삭제는 불가. 먼저 ‘공개 해제’ 후에만 삭제할 수 있어요.",
                   icon: "exclamationmark.triangle.fill", tint: .duoCardinal)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            heroCard

            VStack(spacing: 12) {
                ForEach(Self.steps) { step in
                    stepRow(step)
                }
            }

            Button(action: onStartDesign) {
                HStack {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .bold))
                    Text("미션 만들기 시작!")
                        .font(.duoDisplay(size: 14))
                        .kerning(0.84)
                        .textCase(.uppercase)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.duoBeetle))
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.duoBeetleDeep)
                        .offset(y: 4)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var heroCard: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                DuoKicker(text: "Create a Mission · 나만의 미션 만들기",
                          color: .duoBeetleDeep)
                Text("Mission Designer")
                    .font(.duoDisplay(size: 22))
                    .foregroundColor(.duoEel2)
                Text("당신만의 위치 기반 미션을 만들어 친구들과 공유해 보세요!")
                    .font(.duoBody(size: 13))
                    .foregroundColor(.duoWolf2)
            }
            Spacer()
            FoxMascot(pose: .think, size: 64)
        }
        .padding(16)
        .background(
            LinearGradient(colors: [Color(hex: 0xEED4FF), .white],
                           startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.duoBeetle.opacity(0.5), lineWidth: 2))
    }

    private func stepRow(_ step: DesignStep) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(step.tint)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .overlay(Circle().stroke(step.tint.opacity(0.6), lineWidth: 1))
                Text("\(step.id)")
                    .font(.duoDisplay(size: 16))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.duoDisplay(size: 14))
                    .foregroundColor(.duoEel2)
                Text(step.body)
                    .font(.duoBody(size: 12))
                    .foregroundColor(.duoWolf2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(step.tint.opacity(0.18))
                    .frame(width: 64, height: 64)
                Image(systemName: step.icon)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(step.tint)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.duoSwan2, lineWidth: 2))
    }
}

#if DEBUG
#Preview("HelpDesign") {
    ScrollView { HelpDesignView { print("start design") } }
        .background(Color.duoSnow)
}
#endif
