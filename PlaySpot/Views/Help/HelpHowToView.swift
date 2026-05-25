// Views/Help/HelpHowToView.swift — How to Play
// 디자인: README §15 / screens-tutorial.jsx ScreenHowToPlay
// orange hero + 2 mode cards + 4 PlayStep + reward strip + fox + bubble.

import SwiftUI

private struct PlayStep: Identifiable {
    let id: Int
    let title: String
    let body: String
    let icon: String
    let tint: Color
}

struct HelpHowToView: View {
    private static let steps: [PlayStep] = [
        PlayStep(id: 1, title: "지도 열고 미션 찾기", body: "근처에 숨겨진 아이템을 지도에서 확인하세요.",
                 icon: "map.fill", tint: .duoMacaw),
        PlayStep(id: 2, title: "직접 걸어서 이동", body: "표시된 위치까지 직접 걸어가야 아이템이 활성화됩니다.",
                 icon: "figure.walk", tint: .duoFox),
        PlayStep(id: 3, title: "AR로 흔들고 터치!", body: "거리 안에 들어가면 카메라를 켜고 흔들거나 터치해 획득.",
                 icon: "wand.and.stars", tint: .duoBeetle),
        PlayStep(id: 4, title: "퀴즈 풀고 클리어", body: "퀴즈 정답을 맞춰 모든 필수 아이템을 모으면 클리어!",
                 icon: "trophy.fill", tint: .duoBee)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            heroCard
            modeCards
            stepsList
            rewardStrip
            fox
            Spacer(minLength: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var heroCard: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                DuoKicker(text: "What is · 플레이스팟이란?", color: .duoFoxDeep)
                Text("PlaySpot?")
                    .font(.duoDisplay(size: 26))
                    .foregroundColor(.duoEel2)
                Text("실제 위치를 돌아다니며 AR로 아이템을 모으는\n위치 기반 트레저 헌트 게임이에요.")
                    .font(.duoBody(size: 13))
                    .foregroundColor(.duoWolf2)
            }
            Spacer()
            FoxMascot(pose: .cheer, size: 64)
        }
        .padding(16)
        .background(
            LinearGradient(colors: [.duoFoxBg, .white],
                           startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.duoFox.opacity(0.5), lineWidth: 2))
    }

    private var modeCards: some View {
        HStack(spacing: 10) {
            modeCard(kicker: "LIVE", title: "리얼 모드",
                     desc: "실제 GPS로 직접 걸으면서 플레이",
                     tint: .duoGreen500, bg: .duoGreen100)
            modeCard(kicker: "HOME", title: "가상 모드",
                     desc: "집에서도 위치를 시뮬레이션해 즐기기",
                     tint: .duoBeetle, bg: Color(hex: 0xF1DCFF))
        }
    }

    private func modeCard(kicker: String, title: String, desc: String, tint: Color, bg: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(kicker)
                .font(.duoDisplay(size: 10))
                .kerning(0.66)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(Capsule().fill(tint))
            Text(title)
                .font(.duoDisplay(size: 16))
                .foregroundColor(.duoEel2)
            Text(desc)
                .font(.duoBody(size: 11))
                .foregroundColor(.duoWolf2)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(bg))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(tint, lineWidth: 2))
    }

    private var stepsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            DuoKicker(text: "How to Play · 4 steps")
            VStack(spacing: 10) {
                ForEach(Self.steps) { step in
                    stepRow(step)
                }
            }
        }
    }

    private func stepRow(_ step: PlayStep) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(step.tint)
                    .frame(width: 36, height: 36)
                Text("\(step.id)")
                    .font(.duoDisplay(size: 16))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.duoDisplay(size: 14))
                    .foregroundColor(.duoEel2)
                Text(step.body)
                    .font(.duoBody(size: 12))
                    .foregroundColor(.duoWolf2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: step.icon)
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(step.tint)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.duoSwan2, lineWidth: 2))
    }

    private var rewardStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            DuoKicker(text: "Rewards · 보상", color: .white.opacity(0.7))
            HStack(spacing: 10) {
                perkChip(icon: "bolt.fill", label: "XP", tint: .duoBee)
                perkChip(icon: "diamond.fill", label: "Gem", tint: .duoBeetle)
                perkChip(icon: "flame.fill", label: "Streak", tint: .duoFox)
                perkChip(icon: "rosette", label: "Badge", tint: .duoMacaw)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.duoEel2))
    }

    private func perkChip(icon: String, label: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(tint.opacity(0.25))
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(tint)
            }
            .frame(width: 40, height: 40)
            Text(label.uppercased())
                .font(.duoDisplay(size: 10))
                .kerning(0.6)
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
    }

    private var fox: some View {
        HStack(alignment: .bottom, spacing: 10) {
            FoxMascot(pose: .wave, size: 64)
            HStack {
                Text("준비됐어요? 🎯")
                    .font(.duoDisplay(size: 14))
                    .foregroundColor(.duoEel2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.duoSwan2, lineWidth: 2))
            Spacer()
        }
    }
}

#if DEBUG
#Preview("HelpHowTo") {
    ScrollView { HelpHowToView() }
        .background(Color.duoSnow)
}
#endif
