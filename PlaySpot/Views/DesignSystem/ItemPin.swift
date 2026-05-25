// Views/DesignSystem/ItemPin.swift
// 3D PNG 아이템 핀 (Items/i_*.imageset). ItemType 또는 직접 imageName 지정 가능.
// active=true: 우측상단 별 뱃지 (필수 표시). glow=true: 후면 radial halo.
// 디자인: README §"Item Pin" / pins.jsx GAME_ITEMS

import SwiftUI

struct ItemPin: View {
    enum Kind {
        case type(ItemType)
        case named(String)   // e.g. "start", "mine" — Items/i_<name> 매핑

        var imageName: String {
            switch self {
            case .type(let t):   return "Items/i_\(t.imageFileName)"
            case .named(let n):  return "Items/i_\(n)"
            }
        }
    }

    let kind: Kind
    var size: CGFloat = 56
    var active: Bool = false
    var glow: Bool = false
    var dimmed: Bool = false
    var glowTint: Color = .duoBee

    init(_ type: ItemType, size: CGFloat = 56, active: Bool = false, glow: Bool = false, dimmed: Bool = false) {
        self.kind = .type(type)
        self.size = size
        self.active = active
        self.glow = glow
        self.dimmed = dimmed
    }

    init(named: String, size: CGFloat = 56, active: Bool = false, glow: Bool = false, dimmed: Bool = false) {
        self.kind = .named(named)
        self.size = size
        self.active = active
        self.glow = glow
        self.dimmed = dimmed
    }

    var body: some View {
        ZStack {
            if glow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [glowTint.opacity(0.55), .clear],
                            center: .center, startRadius: 0, endRadius: size * 0.9
                        )
                    )
                    .frame(width: size * 1.6, height: size * 1.6)
            }

            Image(kind.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size * 1.2)
                .saturation(dimmed ? 0.4 : 1.0)
                .opacity(dimmed ? 0.55 : 1.0)

            if active {
                StarBadge(size: size * 0.46)
                    .offset(x: size * 0.30, y: -size * 0.45)
            }
        }
        .frame(width: size, height: size * 1.2)
    }
}

/// 필수 아이템 표시용 노란 별 뱃지 (흰 보더 + 별).
private struct StarBadge: View {
    var size: CGFloat = 22

    var body: some View {
        ZStack {
            Circle().fill(Color.duoBee)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.55, weight: .heavy))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

#if DEBUG
#Preview("ItemPin") {
    ScrollView {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                ItemPin(.start, size: 56)
                ItemPin(.end, size: 56)
                ItemPin(.mine, size: 56, active: true)
                ItemPin(.quiz, size: 56, glow: true)
            }
            HStack(spacing: 16) {
                ItemPin(.simple, size: 36)
                ItemPin(.solution, size: 36)
                ItemPin(.radarMap, size: 36, dimmed: true)
                ItemPin(.timeoutStart, size: 36)
            }
            ItemPin(.mine, size: 80, active: true, glow: true)
        }
        .padding()
    }
    .background(Color.duoSnow)
}
#endif
