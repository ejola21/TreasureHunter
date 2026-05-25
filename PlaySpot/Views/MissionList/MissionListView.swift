// Views/MissionList/MissionListView.swift
// Phase 3 — Duolingo candy 헤더 (Fox + Streak/Gem chip) + SegmentedTabs (POPULAR/NEW/NEAR ME) + Mission Card.
// 데이터 로직 (selectedTab → fetch dispatch) 은 보존.
import SwiftUI

struct MissionListView: View {
    @State private var missions: [Mission] = []
    @State private var selectedTab: ListTab = .all
    @State private var isLoading = false
    @State private var selectedMission: Mission?
    private let dataSource: MissionDataSource = AppConfig.dataSource

    /// 기존 0=Playing / 1=Near Me / 2=All 매핑을 디자인 라벨로 swap.
    enum ListTab: String, Identifiable, CaseIterable {
        case popular, new, near, all   // 4탭으로 확장 (디자인은 3탭이지만 기존 "All" 유지)
        var id: String { rawValue }
        var label: String {
            switch self {
            case .popular: return "Popular"
            case .new:     return "New"
            case .near:    return "Near Me"
            case .all:     return "All"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                SegmentedTabs(
                    selection: $selectedTab,
                    options: ListTab.allCases,
                    label: { $0.label }
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(missions) { m in
                            Button { selectedMission = m } label: {
                                MissionRowView(mission: m)
                            }
                            .buttonStyle(.plain)
                        }
                        if missions.isEmpty && !isLoading {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .refreshable { await loadMissions() }
            }
            .background(Color.duoSnow.ignoresSafeArea())
            .navigationDestination(item: $selectedMission) { mission in
                MissionDetailView(mission: mission)
            }
            .task {
                let loc = AppState.shared.locationService
                loc.requestPermission()
                loc.startUpdating()
                await loadMissions()
            }
            .onChange(of: selectedTab) { _, _ in
                Task { await loadMissions() }
            }
            .loadingHUD(isPresented: isLoading)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            FoxMascot(pose: .wave, size: 36)
            VStack(alignment: .leading, spacing: 0) {
                DuoKicker(text: "Playing Now")
                Text("Missions")
                    .font(.duoDisplay(size: 22))
                    .foregroundColor(.duoEel2)
            }
            Spacer()
            statChip(symbol: "flame.fill", value: "7", tint: .duoFox)
            statChip(symbol: "diamond.fill", value: "248", tint: .duoMacaw)
        }
    }

    private func statChip(symbol: String, value: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(tint)
            Text(value)
                .font(.duoDisplay(size: 12))
                .foregroundColor(.duoEel)
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(Capsule().fill(Color.white))
        .overlay(Capsule().stroke(Color.duoSwan2, lineWidth: 2))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            FoxMascot(pose: .think, size: 56)
            Text("표시할 미션이 없어요.")
                .font(.duoBody(size: 14))
                .foregroundColor(.duoHare)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func loadMissions() async {
        isLoading = true
        defer { isLoading = false }
        await AuthBootstrap.ensureAuthenticated()

        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        let userID = AppState.shared.userID
        do {
            switch selectedTab {
            case .popular:
                // 서버에 popular 분리 호출 없음 — All 과 동일.
                missions = try await dataSource.fetchMissionList(cursor: 0, lang: lang)
            case .new:
                // Playing (TR=602) 매핑 유지.
                missions = try await dataSource.fetchCurrentGames(userID: userID)
            case .near:
                let coord = AppState.shared.locationService.currentLocation?.coordinate
                missions = try await dataSource.fetchPublishedMissions(
                    cursor: 0, lang: lang,
                    latitude: coord?.latitude ?? 0,
                    longitude: coord?.longitude ?? 0
                )
            case .all:
                missions = try await dataSource.fetchMissionList(cursor: 0, lang: lang)
            }
        } catch {
            print("❌ loadMissions error: \(error)")
            missions = []
        }
    }
}

#if DEBUG
#Preview("MissionList") { MissionListView() }
#endif
