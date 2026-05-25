// Views/MissionBuilder/MissionBuilderView.swift — Design List v2 (Phase 5)
// 디자인: README §9 Design List v2 / screens-v2.jsx ScreenDesignListV2
// 비공개 FormGroup (orange chip) + 공개 FormGroup (green chip) + 헬퍼 텍스트.
// 데이터 로직 (load / deleteDrafts / unpublish) 은 보존.
import SwiftUI
import os

struct MissionBuilderView: View {
    @State private var drafts: [Mission] = []
    @State private var uploaded: [Mission] = []
    @State private var showCreate = false
    @State private var uploadResult: String?
    @State private var deleteBlockedAlert = false
    @State private var isLoading = false
    @State private var testTarget: Mission?
    @State private var editTarget: Mission?
    @State private var actionTarget: Mission?

    private var dataSource: MissionDataSource { AppConfig.dataSource }
    private static let log = Logger(subsystem: "com.ejola.playspot", category: "BuilderList")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                        .padding(.top, 4)

                    if !drafts.isEmpty {
                        FormGroup(title: "비공개") {
                            ForEach(Array(drafts.enumerated()), id: \.element.id) { idx, m in
                                DesignRowV2(
                                    mission: m,
                                    statusKind: .privateMission,
                                    isLast: idx == drafts.count - 1,
                                    onTap: { actionTarget = m },
                                    onTest: { testTarget = m }
                                )
                            }
                        }
                    }

                    if !uploaded.isEmpty {
                        FormGroup(
                            title: "공개",
                            subtitle: "공개된 미션은 바로 삭제할 수 없어요. 먼저 ‘공개 해제’ 한 뒤 비공개 목록에서 삭제하세요."
                        ) {
                            ForEach(Array(uploaded.enumerated()), id: \.element.id) { idx, m in
                                DesignRowV2(
                                    mission: m,
                                    statusKind: .publicMission,
                                    isLast: idx == uploaded.count - 1,
                                    onTap: { actionTarget = m },
                                    onTest: { testTarget = m }
                                )
                            }
                        }
                    }

