// Views/DesignSystem/PSToggle.swift
// 56×32 알약형 토글. ON: green-500 fill + green-700 4px 오프셋 섀도, OFF: 회색.
// knob 26×26 white, "ON"/"OFF" 9px display label 내부.
// 디자인: README §"Toggle (PSToggle)"

import SwiftUI

struct PSToggle: View {
    @Binding var isOn: Bool
    var tint: Color = .duoGreen500
    var shadow: Color = .duoGreen700

    var body: some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                // Track
                Capsule()
                    .fill(isOn ? tint : Color.duoSwan)
                    .frame(width: 56, height: 32)
                    .overlay(
                        Capsule()
                            .fill(isOn ? shadow : Color.duoSwan2)
                            .frame(width: 56, height: 4)
                            .offset(y: 14)
                            .mask(Capsule().frame(width: 56, height: 32))
                    )

                // Knob
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .shadow(color: .black.opacity(0.12), radius: 1, x: 0, y: 1)
                    .overlay(
                        Text(isOn ? "ON" : "OFF")
                            .font(.duoDisplay(size: 9))
                            .foregroundColor(isOn ? tint : .duoHare)
                    )
                    .padding(.horizontal, 3)
            }
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("PSToggle") {
    struct Demo: View {
        @State var on = true
        @State var off = false
        var body: some View {
            VStack(spacing: 16) {
                PSToggle(isOn: $on)
                PSToggle(isOn: $off)
                PSToggle(isOn: $on, tint: .duoMacaw, shadow: .duoMacawDeep)
                PSToggle(isOn: $on, tint: .duoFox, shadow: .duoFoxDeep)
            }
            .padding()
        }
    }
    return Demo()
}
#endif
