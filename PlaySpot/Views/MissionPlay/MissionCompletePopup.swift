// Views/MissionPlay/MissionCompletePopup.swift
import SwiftUI

/// 레거시 popup1 카드 스타일의 미션 완료 알림.
/// 스크린샷 참조: "PlaY SPoT" 로고 + 본문 + 주황 확인 버튼.
struct MissionCompletePopup: View {
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("Auth/loginbg_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 240, maxHeight: 80)

                Text("미션 완료!")
                    .font(.title2.bold())

                Text("축하합니다! 모든 필수 아이템을 수집했습니다.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: onConfirm) {
                    Text("확인")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            .padding(24)
            .background(
                Image("UI/popup1")
                    .resizable(capInsets: EdgeInsets(top: 30, leading: 30, bottom: 30, trailing: 30),
                              resizingMode: .stretch)
            )
            .frame(maxWidth: 320)
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }
}

#if DEBUG
#Preview("MissionComplete") {
    MissionCompletePopup {}
}
#endif
