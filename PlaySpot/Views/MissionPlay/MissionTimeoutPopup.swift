// Views/MissionPlay/MissionTimeoutPopup.swift
// Phase 4 — Candy 모달. 빨간 타이머 아이콘 + 안내 + 확인 CandyButton.
import SwiftUI

struct MissionTimeoutPopup: View {
    let elapsedText: String
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.duoCardinalBg)
                        .frame(width: 80, height: 80)
                    Image(systemName: "timer")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.duoCardinal)
                }

                Text("시간 초과")
                    .font(.duoDisplay(size: 24))
                    .foregroundColor(.duoEel2)

                Text("제한 시간이 지나 미션이 종료되었습니다.")
                    .font(.duoBody(size: 14))
                    .foregroundColor(.duoWolf2)
                    .multilineTextAlignment(.center)

                HStack(spacing: 6) {
                    Image(systemName: "stopwatch.fill")
                        .foregroundColor(.duoFox)
                    Text("플레이 시간 \(elapsedText)")
                        .font(.duoBody(size: 13, weight: .semibold))
                        .foregroundColor(.duoWolf2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.duoSnow))

                Button("확인 · OK", action: onConfirm)
                    .buttonStyle(.red)
                    .padding(.top, 4)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 18).fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18).stroke(Color.duoSwan2, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 8)
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
