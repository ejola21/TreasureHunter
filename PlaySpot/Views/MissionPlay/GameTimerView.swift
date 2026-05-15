// Views/MissionPlay/GameTimerView.swift
import SwiftUI

struct GameTimerView: View {
    let elapsedTime: TimeInterval
    let isTimeOutActive: Bool
    let remainingRunTime: TimeInterval

    var body: some View {
        HStack(spacing: 0) {
            if isTimeOutActive {
                // 타임아웃 카운트다운
                Image(systemName: "timer")
                    .foregroundColor(.red)
                    .padding(.trailing, 4)
                timerDigits(TimerFormatter.format(remainingRunTime))
                    .foregroundColor(remainingRunTime < 10 ? .red : .white)
            } else {
                // 경과 시간
                Image(systemName: "clock")
                    .foregroundColor(.white)
                    .padding(.trailing, 4)
                timerDigits(TimerFormatter.format(elapsedTime))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.top, 8)
    }

    private func timerDigits(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .bold, design: .monospaced))
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.3), value: text)
    }
}

#if DEBUG
#Preview("GameTimer") {
    VStack(spacing: 12) {
        GameTimerView(elapsedTime: 5, isTimeOutActive: false, remainingRunTime: 0)
        GameTimerView(elapsedTime: 125, isTimeOutActive: false, remainingRunTime: 0)
        GameTimerView(elapsedTime: 0, isTimeOutActive: true, remainingRunTime: 8)
    }
    .padding()
    .background(Color.gray)
}
#endif
