// DuoTokens.swift
// PlaySpot — SwiftUI design tokens.
// Drop this file into your project and use Color.duo* everywhere.

import SwiftUI

// MARK: - Colors

extension Color {
    // Brand greens (primary)
    static let duoGreen500 = Color(hex: 0x58CC02)
    static let duoGreen550 = Color(hex: 0x5ACD05)
    static let duoGreen700 = Color(hex: 0x5AA703)
    static let duoGreen750 = Color(hex: 0x48A502)
    static let duoGreen800 = Color(hex: 0x43A601)
    static let duoGreen100 = Color(hex: 0xD7FFB8)
    static let duoGreen900 = Color(hex: 0x375B0A)
    
    // Accents
    static let duoMacaw       = Color(hex: 0x1CB0F6)
    static let duoMacawDeep   = Color(hex: 0x0084C2)
    static let duoMacawBg     = Color(hex: 0xD2EFFD)
    static let duoMacawBorder = Color(hex: 0x77D0FA)
    
    static let duoCardinal     = Color(hex: 0xFF4B4B)
    static let duoCardinalDeep = Color(hex: 0xEA2B2B)
    static let duoCardinalBg   = Color(hex: 0xFFDFE0)
    
    static let duoBee     = Color(hex: 0xFFC800)
    static let duoBeeBg   = Color(hex: 0xFFF4CB)
    static let duoBeeDeep = Color(hex: 0xE6A900)
    
    static let duoFox     = Color(hex: 0xFF9600)
    static let duoFoxDeep = Color(hex: 0xE08600)
    static let duoFoxBg   = Color(hex: 0xFFE7CE)
    
    static let duoBeetle     = Color(hex: 0xCE82FF)
    static let duoBeetleDeep = Color(hex: 0x8C39C8)
    
    // Neutrals
    static let duoSnow  = Color(hex: 0xF7F7F7)
    static let duoSwan  = Color(hex: 0xE5E5E5)
    static let duoSwan2 = Color(hex: 0xEBEBEB)
    static let duoHare  = Color(hex: 0xAFAFAF)
    static let duoWolf  = Color(hex: 0x777777)
    static let duoWolf2 = Color(hex: 0x4B4B4B)
    static let duoEel   = Color(hex: 0x3C3C3C)
    static let duoEel2  = Color(hex: 0x2D3339)
    
    init(hex: UInt32) {
        self.init(
            red:   Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8)  & 0xff) / 255,
            blue:  Double(hex         & 0xff) / 255
        )
    }
}

// MARK: - Fonts
// Requires Jalnan2.ttf bundled and registered in Info.plist (UIAppFonts).

extension Font {
    /// Heavy display font (Korean: Jalnan, falls back to Nunito Black).
    static func duoDisplay(size: CGFloat) -> Font {
        .custom("Jalnan2", size: size).weight(.heavy)
    }
    /// Body font (Nunito on iOS — fallback to system if not bundled).
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
// Solid color body with flat 4px-down offset shadow. Press: translate y:4 + remove shadow.

struct CandyButtonStyle: ButtonStyle {
    var tint: Color = .duoGreen500
    var shadowColor: Color = .duoGreen700
    var size: Size = .regular
    
    enum Size { case xs, sm, regular
        var height: CGFloat { self == .xs ? 28 : self == .sm ? 36 : 48 }
        var hPad: CGFloat { self == .xs ? 10 : self == .sm ? 14 : 18 }
        var fontSize: CGFloat { self == .xs ? 11 : self == .sm ? 12 : 14 }
    }
    
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

// Convenience initializers
extension CandyButtonStyle {
    static let primary = CandyButtonStyle(tint: .duoGreen500, shadowColor: .duoGreen700)
    static let blue    = CandyButtonStyle(tint: .duoMacaw,    shadowColor: Color(hex: 0x1899D6))
    static let red     = CandyButtonStyle(tint: .duoCardinal, shadowColor: Color(hex: 0xD33333))
    static let orange  = CandyButtonStyle(tint: .duoFox,      shadowColor: .duoFoxDeep)
    static let purple  = CandyButtonStyle(tint: .duoBeetle,   shadowColor: .duoBeetleDeep)
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
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color.duoSwan2)
                    .offset(y: 2)
                    .mask(
                        RoundedRectangle(cornerRadius: radius)
                            .offset(y: 2)
                    )
                    .zIndex(-1)
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

// MARK: - Section Group Header (kicker label)

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

// MARK: - Demo

#if DEBUG
struct DuoTokens_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                DuoKicker(text: "Section 1, Unit 1")
                Text("PlaySpot")
                    .font(.duoDisplay(size: 36))
                    .foregroundColor(.duoEel2)
                
                Button("Start Mission") {}
                    .buttonStyle(.primary)
                
                Button("Settings") {}
                    .buttonStyle(.blue)
                
                Button("Delete") {}
                    .buttonStyle(.red)
                
                DuoCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Level 0 · Beginner")
                            .font(.duoDisplay(size: 14))
                            .foregroundColor(.duoEel2)
                        Text("시작하는 플레이어를 위한 입문 미션")
                            .font(.duoBody(size: 12))
                            .foregroundColor(.duoWolf2)
                        HStack(spacing: 6) {
                            DuoChip(label: "12 plays", bg: .duoGreen100, fg: .duoGreen800)
                            DuoChip(label: "2 fails", bg: .duoCardinalBg, fg: .duoCardinalDeep)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .background(Color.duoSnow)
    }
}
#endif
