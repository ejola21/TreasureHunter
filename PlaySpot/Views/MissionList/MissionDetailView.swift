// Views/MissionList/MissionDetailView.swift
// Phase 4 — Candy 디자인. 영웅 카드 + InfoRow + 핀 프리뷰 + PLAY CandyButton + Mode Sheet 오버레이.
// 데이터 fetch / replies 로직 보존.
import SwiftUI

/// fullScreenCover(item:) 에 전달되는 플레이 설정.
private struct PlayConfig: Identifiable {
    let mission: Mission
    let isVirtual: Bool
    var id: String { "\(mission.id)_\(isVirtual)" }
}

struct MissionDetailView: View {
    let mission: Mission
    var showReplies: Bool = true
    @State private var replies: [MissionReply] = []
    @State private var liveMission: Mission?
    @State private var playConfig: PlayConfig?
    @State private var showModeSheet = false
    private let dataSource: MissionDataSource = AppConfig.dataSource

    private var displayMission: Mission { liveMission ?? mission }

    static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "M/d HH:mm"
        return f
    }()

    static let writeFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                infoRowsCard
                if !displayMission.items.isEmpty {
                    itemsPreviewCard
                }
                rankingsCard
                if showReplies && !replies.isEmpty {
                    reviewsCard
                }
                Spacer(minLength: 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color.duoSnow.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            playButton
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .background(Color.duoSnow.opacity(0.95))
        }
        .navigationTitle(displayMission.title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if showModeSheet {
                modeSheet
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .fullScreenCover(item: $playConfig, onDismiss: {
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

    // MARK: - 영웅 카드

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AsyncImage(url: displayMission.badgeImageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(Color.duoMacawBg)
                        Image(systemName: "rosette")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.duoMacawDeep)
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.duoMacawBorder, lineWidth: 2))

                VStack(alignment: .leading, spacing: 4) {
                    DuoKicker(text: "By \(displayMission.designer.uppercased())", color: .duoMacawDeep)
                    Text(displayMission.title)
                        .font(.duoDisplay(size: 18))
                        .foregroundColor(.duoEel2)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        StarRatingView(rating: displayMission.recommendAvg, starSize: 12)
                        Text("(\(displayMission.recommendCnt))")
                            .font(.duoBody(size: 11))
                            .foregroundColor(.duoHare)
                    }
                }
                Spacer()
            }

            if !displayMission.description.isEmpty {
                Text(displayMission.description)
                    .font(.duoBody(size: 13))
                    .foregroundColor(.duoWolf2)
            }

            HStack(spacing: 6) {
                DuoChip.green("\(displayMission.playCnt) PLAYS")
                if displayMission.failCnt > 0 {
                    DuoChip.red("\(displayMission.failCnt) FAILS")
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.duoMacawBg))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.duoMacawBorder, lineWidth: 2))
    }

    // MARK: - InfoRow Card

    private var infoRowsCard: some View {
        VStack(spacing: 0) {
            infoRow(icon: "mappin.and.ellipse", tint: .duoMacaw, label: "Place", value: displayMission.place)
            divider
            infoRow(icon: "list.bullet.rectangle", tint: .duoGreen500,
                    label: "Items", value: "\(displayMission.items.count) items")
            divider
            infoRow(icon: "clock.fill", tint: .duoFox,
                    label: "Time Limit",
                    value: displayMission.limitTime > 0
                        ? formatTime(displayMission.limitTime)
                        : "무제한")
            divider
            infoRow(icon: "calendar", tint: .duoBeetle,
                    label: "Created", value: Self.writeFmt.string(from: displayMission.writeDate))
        }
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.duoSwan2, lineWidth: 2))
    }

    private func infoRow(icon: String, tint: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(tint.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.duoDisplay(size: 10))
                    .kerning(0.6)
                    .foregroundColor(.duoHare)
                Text(value)
                    .font(.duoBody(size: 14, weight: .semibold))
                    .foregroundColor(.duoEel2)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Rectangle().fill(Color.duoSwan).frame(height: 1).padding(.leading, 58)
    }

    // MARK: - 핀 프리뷰

    private var itemsPreviewCard: some View {
        let preview = Array(displayMission.items.prefix(6))
        return VStack(alignment: .leading, spacing: 10) {
            DuoKicker(text: "Items in Mission")
            HStack(spacing: 12) {
                ForEach(preview, id: \.itemID) { item in
                    ItemPin(item.itemType, size: 36, active: item.isMandatory)
                }
                if displayMission.items.count > 6 {
                    Text("+\(displayMission.items.count - 6)")
                        .font(.duoDisplay(size: 14))
                        .foregroundColor(.duoHare)
                }
                Spacer()
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.duoSwan2, lineWidth: 2))
    }

    // MARK: - 랭킹

    private var rankingsCard: some View {
        Group {
            if !mission.shortUser1.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    DuoKicker(text: "Rankings")
                    rankRow(rank: 1, user: mission.shortUser1, record: mission.shortRecord1)
                    if !mission.shortUser2.isEmpty {
                        rankRow(rank: 2, user: mission.shortUser2, record: mission.shortRecord2)
                    }
                    if !mission.shortUser3.isEmpty {
                        rankRow(rank: 3, user: mission.shortUser3, record: mission.shortRecord3)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.duoSwan2, lineWidth: 2))
            } else {
                EmptyView()
            }
        }
    }

    private func rankRow(rank: Int, user: String, record: String) -> some View {
        HStack(spacing: 10) {
            Text("#\(rank)")
                .font(.duoDisplay(size: 14))
                .foregroundColor(rank == 1 ? .duoBee : .duoHare)
                .frame(width: 28, alignment: .leading)
            Text(user)
                .font(.duoBody(size: 13, weight: .semibold))
                .foregroundColor(.duoEel)
            Spacer()
            Text(record)
                .font(.duoDisplay(size: 12))
                .foregroundColor(.duoWolf2)
        }
    }

    // MARK: - 리뷰

    private var reviewsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            DuoKicker(text: "Reviews")
            ForEach(replies) { reply in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        StarRatingView(rating: reply.score ?? 0, starSize: 12)
                        if let nick = reply.nickname, !nick.isEmpty {
                            Text(nick)
                                .font(.duoDisplay(size: 11))
                                .foregroundColor(.duoEel2)
                        }
                        Spacer()
                        if let d = reply.writeDate {
                            Text(Self.dateFmt.string(from: d))
                                .font(.duoBody(size: 10))
                                .foregroundColor(.duoHare)
                        }
                    }
                    Text(reply.text)
                        .font(.duoBody(size: 13))
                        .foregroundColor(.duoWolf2)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.duoSnow))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.duoSwan2, lineWidth: 2))
    }

    // MARK: - PLAY 버튼 + Mode Sheet

    private var playButton: some View {
        Button("Play · 미션 시작") {
            // 가상 모드를 지원하지 않으면 바로 Real 시작.
            if mission.isVirtual == .virtual {
                withAnimation(.easeOut(duration: 0.15)) { showModeSheet = true }
            } else {
                playConfig = PlayConfig(mission: mission, isVirtual: false)
            }
        }
        .buttonStyle(.primary)
    }

    private var modeSheet: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { withAnimation { showModeSheet = false } }

            VStack(spacing: 14) {
                DuoKicker(text: "Choose Mode · 모드 선택")
                Text("어떻게 플레이할까요?")
                    .font(.duoDisplay(size: 20))
                    .foregroundColor(.duoEel2)

                HStack(spacing: 10) {
                    modeButton(title: "Real", subtitle: "실제 GPS", tint: .duoGreen500, deep: .duoGreen800) {
                        playConfig = PlayConfig(mission: mission, isVirtual: false)
                        withAnimation { showModeSheet = false }
                    }
                    modeButton(title: "Virtual", subtitle: "가상 위치", tint: .duoBeetle, deep: .duoBeetleDeep) {
                        playConfig = PlayConfig(mission: mission, isVirtual: true)
                        withAnimation { showModeSheet = false }
                    }
                }

                Button("취소", role: .cancel) {
                    withAnimation { showModeSheet = false }
                }
                .font(.duoBody(size: 14, weight: .semibold))
                .foregroundColor(.duoHare)
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: 320)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.duoSwan2, lineWidth: 2))
            .shadow(color: Color.black.opacity(0.3), radius: 18, x: 0, y: 8)
        }
    }

    private func modeButton(title: String, subtitle: String, tint: Color, deep: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.duoDisplay(size: 14))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.duoBody(size: 11))
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 12).fill(tint))
            .background(RoundedRectangle(cornerRadius: 12).fill(deep).offset(y: 4))
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func refreshAfterPlay() async {
        if showReplies {
            if let fresh = try? await dataSource.fetchReplies(missionID: mission.id) {
                replies = ReplyOptimisticCache.shared.merged(missionID: mission.id, with: fresh)
            }
        }
        if let detail = try? await dataSource.fetchMissionDetail(missionID: mission.id) {
            liveMission = detail.0
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

#if DEBUG
#Preview("MissionDetail") {
    NavigationStack { MissionDetailView(mission: .preview) }
}
#endif
