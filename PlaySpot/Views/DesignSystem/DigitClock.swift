// Views/DesignSystem/DigitClock.swift
// 디지트별 카드형 시계 — "00:00:05" 형식.
// 각 디지트는 흰 카드 (1.5px swan border) + display 폰트. 콜론은 별도 카드 없음.
// 디자인: README §"Map Play" 톱바, §"AR Search" 톱바

import SwiftUI

struct DigitClock: View {
    /// 전체 초. 60분(3600s) 초과해도 hh:mm:ss 로 렌더.
    let seconds: Int
    var style: Style = .light
    var digitFontSize: CGFloat = 18
    var digitWidth: CGFloat = 18
    var digitHeight: CGFloat = 28

    enum Style {
        case light    // 흰 카드 + 진한 텍스트 (in-game top HUD)
        case dark     // 어두운 카드 + 흰 텍스트 (AR HUD)

        var bg: Color  { self == .light ? .white         : Color(hex: 0x143036) }
        var fg: Color  { self == .light ? .duoEel2       : .white }
        var bd: Color  { self == .light ? .duoSwan2      : Color.white.opacity(0.18) }
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(formatted.enumerated()), id: \.offset) { _, ch in
                if ch == ":" {
                    Text(":")
                        .font(.duoDisplay(size: digitFontSize))
                        .foregroundColor(style.fg)
                        .frame(width: 8, height: digitHeight)
                } else {
                    Text(String(ch))
                        .font(.duoDisplay(size: digitFontSize))
                        .foregroundColor(style.fg)
                        .frame(width: digitWidth, height: digitHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 4).fill(style.bg)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4).stroke(style.bd, lineWidth: 1.5)
                        )
                }
            }
        }
    }

    private var formatted: String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return String(format: "%02d:%02d:%02d", h, m, sec)
    }
}

#if DEBUG
#Preview("DigitClock") {
    VStack(spacing: 12) {
        DigitClock(seconds: 5, style: .light)
        DigitClock(seconds: 5 * 60 + 23, style: .light)
        DigitClock(seconds: 1 * 3600 + 5 * 60 + 7, style: .light)
        DigitClock(seconds: 540, style: .dark, digitFontSize: 22, digitWidth: 22, digitHeight: 32)
            .padding()
            .background(Color.duoEel2)
    }
    .padding()
    .background(LinearGradient.hudTeal)
}
#endif
