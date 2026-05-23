// Views/MissionList/MissionRowView.swift
import SwiftUI

struct MissionRowView: View {
    let mission: Mission

    /// 생성일자 표시용 — "2026/05/23" 형식.
    static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            // 배지 이미지 — Mission.badgeImageName 으로 정확한 URL 구성.
            // 서버 응답에 fileName 이 없거나 미설정이면 placeholder.
            // (다운로드 전략 확정 전까지 S3 직접 노출 보류 — badgeBaseURL 은 레거시 정적 경로.)
            AsyncImage(url: mission.badgeImageURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(mission.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(mission.place)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    StarRatingView(rating: mission.recommendAvg, starSize: 12)

                    Text("Play: \(mission.playCnt)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(Self.dateFmt.string(from: mission.writeDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if mission.isVirtual == .virtual {
                Image(systemName: "v.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview("MissionRow") {
    List {
        MissionRowView(mission: .preview)
    }
}
#endif
