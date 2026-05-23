// Views/MissionPlay/MissionTimeoutPopup.swift
import SwiftUI

/// 미션 제한 시간 초과 알림. 레거시 finishTimeAlert 대응.
/// MissionCompletePopup 과 동일 카드 스타일 — 시간 초과로 미션이 종료됐음을 알린다.
struct MissionTimeoutPopup: View {
    let elapsedText: String
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "timer")
                    .font(.system(size: 48))
                    .foregroundColor(.red)

                Text("시간 초과")
                    .font(.title2.bold())

                Text("제한 시간이 지나 미션이 종료되었습니다.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("플레이 시간 \(elapsedText)")
                    .font(.callout.monospaced())
                    .foregroundColor(.secondary)

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
#Preview("MissionTimeout") {
    MissionTimeoutPopup(elapsedText: "00:09:00") {}
}
#endif
