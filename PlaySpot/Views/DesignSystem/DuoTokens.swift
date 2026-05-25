// Views/DesignSystem/DuoTokens.swift
// PlaySpot Duolingo-style design tokens.
// SOT: design_handoff_playspot_redesign/README.md §"Design Tokens"
//      + styles/tokens.css. 핸드오프 스타터 (swiftui_starter/DuoTokens.swift) 를
//        프로젝트로 이동하면서 plan_redesign.md §1.2 의 누락 토큰 13개를 추가했다.

import SwiftUI

// MARK: - Color hex helper

extension Color {
    init(hex: UInt32) {
        self.init(
            red:   Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8)  & 0xff) / 255,
            blue:  Double(hex         & 0xff) / 255
        )
    }
}

// MARK: - Colors

extension Color {
    // Brand greens (primary)
    static let duoGreen100 = Color(hex: 0xD7FFB8)
    static let duoGreen200 = Color(hex: 0xB7FF80)
    static let duoGreen300 = Color(hex: 0x93E85C)
    static let duoGreen400 = Color(hex: 0x8EE000)
    static let duoGreen500 = Color(hex: 0x58CC02)   // PRIMARY
    static let duoGreen550 = Color(hex: 0x5ACD05)
    static let duoGreen700 = Color(hex: 0x5AA703)   // primary button shadow
    static let duoGreen750 = Color(hex: 0x48A502)
    static let duoGreen800 = Color(hex: 0x43A601)
    static let duoGreen900 = Color(hex: 0x375B0A)

    // Macaw (blue) accent
    static let duoMacaw         = Color(hex: 0x1CB0F6)
    static let duoMacawDeep     = Color(hex: 0x0084C2)
    static let duoMacawBg       = Color(hex: 0xD2EFFD)
    static let duoMacawBorder   = Color(hex: 0x77D0FA)
    static let duoMacawNavBg    = Color(hex: 0xE1F4FF)   // BottomNav active tile bg
    static let duoMacawNavBorder = Color(hex: 0x91D7F6)  // BottomNav active tile border

    // Cardinal (red) — danger / mine / quiz
    static let duoCardinal     = Color(hex: 0xFF4B4B)
    static let duoCardinalDeep = Color(hex: 0xEA2B2B)
    static let duoCardinalBg   = Color(hex: 0xFFDFE0)

    // Bee (yellow) — XP / stars
    static let duoBee     = Color(hex: 0xFFC800)
    static let duoBeeDeep = Color(hex: 0xE6A900)
    static let duoBeeBg   = Color(hex: 0xFFF4CB)

    // Fox (orange) — streak / warning
    static let duoFox     = Color(hex: 0xFF9600)
    static let duoFoxDeep = Color(hex: 0xE08600)
    static let duoFoxBg   = Color(hex: 0xFFE7CE)

    // Beetle (purple) — rewards, gems
    static let duoBeetle     = Color(hex: 0xCE82FF)
    static let duoBeetleDeep = Color(hex: 0x8C39C8)

    // Humpback (deep blue) — leaderboard (참고용, 현재 미사용)
    static let duoHumpback = Color(hex: 0x2B70C9)

    // Neutrals
    static let duoSnow  = Color(hex: 0xF7F7F7)
    static let duoPolar = Color(hex: 0xF0F0F0)
    static let duoSwan  = Color(hex: 0xE5E5E5)
    static let duoSwan2 = Color(hex: 0xEBEBEB)
    static let duoHare  = Color(hex: 0xAFAFAF)
    static let duoWolf  = Color(hex: 0x777777)
    static let duoWolf2 = Color(hex: 0x4B4B4B)
    static let duoEel   = Color(hex: 0x3C3C3C)
    static let duoEel2  = Color(hex: 0x2D3339)

    // In-game HUD gradients (teal — 테마 외 고정값)
    static let hudTealStart = Color(hex: 0x2A8794)
    static let hudTealEnd   = Color(hex: 0x1A5E69)
    static let hudDarkStart = Color(hex: 0x1A5E69)
    static let hudDarkEnd   = Color(hex: 0x0E3A42)

