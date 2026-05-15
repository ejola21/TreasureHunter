// Views/MissionBuilder/MissionSetupView.swift
import SwiftUI

struct MissionSetupView: View {
    @State private var title = ""
    @State private var description = ""
    @State private var place = ""
    @State private var supportVirtual = true
    @Environment(\.dismiss) private var dismiss
    let mission: Mission?
    private let missionRepo = MissionRepository()

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Title", text: $title)
                    TextField("Place", text: $place)
                    Toggle("Support Virtual Mode", isOn: $supportVirtual)
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(mission == nil ? "New Mission" : "Edit Mission")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMission()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let mission {
                    title = mission.title
                    description = mission.description
                    place = mission.place
                    supportVirtual = mission.isVirtual == .virtual
                }
            }
        }
    }

    private func saveMission() {
        let id = mission?.id ?? "\(AppState.shared.userID)\(formattedDate())"
        let m = Mission(
            id: id, title: title, description: description,
            place: place, designer: AppState.shared.userID,
            status: .designing, isVirtual: supportVirtual ? .virtual : .real
        )
        try? missionRepo.save(m)
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter.string(from: Date())
    }
}

#if DEBUG
#Preview("MissionSetup - New") { MissionSetupView(mission: nil) }
#Preview("MissionSetup - Edit") { MissionSetupView(mission: .preview) }
#endif
