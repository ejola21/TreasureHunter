// Views/MissionList/MissionRowView.swift
// Phase 3 — Candy 카드 스타일.
// 좌측 64×64 뱃지 (AsyncImage + level badge), 우측 PLAYS/FAILS chip.
// 디자인: README §1 Mission List
import SwiftUI

struct MissionRowView: View {
    let mission: Mission

    static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    /// 미션 디자이너 ID 마지막 글자 기반으로 4가지 액센트 색상 분배 — 데코레이션용.
    private var tint: (bg: Color, border: Color, deep: Color) {
        let palette: [(Color, Color, Color)] = [
            (.duoGreen100, .duoGreen500, .duoGreen800),
            (.duoMacawBg,  .duoMacaw,    .duoMacawDeep),
            (.duoFoxBg,    .duoFox,      .duoFoxDeep),
            (Color(hex: 0xF1DCFF), .duoBeetle, .duoBeetleDeep)
        ]
        let hash = abs(mission.id.hashValue) % palette.count
        return palette[hash]
    }

    var body: some View {
        HStack(spacing: 12) {
            // 뱃지 (64×64 카드 + 레벨 원)
            badgeTile
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(mission.title)
                    .font(.duoDisplay(size: 15))
                    .foregroundColor(.duoEel2)
                    .lineLimit(1)

                Text(mission.place)
                    .font(.duoBody(size: 11))
                    .foregroundColor(.duoWolf2)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    StarRatingView(rating: mission.recommendAvg, starSize: 11)
                    Text("Play: \(mission.playCnt)  ·  \(Self.dateFmt.string(from: mission.writeDate))")
                        .font(.duoBody(size: 9, weight: .semibold))
                        .foregroundColor(.duoMacaw)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                DuoChip.green("\(mission.playCnt) PLAYS")
                if mission.failCnt > 0 {
                    DuoChip.red("\(mission.failCnt) FAILS")
                }
                if mission.isVirtual == .virtual {
                    DuoChip.blue("V")
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DuoRadius.xl).fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DuoRadius.xl).stroke(Color.duoSwan2, lineWidth: 2)
        )
    }

    private var badgeTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DuoRadius.lg).fill(tint.bg)

            AsyncImage(url: mission.badgeImageURL) { image in
                // 여백 없이 컨테이너 꽉 차게 — fill 로 잘라내고 cornerRadius 로 클립.
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "rosette")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(tint.deep)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DuoRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DuoRadius.lg)
                .stroke(tint.border, lineWidth: 2)
        )
    }
}

#if DEBUG
#Preview("MissionRow") {
    VStack(spacing: 12) {
        MissionRowView(mission: .preview)
    }
    .padding()
    .background(Color.duoSnow)
}
#endif
