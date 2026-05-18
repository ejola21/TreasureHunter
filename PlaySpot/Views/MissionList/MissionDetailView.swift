// Views/MissionList/MissionDetailView.swift
import SwiftUI

/// fullScreenCover(item:) 에 전달되는 플레이 설정.
/// isVirtual 을 item 안에 함께 포장해 playVirtual/@State 타이밍 레이스를 원천 제거.
private struct PlayConfig: Identifiable {
    let mission: Mission
    let isVirtual: Bool
    var id: String { "\(mission.id)_\(isVirtual)" }
}

struct MissionDetailView: View {
    let mission: Mission
    @State private var replies: [MissionReply] = []
    @State private var playConfig: PlayConfig?
    private let dataSource: MissionDataSource = AppConfig.dataSource

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 배지 이미지
                AsyncImage(url: URL(string: "\(APIEndpoint.badgeBaseURL)\(mission.id).png")) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.2))
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // 미션 정보
                VStack(alignment: .leading, spacing: 8) {
                    Text(mission.title).font(.title2.bold())
                    Text(mission.place).foregroundColor(.secondary)
                    Text(mission.description).font(.body)

                    HStack {
                        StarRatingView(rating: Double(mission.recommendAvg))
                        Text("(\(mission.recommendCnt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // 랭킹 정보
                    if !mission.shortUser1.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rankings").font(.headline)
                            rankRow(rank: 1, user: mission.shortUser1, record: mission.shortRecord1)
                            rankRow(rank: 2, user: mission.shortUser2, record: mission.shortRecord2)
                            rankRow(rank: 3, user: mission.shortUser3, record: mission.shortRecord3)
                        }
                    }
                }
                .padding(.horizontal)

                // 댓글
                if !replies.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reviews").font(.headline)
                        ForEach(replies) { reply in
                            Text(reply.text)
                                .font(.body)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }

                // 플레이 버튼
                VStack(spacing: 12) {
                    Button {
                        playConfig = PlayConfig(mission: mission, isVirtual: false)
                    } label: {
                        Label("Real Play", systemImage: "location.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if mission.isVirtual == .virtual {
                        Button {
                            playConfig = PlayConfig(mission: mission, isVirtual: true)
                        } label: {
                            Label("Virtual Play", systemImage: "globe")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(mission.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $playConfig) { config in
            MissionPlayView(
                missionID: config.mission.id,
                isNewStart: true,
                isVirtualMode: config.isVirtual
            )
        }
        .task {
            await AuthBootstrap.ensureAuthenticated()
            do {
                replies = try await dataSource.fetchReplies(missionID: mission.id)
            } catch {}
        }
    }

    private func rankRow(rank: Int, user: String, record: String) -> some View {
        HStack {
            Text("#\(rank)").font(.caption.bold()).frame(width: 24)
            Text(user).font(.caption)
            Spacer()
            Text(record).font(.caption.monospaced())
        }
    }
}

#if DEBUG
#Preview("MissionDetail") {
    NavigationStack { MissionDetailView(mission: .preview) }
}
#endif
