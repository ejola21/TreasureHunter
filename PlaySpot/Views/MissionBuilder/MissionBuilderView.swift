// Views/MissionBuilder/MissionBuilderView.swift
import SwiftUI
import MapKit

struct MissionBuilderView: View {
    @State private var missions: [Mission] = []
    @State private var showCreate = false
    private let missionRepo = MissionRepository()

    var body: some View {
        NavigationStack {
            List {
                ForEach(missions) { mission in
                    NavigationLink(value: mission) {
                        VStack(alignment: .leading) {
                            Text(mission.title.isEmpty ? "Untitled" : mission.title)
                                .font(.headline)
                            Text(mission.status == .serverUpload ? "Uploaded" : "Draft")
                                .font(.caption)
                                .foregroundColor(mission.status == .serverUpload ? .green : .orange)
                        }
                    }
                }
                .onDelete { indices in
                    for index in indices {
                        try? missionRepo.delete(missionID: missions[index].id)
                    }
                    missions.remove(atOffsets: indices)
                }
            }
            .navigationTitle("My Designs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: Mission.self) { mission in
                MissionSetupView(mission: mission)
            }
            .sheet(isPresented: $showCreate) {
                MissionSetupView(mission: nil)
            }
            .onAppear {
                missions = (try? missionRepo.fetchByStatus(.serverUpload)) ?? []
            }
        }
    }
}

// Stub for builder list
struct MissionBuilderListView: View {
    var body: some View { MissionBuilderView() }
}

#if DEBUG
#Preview("MissionBuilder") { MissionBuilderView() }
#endif
