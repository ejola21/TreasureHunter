// Views/DesignSystem/DuoStepper.swift
// 30px height 알약 (1.5px swan border, snow bg). 36px wide −/+ buttons + 1px 분리선.
// SwiftUI 의 기본 Stepper 와 이름 충돌 회피 위해 DuoStepper.
// 디자인: README §"Stepper"

import SwiftUI

struct DuoStepper: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 5...200
    var step: Int = 5
    var unit: String? = nil
    var tint: Color = .duoEel

    var body: some View {
        HStack(spacing: 0) {
            stepperButton(symbol: "−", enabled: value > range.lowerBound) {
                value = max(range.lowerBound, value - step)
            }
            Divider()
                .frame(width: 1, height: 30)
                .background(Color.duoSwan)
            stepperButton(symbol: "+", enabled: value < range.upperBound) {
                value = min(range.upperBound, value + step)
            }
        }
        .background(
            Capsule().fill(Color.duoSnow)
        )
        .overlay(
            Capsule().stroke(Color.duoSwan, lineWidth: 1.5)
        )
        .frame(height: 30)
    }

    private func stepperButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
                .font(.duoDisplay(size: 18))
                .foregroundColor(enabled ? tint : .duoHare)
                .frame(width: 36, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

#if DEBUG
#Preview("DuoStepper") {
    struct Demo: View {
        @State var v1 = 45
        @State var v2 = 10
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack { Text("발견 거리: \(v1) m"); Spacer(); DuoStepper(value: $v1, range: 5...200, step: 5) }
                HStack { Text("Min reached: \(v2) m"); Spacer(); DuoStepper(value: $v2, range: 10...100, step: 10) }
            }
            .padding()
        }
    }
    return Demo()
}
#endif
