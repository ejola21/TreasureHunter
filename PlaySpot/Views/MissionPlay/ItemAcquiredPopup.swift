// Views/MissionPlay/ItemAcquiredPopup.swift
// Phase 4 — Candy 디자인. 컬러 워드마크 + 아이콘 + 본문 + OK CandyButton.
// 시그니처는 기존 (alert: ItemAcquiredAlert, onOK: () -> Void) 유지.
// 디자인: README §"Item Acquired Popup" / screens-v2.jsx ItemAcquiredPopup
import SwiftUI

struct ItemAcquiredPopup: View {
    let alert: ItemAcquiredAlert
    let onOK: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 12) {
                Image("Minigame/playspot_logo_color")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 56)

                // 기존 alert.itemIconName 은 namespace 포함된 imageset 명 (e.g. "Items/i_start").
                Image(alert.itemIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 67)

                Text(alert.title)
                    .font(.duoDisplay(size: 22))
                    .foregroundColor(.duoEel2)
                    .multilineTextAlignment(.center)

                Text(alert.message)
                    .font(.duoBody(size: 13))
                    .foregroundColor(.duoWolf2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("확인 · OK", action: onOK)
                    .buttonStyle(.orange)
                    .padding(.top, 8)
            }
            .padding(20)
            .frame(maxWidth: 280)
            .background(
                RoundedRectangle(cornerRadius: 18).fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18).stroke(Color.duoSwan2, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 30, x: 0, y: 8)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.92)))
    }
}

#if DEBUG
#Preview("ItemAcquired") {
    ZStack {
        Color.duoEel2.ignoresSafeArea()
        ItemAcquiredPopup(
            alert: ItemAcquiredAlert(
                title: "Start!",
                message: "미션이 시작되었어요. 첫 번째 아이템을 찾아보세요!",
                itemIconName: "Items/i_start"
            ),
            onOK: {}
        )
    }
}
#endif
