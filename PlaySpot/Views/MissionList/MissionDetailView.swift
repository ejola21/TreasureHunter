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
    /// 댓글(리뷰) 섹션 표시 여부. 빌더의 "테스트" 진입 시에는 false (댓글 없이 동일 화면).
    var showReplies: Bool = true
    @State private var replies: [MissionReply] = []
    @State private var liveMission: Mission?      // 플레이 종료 후 평균 별점 갱신용 (nil = 초기 mission 사용).
    @State private var playConfig: PlayConfig?
    private let dataSource: MissionDataSource = AppConfig.dataSource

    /// 현재 화면이 표시할 미션 — 플레이 후 새로 fetch 한 값이 있으면 그것을, 없으면 초기값.
    private var displayMission: Mission { liveMission ?? mission }

    /// 댓글 일시 표시용 포맷터 (예: "5/23 13:45").
    static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "M/d HH:mm"
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 배지 이미지 — Mission.badgeImageName 으로 URL 구성.
                AsyncImage(url: displayMission.badgeImageURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.2))
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // 미션 정보
                VStack(alignment: .leading, spacing: 8) {
                    Text(displayMission.title).font(.title2.bold())
                    Text(mission.place).foregroundColor(.secondary)
                    Text(displayMission.description).font(.body)

                    HStack {
                        StarRatingView(rating: displayMission.recommendAvg)
                        Text("(\(displayMission.recommendCnt))")
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

                // 플레이 버튼 — 댓글 섹션 위에 배치 (사용자 요청).
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

                // 댓글 — 각 행에 작성자 별점 표시.
                if showReplies && !replies.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reviews").font(.headline)
                        ForEach(replies) { reply in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    StarRatingView(rating: reply.score ?? 0, starSize: 14)
                                    if let nick = reply.nickname, !nick.isEmpty {
                                        Text(nick)
                                            .font(.caption.bold())
                                            .foregroundColor(.primary)
                                    }
                                    Spacer()
                                    if let d = reply.writeDate {
                                        Text(Self.dateFmt.string(from: d))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Text(reply.text).font(.body)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(displayMission.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $playConfig, onDismiss: {
            // 플레이 종료(또는 후기 제출) 후 — 댓글 / 평균 별점 새로 fetch.
            Task { await refreshAfterPlay() }
        }) { config in
            MissionPlayView(
                missionID: config.mission.id,
                isNewStart: true,
                isVirtualMode: config.isVirtual
            )
        }
        .task {
            await AuthBootstrap.ensureAuthenticated()
            guard showReplies else { return }
            do {
                let fresh = try await dataSource.fetchReplies(missionID: mission.id)
                replies = ReplyOptimisticCache.shared.merged(missionID: mission.id, with: fresh)
            } catch {}
        }
    }

    /// 플레이 종료 후 호출 — 후기 목록 + 평균 별점/리뷰 카운트가 반영된 미션 상세를 다시 받는다.
    @MainActor
    private func refreshAfterPlay() async {
        if showReplies {
            if let fresh = try? await dataSource.fetchReplies(missionID: mission.id) {
                replies = ReplyOptimisticCache.shared.merged(missionID: mission.id, with: fresh)
            }
        }
        // 평균 별점/카운트는 fetchMissionDetail 응답의 Mission 으로 갱신.
        if let detail = try? await dataSource.fetchMissionDetail(missionID: mission.id) {
            liveMission = detail.0
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
