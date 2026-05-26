// Views/DesignSystem/HUDComponents.swift
// Map Play / AR Searching 상단·하단에서 공유되는 candy HUD 컴포넌트.
// - WhitePillTimer: 흰 캡슐 + 주황 시계 + monospace 디지트
// - CandyIconButton: 42×42 정사각 candy 아이콘 버튼 (Locate/Info/MAP)
// - CandyExitButton: 빨간 EXIT candy 버튼 (40 높이, 라운드 12)
// - StatChip: 라이트 틴트 + 1.5px 보더 chip (지형/필수/HIDDEN/STEALTH)
import SwiftUI

// MARK: - 흰 pill 타이머

struct WhitePillTimer: View {
    /// 총 초.
    let seconds: Int
    /// Run Start 활성 중 → 디지트를 빨간색.
    var isRunActive: Bool = false

    private var formatted: String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return String(format: "%02d:%02d:%02d", h, m, sec)
    }

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(Color.duoFoxBg)
                    .frame(width: 28, height: 28)
                Image(systemName: "clock.fill")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.duoFox)
            }
            Text(formatted)
                .font(.duoDisplay(size: 20))
                .foregroundColor(isRunActive ? .duoCardinal : .duoEel2)
                .monospacedDigit()
                .padding(.trailing, 4)
        }
        .padding(.leading, 6)
        .padding(.trailing, 12)
        .frame(height: 40)
        .background(Capsule().fill(Color.white))
        .overlay(Capsule().stroke(Color.duoSwan2, lineWidth: 1.5))
    }
}

// MARK: - 42×42 candy 아이콘 버튼

struct CandyIconButton: View {
    let systemImage: String
    var size: CGFloat = 42
    var tint: Color = .white
    var fg: Color = .duoEel2
    var shadowColor: Color = .duoSwan2
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .heavy))
                .foregroundColor(fg)
                .frame(width: size, height: size)
                .background(RoundedRectangle(cornerRadius: 12).fill(tint))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(shadowColor)
                        .offset(y: 4)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 빨간 EXIT candy 버튼

struct CandyExitButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("EXIT")
                .font(.duoDisplay(size: 14))
                .kerning(0.66)
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 40)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.duoCardinal))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: 0xD33333))
                        .offset(y: 4)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 라이트 틴트 chip (지형/필수/HIDDEN/STEALTH)

struct StatChip: View {
    enum Style {
        case blue, orange, neutral, purple

        var bg: Color {
            switch self {
            case .blue:    return .duoMacawBg
            case .orange:  return .duoFoxBg
            case .neutral: return .white
            case .purple:  return Color(hex: 0xF1DCFF)
            }
        }
        var border: Color {
            switch self {
            case .blue:    return .duoMacaw
            case .orange:  return .duoFox
            case .neutral: return .duoSwan
            case .purple:  return .duoBeetle
            }
        }
        var labelColor: Color {
            switch self {
            case .blue:    return .duoMacaw
            case .orange:  return .duoFox
            case .neutral: return .duoHare
            case .purple:  return .duoBeetle
            }
        }
        var valueColor: Color {
            switch self {
            case .blue:    return .duoMacawDeep
            case .orange:  return .duoFoxDeep
            case .neutral: return .duoEel2
            case .purple:  return .duoBeetleDeep
            }
        }
    }

    let label: String
    let value: Int
    var style: Style = .neutral

    var body: some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.duoBody(size: 11, weight: .heavy))
                .foregroundColor(style.labelColor)
            Text(String(format: "%03d", value))
                .font(.duoDisplay(size: 20))
                .foregroundColor(style.valueColor)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(style.bg))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(style.border, lineWidth: 1.5))
    }
}

// MARK: - 흰 pill 하단 HUD (HINT · 떠있는 레이더 · 유효 반경)
// AR Searching / AR Play / 미니게임 공용.
// 좌: 파란 깃발 박스 + 라벨/값 — 우: 라벨/값 + 녹색 핀 박스 — 가운데: 떠있는 레이더.

struct RadarPillHUD<Radar: View>: View {
    let leftLabel: String
    let leftValue: String
    var leftValueColor: Color = .duoFox

    let rightLabel: String
    let rightValue: String
    var rightValueColor: Color = .duoGreen500

    @ViewBuilder var radar: () -> Radar

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // 좌 — 파란 깃발 박스 + 라벨/값
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color.duoMacawBg)
                            .frame(width: 38, height: 38)
                            .overlay(
                                RoundedRectangle(cornerRadius: 9)
                                    .stroke(Color.duoMacawBorder, lineWidth: 1.5)
                            )
                        Image(systemName: "flag.fill")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.duoMacaw)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(leftLabel)
                            .font(.duoBody(size: 11, weight: .heavy))
                            .foregroundColor(.duoHare)
                            .lineLimit(1)
                        Text(leftValue)
                            .font(.duoDisplay(size: 20))
                            .foregroundColor(leftValueColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer().frame(width: 72)

                // 우 — 라벨/값 + 녹색 핀 박스
                HStack(spacing: 10) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(rightLabel)
                            .font(.duoBody(size: 11, weight: .heavy))
                            .foregroundColor(.duoHare)
                            .lineLimit(1)
                        Text(rightValue)
                            .font(.duoDisplay(size: 20))
                            .foregroundColor(rightValueColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color.duoGreen500)
                            .frame(width: 38, height: 38)
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
            )

            // 가운데 — 떠있는 레이더 (살짝 위로). 레이더 자체에 흰 외곽 stroke 가 있으므로
            // 별도 흰 halo 없이 그림자만 적용 (미니게임/AR Play 통일).
            radar()
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
                .offset(y: -8)
        }
    }
}

#if DEBUG
#Preview("HUDComponents") {
    VStack(spacing: 16) {
        HStack(spacing: 8) {
            CandyExitButton {}
            WhitePillTimer(seconds: 5)
            CandyIconButton(systemImage: "scope") {}
            CandyIconButton(
                systemImage: "info",
                tint: .duoMacaw,
                fg: .white,
                shadowColor: Color(hex: 0x1899D6)
            ) {}
        }
        .padding()

        HStack(spacing: 6) {
            StatChip(label: "지형", value: 1, style: .blue)
            StatChip(label: "필수", value: 4, style: .orange)
            Spacer().frame(width: 70)
            StatChip(label: "HIDDEN", value: 1, style: .neutral)
            StatChip(label: "STEALTH", value: 0, style: .purple)
        }
        .padding()
        .background(Color.white)
    }
    .background(Color.duoSnow)
}
#endif
