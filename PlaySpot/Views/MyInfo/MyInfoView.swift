// Views/MyInfo/MyInfoView.swift
import SwiftUI

struct MyInfoView: View {
    @Environment(AppState.self) var appState
    @State private var designedMissions: [Mission] = []
    @State private var playedMissions: [Mission] = []
    private let dataSource: MissionDataSource = AppConfig.dataSource

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(appState.userID)
                                .font(.headline)
                            Text(appState.isGuest ? "Guest" : "Member")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Items") {
                    LabeledContent("Solutions", value: "\(appState.solutionCount)")
                    LabeledContent("Time Add", value: "\(appState.timeAddCount)")
                }

                Section("Designed (\(designedMissions.count))") {
                    ForEach(designedMissions) { mission in
                        Text(mission.title)
                    }
                }

                Section("Played (\(playedMissions.count))") {
                    ForEach(playedMissions) { mission in
                        Text(mission.title)
                    }
                }
            }
            .navigationTitle("My Info")
            .task {
                do {
                    designedMissions = try await dataSource.fetchMyDesigned(userID: appState.userID)
                    playedMissions = try await dataSource.fetchMyPlayed(userID: appState.userID)
                } catch {}
            }
        }
    }
}

#if DEBUG
#Preview("MyInfo") {
    MyInfoView().environment(AppState.shared)
}
#endif
