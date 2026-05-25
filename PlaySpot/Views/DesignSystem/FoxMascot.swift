// Views/DesignSystem/FoxMascot.swift
// 4 pose 폭스 마스코트 — wave/sit/think/cheer. 디자인은 SVG 일러스트.
// Phase 1 placeholder: SF Symbol (face.smiling) + pose 별 회전/색상 차이.
// Phase 7 에서 실제 일러스트 PNG 4장으로 교체 예정.
// 디자인: README §"Fox Mascot"

import SwiftUI

enum FoxPose {
    case wave, sit, think, cheer

    var systemSymbol: String {
        switch self {
        case .wave:  return "hand.wave.fill"
        case .sit:   return "face.smiling.inverse"
        case .think: return "questionmark.bubble.fill"
        case .cheer: return "star.fill"
        }
    }
}

struct FoxMascot: View {
    var pose: FoxPose = .wave
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.duoFoxBg)
                .overlay(Circle().stroke(Color.duoFox, lineWidth: 2))
            Image(systemName: pose.systemSymbol)
                .font(.system(size: size * 0.5, weight: .heavy))
                .foregroundStyle(Color.duoFox)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Fox mascot — \(String(describing: pose))")
    }
}

#if DEBUG
#Preview("FoxMascot") {
    HStack(spacing: 16) {
        FoxMascot(pose: .wave,  size: 48)
        FoxMascot(pose: .sit,   size: 48)
        FoxMascot(pose: .think, size: 48)
        FoxMascot(pose: .cheer, size: 48)
    }
    .padding()
}
#endif
