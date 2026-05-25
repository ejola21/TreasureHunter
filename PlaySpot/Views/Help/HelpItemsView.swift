// Views/Help/HelpItemsView.swift — Item Glossary
// 디자인: README §14 Help · Item Glossary / screens-tutorial.jsx ScreenItemGlossary
// Property legend + 5 그룹 (Mission/Quiz/Radar/Time/Special). 각 그룹 컬러 헤더 + 아이템 row.

import SwiftUI

private struct ItemGroup: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let tint: Color
    let bg: Color
    let types: [ItemType]
}

struct HelpItemsView: View {
    private static let groups: [ItemGroup] = [
        ItemGroup(id: "core",  title: "Mission · 핵심",  subtitle: "미션 진행에 필요한 아이템",
                  tint: .duoGreen800, bg: .duoGreen100,
                  types: [.start, .end, .simple, .mine, .mineNoBomb, .random]),
        ItemGroup(id: "quiz",  title: "Quiz · 퀴즈",     subtitle: "정답을 맞춰야 획득",
                  tint: .duoCardinalDeep, bg: .duoCardinalBg,
                  types: [.quiz, .solution]),
        ItemGroup(id: "radar", title: "Radar · 레이더",  subtitle: "숨김 아이템을 보이게",
                  tint: .duoBeetleDeep, bg: Color(hex: 0xF1DCFF),
                  types: [.radarMap, .radarMine, .radarAR, .radarAll]),
        ItemGroup(id: "time",  title: "Time · 시간",     subtitle: "타임어택 트리거",
                  tint: .duoMacawDeep, bg: .duoMacawBg,
                  types: [.timeoutStart, .timeoutEnd]),
        ItemGroup(id: "special", title: "Special · 특수", subtitle: "특수 효과 아이템",
                  tint: .duoFoxDeep, bg: .duoFoxBg,
                  types: [.black, .store, .coupon])
    ]

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            propertyLegend

            ForEach(Self.groups) { group in
                groupCard(group)
            }
            Spacer(minLength: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Property Legend

    private var propertyLegend: some View {
        VStack(alignment: .leading, spacing: 6) {
            DuoKicker(text: "Properties · 아이템 속성")
            VStack(spacing: 0) {
                legendRow(emoji: "👁️", label: "Normal", desc: "지도/AR 모두 표시", isLast: false)
                rowDivider
                legendRow(emoji: "🗺️", label: "Hidden", desc: "AR 화면에서만 보임 (지도 숨김)", isLast: false)
                rowDivider
                legendRow(emoji: "🥷", label: "Stealth", desc: "AR 까지도 숨김 — Stealth Radar 필요", isLast: false)
                rowDivider
                legendRow(emoji: "⭐", label: "필수", desc: "획득해야 미션 클리어", isLast: true)
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.duoSwan2, lineWidth: 2))
        }
    }

    private func legendRow(emoji: String, label: String, desc: String, isLast: Bool) -> some View {
        HStack(spacing: 12) {
            Text(emoji).font(.system(size: 18))
            Text(label)
                .font(.duoDisplay(size: 13))
                .foregroundColor(.duoEel2)
                .frame(width: 70, alignment: .leading)
            Text(desc)
                .font(.duoBody(size: 12))
                .foregroundColor(.duoWolf2)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var rowDivider: some View {
        Rectangle().fill(Color.duoSwan).frame(height: 1).padding(.leading, 14)
    }

    // MARK: - 그룹 카드

    private func groupCard(_ group: ItemGroup) -> some View {
        VStack(spacing: 0) {
            // 헤더 (컬러 bg + 흰 텍스트)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.title)
                        .font(.duoDisplay(size: 14))
                        .foregroundColor(.white)
                    Text(group.subtitle)
                        .font(.duoBody(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(group.tint)

            // 아이템 row
            VStack(spacing: 0) {
                ForEach(Array(group.types.enumerated()), id: \.element) { idx, type in
                    itemRow(type: type, isLast: idx == group.types.count - 1)
                }
            }
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(group.tint, lineWidth: 2))
    }

    private func itemRow(type: ItemType, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ItemPin(type, size: 42)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(type.displayLabel)
                            .font(.duoDisplay(size: 14))
                            .foregroundColor(.duoEel2)
                    }
                    Text(type.detailGuide.effect)
                        .font(.duoBody(size: 11))
                        .foregroundColor(.duoWolf2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(14)

            if !isLast {
                Rectangle().fill(Color.duoSwan).frame(height: 1).padding(.leading, 14)
            }
        }
    }
}

#if DEBUG
#Preview("HelpItems") {
    ScrollView { HelpItemsView() }
        .background(Color.duoSnow)
}
#endif
