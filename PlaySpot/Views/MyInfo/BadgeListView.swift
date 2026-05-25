// Views/MyInfo/BadgeListView.swift
// Phase 3 — 티얼 헤더 + 3-col 그리드 (60×60 원형 뱃지).
// Mission Badge: 실제 플레이한 미션의 뱃지. Play Badge: 플레이 카운트 마일스톤.
// 디자인: README §11 Badge List v2
import SwiftUI

struct BadgeListView: View {
    @State private var playedMissions: [Mission] = []
    private let dataSource: MissionDataSource = AppConfig.dataSource

    private let playMilestones: [Int] = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 90, 100]
    private let missionBadgeMinSlots: Int = 6

    private var totalPlayCount: Int { playedMissions.count }

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    private var placeholderMissionCount: Int {
        max(0, missionBadgeMinSlots - playedMissions.count)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Badge List")
                    .font(.duoDisplay(size: 22))
                    .foregroundColor(.duoEel2)
                    .padding(.top, 8)

                badgeSection(title: "Mission Badge") {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(playedMissions) { m in
                            MissionBadgeCell(mission: m)
                        }
                        ForEach(0..<placeholderMissionCount, id: \.self) { _ in
                            LockedBadgeCell()
                        }
                    }
                    .padding(12)
                }

                badgeSection(title: "Play Badge") {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(playMilestones, id: \.self) { ms in
                            PlayBadgeCell(milestone: ms, earned: totalPlayCount >= ms)
                        }
                    }
                    .padding(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.duoSnow.ignoresSafeArea())
        .task {
            do {
                playedMissions = try await dataSource.fetchMyPlayed(userID: AppState.shared.userID)
            } catch {}
        }
    }

    // MARK: - 섹션 (티얼 헤더 + 카드 내용)

    private func badgeSection<C: View>(title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.duoDisplay(size: 16))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                Color(hex: 0x1C8A9F)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Color.black.opacity(0.18)).frame(height: 3)
                    }
            )

            content()
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(Color.duoSwan2, lineWidth: 2)
        )
    }
}

// MARK: - 셀

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
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.duoEel.opacity(0.5), lineWidth: 2.5))
            .shadow(color: Color.black.opacity(0.18), radius: 0, x: 0, y: 3)

            Text(mission.title)
                .font(.duoBody(size: 11, weight: .semibold))
                .foregroundColor(.duoEel2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct PlayBadgeCell: View {
    let milestone: Int
    let earned: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(earned ? Color.duoGreen400 : Color.duoSwan)
                    .overlay(Circle().stroke(earned ? Color.duoGreen800 : Color.duoHare, lineWidth: 2.5))
                    .shadow(color: Color.black.opacity(earned ? 0.18 : 0), radius: 0, x: 0, y: earned ? 3 : 0)

                if earned {
                    VStack(spacing: 0) {
                        Text("play").font(.duoDisplay(size: 8)).foregroundColor(.white)
                        Text("\(milestone)").font(.duoDisplay(size: 14)).foregroundColor(.white)
                    }
                    .shadow(color: Color.duoGreen900.opacity(0.8), radius: 0, x: 0, y: 1)
                } else {
                    Text("?")
                        .font(.duoDisplay(size: 18))
                        .foregroundColor(.duoHare)
                }
            }
            .frame(width: 60, height: 60)

            Text("\(milestone)")
                .font(.duoBody(size: 11, weight: .semibold))
                .foregroundColor(earned ? .duoEel2 : .duoHare)
        }
    }
}

private struct LockedBadgeCell: View {
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.duoSwan)
                    .overlay(Circle().stroke(Color.duoHare, lineWidth: 2.5))
                Text("?")
                    .font(.duoDisplay(size: 22))
                    .foregroundColor(.duoHare)
            }
            .frame(width: 60, height: 60)

            Text(" ").font(.duoBody(size: 11))
        }
    }
}

#if DEBUG
#Preview("BadgeList") { BadgeListView() }
#endif
