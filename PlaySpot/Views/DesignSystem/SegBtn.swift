// Views/DesignSystem/SegBtn.swift
// 세그먼티드 탭 — 흰 배경 + 활성 액센트 (POPULAR/NEW/NEAR ME 패턴).
// 44px height, 12px radius, 2px border. 활성: theme-primary bg + border + text.
// 디자인: README §1 Mission List "Segmented tabs"

import SwiftUI

struct SegmentedTabs<T: Hashable & Identifiable>: View {
    @Binding var selection: T
    let options: [T]
    let label: (T) -> String
    var theme: Color = .duoGreen500
    var themeBg: Color = .duoGreen100
    var themeDeep: Color = .duoGreen800

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options) { option in
                let active = option == selection
                Button {
                    withAnimation(.easeOut(duration: 0.12)) { selection = option }
                } label: {
                    Text(label(option).uppercased())
                        .font(.duoDisplay(size: 12))
                        .kerning(0.6)
                        .foregroundColor(active ? themeDeep : .duoHare)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: DuoRadius.lg)
                                .fill(active ? themeBg : Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DuoRadius.lg)
                                .stroke(active ? theme : .duoSwan2, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// 2-옵션 라디오형 (Legacy / REST) — Settings 의 API Backend Picker.
struct SegBtnPair<T: Hashable>: View {
    @Binding var selection: T
    let options: [(T, String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { idx, pair in
                let active = pair.0 == selection
                Button {
                    withAnimation(.easeOut(duration: 0.12)) { selection = pair.0 }
                } label: {
                    Text(pair.1)
                        .font(.duoBody(size: 14, weight: .semibold))
                        .foregroundColor(active ? .duoEel : .duoHare)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(active ? Color.white : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(active ? Color.duoSwan : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                if idx < options.count - 1 {
                    Divider().frame(width: 1, height: 24).background(Color.duoSwan2)
                }
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(Color.duoSnow)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(Color.duoSwan2, lineWidth: 1)
        )
    }
}

#if DEBUG
private enum DemoTab: String, Identifiable, CaseIterable {
    case popular, new, near
    var id: String { rawValue }
}

#Preview("SegmentedTabs") {
    struct Demo: View {
        @State var sel: DemoTab = .popular
        @State var backend: String = "REST"
        var body: some View {
            VStack(spacing: 20) {
                SegmentedTabs(
                    selection: $sel,
                    options: DemoTab.allCases,
                    label: { $0.rawValue }
                )
                SegBtnPair(selection: $backend, options: [("Legacy", "Legacy"), ("REST", "REST")])
            }
            .padding()
        }
    }
    return Demo()
}
#endif
