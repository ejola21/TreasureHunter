// Views/MissionPlay/HintPopup.swift
// Phase 4 — AR 화면 위에 뜨는 힌트 획득 모달.
// 디자인: README §5 Hint Acquired Popup
import SwiftUI

struct HintPopup: View {
    let hintText: String
    var rewardXP: Int = 15
    var rewardGems: Int = 1
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            // 어두운 배경 (AR view 가 뒤에 있다면 그대로 보이게)
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                // 좌상단 핀 오버랩
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        DuoKicker(text: "Item Acquired · 아이템 획득", color: .duoMacaw)

                        Text("Hint!")
                            .font(.duoDisplay(size: 30))
                            .foregroundColor(.duoEel2)

                        Text(hintText)
                            .font(.duoBody(size: 14))
                            .foregroundColor(.duoWolf2)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)

                        HStack(spacing: 8) {
                            rewardChip(systemImage: "bolt.fill", value: "+\(rewardXP) XP", tint: .duoBee)
                            rewardChip(systemImage: "diamond.fill", value: "+\(rewardGems) Gem", tint: .duoBeetle)
                        }
                        .padding(.top, 6)

                        Button("확인 · OK", action: onConfirm)
                            .buttonStyle(.primary)
                            .padding(.top, 8)
                    }
                    .padding(20)
                    .padding(.top, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18).fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18).stroke(Color.duoSwan2, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 8)

                    // 좌상단 오버랩 핀
                    ItemPin(.simple, size: 58, active: true, glow: true)
                        .offset(x: -14, y: -22)
                }
            }
            .frame(maxWidth: 320)
            .padding(.horizontal, 20)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private func rewardChip(systemImage: String, value: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(tint)
            Text(value)
                .font(.duoDisplay(size: 12))
                .foregroundColor(.duoEel)
        }
        .padding(.horizontal, 10)
        .frame(height: 26)
        .background(Capsule().fill(Color.white))
        .overlay(Capsule().stroke(Color.duoSwan2, lineWidth: 1.5))
    }
}

#if DEBUG
#Preview("HintPopup") {
    ZStack {
        LinearGradient(
            colors: [Color.duoFox, Color.duoCardinal],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ).ignoresSafeArea()

        HintPopup(
            hintText: "다음 단서는 큰 나무 옆 벤치에 숨겨져 있어요. 한 번 둘러보세요!",
            onConfirm: {}
        )
    }
}
#endif