    // AR Radar gradient
    static let radarGreenLight = Color(hex: 0x6CD87F)
    static let radarGreenDark  = Color(hex: 0x1A5223)
}

// MARK: - Gradients

extension LinearGradient {
    /// In-game top HUD — `linear-gradient(180deg, #2A8794, #1A5E69)`
    static let hudTeal = LinearGradient(
        colors: [.hudTealStart, .hudTealEnd],
        startPoint: .top, endPoint: .bottom
    )
    /// AR Hint/Found dark HUD — `linear-gradient(180deg, #1A5E69, #0E3A42)`
    static let hudDark = LinearGradient(
        colors: [.hudDarkStart, .hudDarkEnd],
        startPoint: .top, endPoint: .bottom
    )
}

extension RadialGradient {
    /// AR Radar disc — light center → dark edge
    static let radarDisc = RadialGradient(
        colors: [.radarGreenLight, .radarGreenDark],
        center: .center, startRadius: 0, endRadius: 32
    )
}

// MARK: - Fonts
// Jalnan2.ttf 는 PlaySpot/Resources/Fonts/Jalnan2.ttf 에 번들, Info.plist UIAppFonts 등록.
// 실제 폰트 메타데이터에서 추출한 식별자:
//   - Family name:     "Jalnan 2 TTF" (공백 포함)
//   - PostScript name: "Jalnan2TTF"   ← SwiftUI/UIFont 가 가장 안정적으로 인식
// 핸드오프 README/스타터의 "Jalnan2" 는 부정확하므로 사용하지 않는다.

extension Font {
    static let duoDisplayFontName = "Jalnan2TTF"

    /// Display font (Korean: Jalnan 2 / 폴백: system .heavy)
    static func duoDisplay(size: CGFloat) -> Font {
        .custom(duoDisplayFontName, size: size).weight(.heavy)
    }

    /// Body font — Nunito 미번들 시 SwiftUI 가 system 으로 폴백.
    static func duoBody(size: CGFloat = 14, weight: Font.Weight = .regular) -> Font {
        .custom("Nunito", size: size).weight(weight)
    }
}

// MARK: - Spacing & Radius

enum DuoSpace {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20
    static let s6: CGFloat = 24
    static let s8: CGFloat = 32
    static let s10: CGFloat = 40
    static let s12: CGFloat = 48
}

enum DuoRadius {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 8
    static let md: CGFloat = 10
    static let lg: CGFloat = 12
    static let xl: CGFloat = 14
    static let xxl: CGFloat = 16
    static let pill: CGFloat = 9999
}

// MARK: - Candy Button
// 솔리드 컬러 본체 + 4px 아래 오프셋 섀도. 누르면 y:4 + 섀도 제거.

struct CandyButtonStyle: ButtonStyle {
    enum Size {
        case xs, sm, regular
        var height: CGFloat { self == .xs ? 28 : self == .sm ? 36 : 48 }
        var hPad: CGFloat   { self == .xs ? 10 : self == .sm ? 14 : 18 }
        var fontSize: CGFloat { self == .xs ? 11 : self == .sm ? 12 : 14 }
    }

