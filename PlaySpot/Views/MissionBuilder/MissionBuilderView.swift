// Views/MissionBuilder/MissionBuilderView.swift — 내 디자인 목록
// plan_designer.md §7.1 / api_designer.md §6 (R1.4)
import SwiftUI
import os

struct MissionBuilderView: View {
    @State private var drafts: [Mission] = []
    @State private var uploaded: [Mission] = []
    @State private var showCreate = false
    @State private var uploadResult: String?
    @State private var deleteBlockedAlert = false
    @State private var isLoading = false
    /// 테스트 플레이 대상 미션 — 설정되면 MissionPlayView 를 fullScreenCover 로 띄운다.
    @State private var testTarget: Mission?

    private var dataSource: MissionDataSource { AppConfig.dataSource }
    private static let log = Logger(subsystem: "com.ejola.playspot", category: "BuilderList")

    var body: some View {
        NavigationStack {
            List {
                if !drafts.isEmpty {
                    Section("비공개") {
                        ForEach(drafts) { row($0) }
                            .onDelete { offsets in deleteDrafts(offsets: offsets) }
                    }
                }
                if !uploaded.isEmpty {
                    // 공개된 미션(Status=SERVER_UPLOAD)은 서버 정책상 직접 삭제 불가.
                    // api_designer.md §1.4.2 / §4.5 — 먼저 공개 해제(Status 2→1) 후 삭제.
                    // swipe delete 는 비활성하고, swipeActions 로 "공개 해제" 만 노출한다.
                    Section {
                        ForEach(uploaded) { mission in
                            row(mission)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        deleteBlockedAlert = true
                                    } label: {
                                        Label("삭제", systemImage: "trash")
                                    }
                                    .tint(.gray)        // 비활성 톤 — 안내만
                                    Button {
                                        Task { await unpublish(mission) }
                                    } label: {
                                        Label("공개 해제", systemImage: "lock.open")
                                    }
                                    .tint(.orange)
                                }
                        }
                    } header: {
                        Text("공개")
                    } footer: {
                        Text("공개된 미션은 바로 삭제할 수 없어요. 먼저 ‘공개 해제’ 한 뒤 비공개 목록에서 삭제하세요.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                if drafts.isEmpty && uploaded.isEmpty {
                    ContentUnavailableView("작성한 미션이 없습니다",
                                           systemImage: "map",
                                           description: Text("우측 상단 + 버튼으로 새 미션을 만들어보세요."))
                }
            }
            .navigationTitle("내 디자인")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showCreate = true } label: { Image(systemName: "plus") }
                }
            }
            .navigationDestination(for: Mission.self) { mission in
                MissionSetupView(mission: mission)
            }
            .sheet(isPresented: $showCreate, onDismiss: { Task { await load() } }) {
                NavigationStack { MissionSetupView(mission: nil) }
            }
            .alert("업로드 결과", isPresented: .constant(uploadResult != nil), presenting: uploadResult) { _ in
                Button("확인") { uploadResult = nil }
            } message: { msg in Text(msg) }
            .alert("공개된 미션은 삭제할 수 없어요", isPresented: $deleteBlockedAlert) {
                Button("확인", role: .cancel) { }
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
                // 테스트 — Missions 탭의 미션 상세와 동일 화면 (제목·설명·장소·Real/Virtual 플레이).
                // 댓글(리뷰)만 제외.
                NavigationStack {
                    MissionDetailView(mission: mission, showReplies: false)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("닫기") { testTarget = nil }
                            }
                        }
                }
            }
            .onAppear { Task { await load() } }
        }
    }

    // MARK: - 행

    @ViewBuilder
    private func row(_ mission: Mission) -> some View {
        NavigationLink(value: mission) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mission.title.isEmpty ? "Untitled" : mission.title)
                        .font(.headline)
                    HStack(spacing: 6) {
                        statusBadge(mission.status)
                        if mission.items.count > 0 {
                            Text("아이템 \(mission.items.count)")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        if !mission.place.isEmpty {
                            Text(mission.place)
                                .font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                // 테스트 플레이 — 저장된(서버) 미션을 가상 모드로 바로 플레이.
                Button {
                    testTarget = mission
                } label: {
                    Label("테스트", systemImage: "play.circle.fill")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderless)
                .tint(.green)
            }
        }
    }

    private func statusBadge(_ status: MissionStatus) -> some View {
        let (text, color): (String, Color) = {
            switch status {
            case .unpublished: return ("비공개", .orange)
            case .published:   return ("공개", .green)
            }
        }()
        return Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundColor(color)
    }

    // MARK: - 데이터

    /// 내 디자인 목록 로드.
    /// 빌더의 모든 저장이 서버로 일원화되었으므로 (로컬 draft 폐기), 서버 R1.4
    /// (`GET /users/{id}/missions/designed`) 응답만을 단일 소스로 쓴다.
    @MainActor
    private func load() async {
        isLoading = true
        defer { isLoading = false }

        let serverMissions = (try? await dataSource.fetchMyDesigned(userID: AppState.shared.userID)) ?? []
        drafts = serverMissions.filter { $0.status != .published }
        uploaded = serverMissions.filter { $0.status == .published }
        Self.log.info("load: server=\(serverMissions.count, privacy: .public) drafts=\(self.drafts.count, privacy: .public) uploaded=\(self.uploaded.count, privacy: .public)")
    }

    /// 비공개(작성 중) 미션 swipe delete — 서버에서 삭제 (R1.3).
    /// 비공개(Status=0)는 서버 정책상 삭제 허용.
    private func deleteDrafts(offsets: IndexSet) {
        let targets = offsets.map { drafts[$0] }
        drafts.remove(atOffsets: offsets)
        Task {
            for m in targets {
                _ = try? await dataSource.deleteMission(missionID: m.id)
            }
            await load()
        }
    }

    // MARK: - 공개 해제 (Status 2 → 0)

    /// 공개된 미션을 비공개로 되돌린다 (api_designer.md §4.5).
    /// R1.2 (`PATCH /missions/{id}`) 로 전체 페이로드를 다시 보내되 `Status=unpublished` 로 변경.
    /// 성공 시 목록 갱신 + 비공개 섹션으로 이동.
    private func unpublish(_ mission: Mission) async {
        let vm = MissionBuilderViewModel(mission: mission, items: mission.items,
                                         quizzes: mission.items.flatMap(\.quizzes))
        // designed 목록 응답은 items 가 비어 있으므로, 서버 상세를 먼저 로드.
        await vm.loadDetail()
        vm.mission.status = .unpublished   // loadDetail 이 mission 을 덮으므로 다시 명시.
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

}

// 외부 호환용 stub
struct MissionBuilderListView: View {
    var body: some View { MissionBuilderView() }
}

#if DEBUG
#Preview("MissionBuilder") { MissionBuilderView() }
#endif
