// Views/MyInfo/BadgeListView.swift
// 레거시 Badge List 화면 재현: "Mission Badge" / "Play Badge" 두 섹션,
// 청록색 헤더 + 3열 그리드. 미획득 슬롯은 empty02("?") 플레이스홀더.
import SwiftUI

struct BadgeListView: View {
    @State private var playedMissions: [Mission] = []
    private let dataSource: MissionDataSource = AppConfig.dataSource

    /// 레거시 res/img/play{N}.png 가 존재하는 마일스톤 목록 (= Badges/play{N}.imageset)
    private let playMilestones: [Int] = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 90, 100]
    /// Mission Badge 섹션 최소 셀 수 (없으면 placeholder만 채워서 그리드 모양 유지)
    private let missionBadgeMinSlots: Int = 6

    private var totalPlayCount: Int { playedMissions.count }

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    sectionCard(title: "Mission Badge") {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(playedMissions) { mission in
                                MissionBadgeCell(mission: mission)
                            }
                            // 미획득 자리 채우기
                            ForEach(0..<placeholderMissionCount, id: \.self) { _ in
                                PlaceholderBadgeCell()
                            }
                        }
                        .padding(12)
                    }

                    sectionCard(title: "Play Badge") {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(playMilestones, id: \.self) { milestone in
                                PlayBadgeCell(milestone: milestone, earned: totalPlayCount >= milestone)
                            }
                        }
                        .padding(12)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
            .background(Color(white: 0.95))
            .navigationTitle("Badge List")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                do {
                    playedMissions = try await dataSource.fetchMyPlayed(userID: AppState.shared.userID)
                } catch {}
            }
        }
    }

    private var placeholderMissionCount: Int {
        max(0, missionBadgeMinSlots - playedMissions.count)
    }

    // MARK: - 섹션 카드 (흰 배경 + 청록 헤더)

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(red: 0.12, green: 0.62, blue: 0.65))

            content()
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - 셀들

private struct MissionBadgeCell: View {
    let mission: Mission

    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: "\(APIEndpoint.badgeBaseURL)\(mission.id).png")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure, .empty:
                    Image("Badges/empty02").resizable().scaledToFit()
                @unknown default:
                    Image("Badges/empty02").resizable().scaledToFit()
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(mission.title)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct PlayBadgeCell: View {
    let milestone: Int
    let earned: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(earned ? "Badges/play\(milestone)" : "Badges/empty02")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            Text("\(milestone)")
                .font(.caption)
                .foregroundColor(earned ? .black : .gray)
        }
    }
}

private struct PlaceholderBadgeCell: View {
    var body: some View {
        VStack(spacing: 6) {
            Image("Badges/empty02")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            Text(" ")
                .font(.caption)
        }
    }
}

#if DEBUG
#Preview("BadgeList") { BadgeListView() }
#endif