                    if drafts.isEmpty && uploaded.isEmpty && !isLoading {
                        emptyState
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color.duoSnow.ignoresSafeArea())
            .navigationDestination(item: $editTarget) { mission in
                MissionSetupView(mission: mission)
            }
            .sheet(isPresented: $showCreate, onDismiss: { Task { await load() } }) {
                NavigationStack { MissionSetupView(mission: nil) }
            }
            .alert("업로드 결과", isPresented: .constant(uploadResult != nil), presenting: uploadResult) { _ in
                Button("확인") { uploadResult = nil }
            } message: { msg in Text(msg) }
            .alert("공개된 미션은 삭제할 수 없어요", isPresented: $deleteBlockedAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("먼저 ‘공개 해제’를 눌러 비공개 상태로 되돌린 뒤, 비공개 목록에서 삭제하세요.")
            }
            .refreshable { await load() }
            .overlay {
                if isLoading && drafts.isEmpty && uploaded.isEmpty {
                    ProgressView("불러오는 중…")
                }
            }
            .fullScreenCover(item: $testTarget) { mission in
                NavigationStack {
                    MissionDetailView(mission: mission, showReplies: false)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("닫기") { testTarget = nil }
                            }
                        }
                }
            }
            .sheet(item: $actionTarget) { mission in
                DesignActionSheet(
                    mission: mission,
                    onModify: {
                        actionTarget = nil
                        editTarget = mission
                    },
                    onTest: {
                        actionTarget = nil
                        testTarget = mission
                    },
                    onTogglePublish: {
                        let target = mission
                        actionTarget = nil
                        if target.status == .published {
                            Task { await unpublish(target) }
                        } else {
                            Task { await publish(target) }
                        }
                    },
                    onDelete: {
                        let target = mission
                        actionTarget = nil
                        if target.status == .published {
                            deleteBlockedAlert = true
                        } else {
                            Task {
                                _ = try? await dataSource.deleteMission(missionID: target.id)
                                await load()
                            }
                        }
                    },
                    onCancel: { actionTarget = nil }
                )
                .presentationDetents([.medium, .large])
            }
            .onAppear { Task { await load() } }
        }
    }

    // MARK: - 헤더 + 빈 상태

    private var header: some View {
        HStack(alignment: .center) {
            Text("내 디자인")
                .font(.duoDisplay(size: 28))
                .foregroundColor(.duoEel2)
            Spacer()
            Button {
                showCreate = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.duoGreen500))
                    .background(
                        RoundedRectangle(cornerRadius: 10).fill(Color.duoGreen700)
                            .offset(y: 4)
                    )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            FoxMascot(pose: .think, size: 64)
            Text("작성한 미션이 없어요")
                .font(.duoDisplay(size: 16))
                .foregroundColor(.duoEel2)
            Text("우측 상단 + 버튼으로 새 미션을 만들어보세요.")
                .font(.duoBody(size: 13))
                .foregroundColor(.duoHare)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - 데이터

    @MainActor
    private func load() async {
        isLoading = true
        defer { isLoading = false }

        let serverMissions = (try? await dataSource.fetchMyDesigned(userID: AppState.shared.userID)) ?? []
        drafts = serverMissions.filter { $0.status != .published }
        uploaded = serverMissions.filter { $0.status == .published }
        Self.log.info("load: server=\(serverMissions.count, privacy: .public) drafts=\(self.drafts.count, privacy: .public) uploaded=\(self.uploaded.count, privacy: .public)")
    }

    /// 공개 → 비공개 전환 (Status 2 → 0).
    private func unpublish(_ mission: Mission) async {
        let vm = MissionBuilderViewModel(mission: mission, items: mission.items,
                                         quizzes: mission.items.flatMap(\.quizzes))
        await vm.loadDetail()
        vm.mission.status = .unpublished
        let ok = await vm.save()
        if ok {
            await load()
        } else if let err = vm.saveError, err.isNotFound {
            uploadResult = "이 미션은 서버에서 이미 삭제됐어요. 목록을 새로고침합니다."
            await load()
        } else {
            uploadResult = vm.saveError?.userFacingMessage ?? "공개 해제에 실패했습니다. 잠시 후 다시 시도하세요."
        }
    }

    /// 비공개 → 공개 전환 (Status 0 → 2).
    private func publish(_ mission: Mission) async {
        let vm = MissionBuilderViewModel(mission: mission, items: mission.items,
                                         quizzes: mission.items.flatMap(\.quizzes))
        await vm.loadDetail()
        vm.mission.status = .published
        let ok = await vm.save()
        if ok {
            await load()
        } else {
            uploadResult = vm.saveError?.userFacingMessage ?? "공개에 실패했습니다. 잠시 후 다시 시도하세요."
        }
    }
}

// MARK: - Design Row v2

private struct DesignRowV2: View {
    enum StatusKind { case privateMission, publicMission }

    let mission: Mission
    let statusKind: StatusKind
    let isLast: Bool
    let onTap: () -> Void
    let onTest: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(mission.title.isEmpty ? "Untitled" : mission.title)
                                .font(.duoDisplay(size: 14))
                                .foregroundColor(.duoEel2)
                                .lineLimit(1)
                            statusChip
                        }
                        Text(mission.place.isEmpty
                             ? "장소 미설정 · 아이템 \(mission.items.count)개"
                             : "\(mission.place) · 아이템 \(mission.items.count)개")
                            .font(.duoBody(size: 11))
                            .foregroundColor(.duoHare)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: onTest) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11, weight: .heavy))
                        Text("테스트")
                            .font(.duoDisplay(size: 11))
                            .kerning(0.6)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.duoGreen500))
                    .background(
                        RoundedRectangle(cornerRadius: 8).fill(Color.duoGreen700).offset(y: 3)
                    )
                }
                .buttonStyle(.plain)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.duoHare)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            if !isLast {
                Rectangle().fill(Color.duoSwan).frame(height: 1).padding(.leading, 14)
            }
        }
    }

    private var statusChip: some View {
        Group {
            switch statusKind {
            case .privateMission: DuoChip.orange("비공개")
            case .publicMission:  DuoChip.green("공개")
            }
        }
    }
}

// 외부 호환용 stub
struct MissionBuilderListView: View {
    var body: some View { MissionBuilderView() }
}

#if DEBUG
#Preview("MissionBuilder") { MissionBuilderView() }
#endif
