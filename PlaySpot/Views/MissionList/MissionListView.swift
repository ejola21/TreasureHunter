// Views/MissionList/MissionListView.swift
import SwiftUI

struct MissionListView: View {
    @State private var missions: [Mission] = []
    @State private var selectedTab = 0
    @State private var isLoading = false
    @State private var selectedMission: Mission?
    private let dataSource: MissionDataSource = AppConfig.dataSource

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 기존 UISegmentedControl — 3개 탭
                Picker("", selection: $selectedTab) {
                    Text("Playing").tag(0)
                    Text("Near Me").tag(1)
                    Text("All").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List(missions) { mission in
                    MissionRowView(mission: mission)
                        .onTapGesture {
                            selectedMission = mission
                        }
                }
                .listStyle(.plain)
                .refreshable {
                    await loadMissions()
                }
            }
            .navigationTitle("Play Spot")
            .navigationDestination(item: $selectedMission) { mission in
                MissionDetailView(mission: mission)
            }
            .task {
                // 가상 모드 위치 오프셋이 제때 적용되도록 미션 목록 진입 시점에 미리 시작.
                // MissionPlayView가 열릴 때 awaitFirstLocation()이 즉시 반환할 수 있게 함.
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

    private func loadMissions() async {
        isLoading = true
        defer { isLoading = false }

        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        do {
            missions = try await dataSource.fetchMissionList(cursor: 0, lang: lang)
        } catch {
            print("❌ loadMissions error: \(error)")
            missions = []
        }
    }
}

#if DEBUG
#Preview("MissionList") { MissionListView() }
#endif