    var tint: Color = .duoGreen500
    var shadowColor: Color = .duoGreen700
    var size: Size = .regular

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(.duoDisplay(size: size.fontSize))
            .kerning(0.06 * size.fontSize)
            .textCase(.uppercase)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .padding(.horizontal, size.hPad)
            .background(
                RoundedRectangle(cornerRadius: DuoRadius.lg).fill(tint)
            )
            .offset(y: pressed ? 4 : 0)
            .background(
                RoundedRectangle(cornerRadius: DuoRadius.lg)
                    .fill(shadowColor)
                    .frame(height: size.height + 4)
            )
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

extension CandyButtonStyle {
    static let primary = CandyButtonStyle(tint: .duoGreen500, shadowColor: .duoGreen700)
    static let blue    = CandyButtonStyle(tint: .duoMacaw,    shadowColor: Color(hex: 0x1899D6))
    static let red     = CandyButtonStyle(tint: .duoCardinal, shadowColor: Color(hex: 0xD33333))
    static let orange  = CandyButtonStyle(tint: .duoFox,      shadowColor: .duoFoxDeep)
    static let purple  = CandyButtonStyle(tint: .duoBeetle,   shadowColor: .duoBeetleDeep)
}

// 편의 헬퍼 — `.buttonStyle(.primary)` 호출 가능하도록.
extension ButtonStyle where Self == CandyButtonStyle {
    static var primary: CandyButtonStyle { .primary }
    static var blue:    CandyButtonStyle { .blue }
    static var red:     CandyButtonStyle { .red }
    static var orange:  CandyButtonStyle { .orange }
    static var purple:  CandyButtonStyle { .purple }
}

// MARK: - Card

struct DuoCard<Content: View>: View {
    var radius: CGFloat = DuoRadius.xl
    var padding: CGFloat = 12
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Color.duoSwan2, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color.duoSwan2)
                    .offset(y: 2)
            )
    }
}

// MARK: - Chip

struct DuoChip: View {
    let label: String
    var bg: Color = .duoGreen100
    var fg: Color = .duoGreen800

    var body: some View {
        Text(label.uppercased())
            .font(.duoDisplay(size: 11))
            .kerning(0.5)
            .foregroundColor(fg)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(Capsule().fill(bg))
    }
}

extension DuoChip {
    static func green(_ label: String)  -> DuoChip { .init(label: label, bg: .duoGreen100,   fg: .duoGreen800) }
    static func red(_ label: String)    -> DuoChip { .init(label: label, bg: .duoCardinalBg, fg: .duoCardinalDeep) }
    static func orange(_ label: String) -> DuoChip { .init(label: label, bg: .duoFoxBg,      fg: .duoFoxDeep) }
    static func yellow(_ label: String) -> DuoChip { .init(label: label, bg: .duoBeeBg,      fg: .duoBeeDeep) }
    static func blue(_ label: String)   -> DuoChip { .init(label: label, bg: .duoMacawBg,    fg: .duoMacawDeep) }
    static func purple(_ label: String) -> DuoChip { .init(label: label, bg: Color(hex: 0xF1DCFF), fg: .duoBeetleDeep) }
}

// MARK: - Kicker

struct DuoKicker: View {
    let text: String
    var color: Color = .duoHare
    var body: some View {
        Text(text.uppercased())
            .font(.duoDisplay(size: 10))
            .kerning(0.6)
            .foregroundColor(color)
    }
}

// MARK: - Preview

#if DEBUG
struct DuoTokens_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DuoKicker(text: "Section 1, Unit 1")
                Text("PlaySpot")
                    .font(.duoDisplay(size: 36))
                    .foregroundColor(.duoEel2)

                HStack(spacing: 8) {
                    Button("Start") {}.buttonStyle(.primary)
                    Button("Info") {}.buttonStyle(.blue)
                    Button("Quit") {}.buttonStyle(.red)
                }
                HStack(spacing: 8) {
                    Button("XP") {}.buttonStyle(.orange)
                    Button("Quest") {}.buttonStyle(.purple)
                }

                DuoCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Level 0 · Beginner")
                            .font(.duoDisplay(size: 14))
                            .foregroundColor(.duoEel2)
                        Text("시작하는 플레이어를 위한 입문 미션")
                            .font(.duoBody(size: 12))
                            .foregroundColor(.duoWolf2)
                        HStack(spacing: 6) {
                            DuoChip.green("12 plays")
                            DuoChip.red("2 fails")
                            DuoChip.orange("Beginner")
                        }
                    }
                }

                LinearGradient.hudTeal
                    .frame(height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(Text("HUD Teal").font(.duoDisplay(size: 14)).foregroundColor(.white))

                RadialGradient.radarDisc
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
            }
            .padding()
        }
        .background(Color.duoSnow)
    }
}
#endif
