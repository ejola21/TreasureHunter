// Views/DesignSystem/BottomNav5.swift
// 5탭 커스텀 하단 네비게이션 — TabView 기본 탭바 교체용.
// 각 타일: flex 1, 아이콘 22px + UPPERCASE 9px label.
// 활성: macaw-nav-bg + macaw-nav-border + macaw-deep text.
// 디자인: README §"Bottom Nav (5-tab)" / screens-v2.jsx BottomNav5

import SwiftUI

enum MainTab: Int, CaseIterable, Identifiable {
    case missions, design, info, badge, settings
    var id: Int { rawValue }

    var label: String {
        switch self {
        case .missions: return "Missions"
        case .design:   return "Design"
        case .info:     return "My Info"
        case .badge:    return "Badge"
        case .settings: return "Settings"
        }
    }

    /// 디자인은 PSIcons 커스텀 SVG. 우선 SF Symbol 로 placeholder 후 Phase 7 에 외주 일러스트 교체.
    var systemSymbol: String {
        switch self {
        case .missions: return "list.bullet.rectangle"
        case .design:   return "square.and.pencil"
        case .info:     return "person.circle"
        case .badge:    return "rosette"
        case .settings: return "gearshape"
        }
    }
}

struct BottomNav5: View {
    @Binding var active: MainTab

    var body: some View {
        HStack(spacing: 8) {
            ForEach(MainTab.allCases) { tab in
                BottomNav5Tile(tab: tab, active: active == tab) {
                    withAnimation(.easeOut(duration: 0.12)) { active = tab }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(
            Color.white
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.duoSwan).frame(height: 2)
                }
        )
    }
}

private struct BottomNav5Tile: View {
    let tab: MainTab
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.systemSymbol)
                    .font(.system(size: 18, weight: active ? .heavy : .semibold))
                    .foregroundColor(active ? .duoMacawDeep : .duoHare)
                Text(tab.label.uppercased())
                    .font(.duoDisplay(size: 9))
                    .kerning(0.6)
                    .foregroundColor(active ? .duoMacawDeep : .duoHare)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(active ? Color.duoMacawNavBg : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(active ? Color.duoMacawNavBorder : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("BottomNav5") {
    struct Demo: View {
        @State var t: MainTab = .missions
        var body: some View {
            VStack {
                Spacer()
                Text("Tab: \(t.label)").padding()
                BottomNav5(active: $t)
            }
            .background(Color.duoSnow)
        }
    }
    return Demo()
}
#endif
