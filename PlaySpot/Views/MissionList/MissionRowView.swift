// Views/MissionList/MissionRowView.swift
import SwiftUI

struct MissionRowView: View {
    let mission: Mission

    var body: some View {
        HStack(spacing: 12) {
            // 배지 이미지 (기존 MissionListCell의 badgeImageView)
            AsyncImage(url: URL(string: "\(APIEndpoint.badgeBaseURL)\(mission.id).png")) { image in
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
                    StarRatingView(rating: Double(mission.recommendAvg), starSize: 12)

                    Text("Play: \(mission.playCnt)")
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
