// Views/Components/FlipCounterView.swift
import SwiftUI

struct FlipCounterView: View {
    let value: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(digits, id: \.offset) { _, digit in
                SingleDigitFlip(digit: digit)
            }
        }
    }

    private var digits: [(offset: Int, element: Int)] {
        Array(String(format: "%02d", value).compactMap { $0.wholeNumberValue }.enumerated())
    }
}

struct SingleDigitFlip: View {
    let digit: Int

    var body: some View {
        Text("\(digit)")
            .font(.system(size: 24, weight: .bold, design: .monospaced))
            .frame(width: 24, height: 36)
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(4)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.3), value: digit)
    }
}

#if DEBUG
#Preview("FlipCounter") {
    VStack(spacing: 12) {
        FlipCounterView(value: 5)
        FlipCounterView(value: 42)
        FlipCounterView(value: 99)
    }
    .padding()
}
#endif
