// Views/MissionPlay/MissionInfoSheet.swift
import SwiftUI

struct MissionInfoSheet: View {
    let mission: Mission
    let engine: GameEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Mission Info") {
                    LabeledContent("Title", value: mission.title)
                    LabeledContent("Place", value: mission.place)
                    LabeledContent("Designer", value: mission.designer)
                }

                Section("Progress") {
                    LabeledContent("Required Items", value: "\(engine.mandatoryRemaining) remaining")
                    LabeledContent("Mines", value: "\(engine.mineCount)")
                    LabeledContent("Hidden on Map", value: "\(engine.hiddenOnMapCount)")
                    LabeledContent("Stealth on AR", value: "\(engine.stealthOnARCount)")
                }

                Section("Power-ups") {
                    ForEach(Array(engine.dicRnPTaken.keys.sorted()), id: \.self) { key in
                        if let type = ItemType(rawValue: key) {
                            LabeledContent(String(describing: type.displayName),
                                         value: "\(engine.dicRnPTaken[key] ?? 0)")
                        }
                    }
                }
            }
            .navigationTitle("Mission Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#if DEBUG
#Preview("MissionInfo") {
    let engine = GameEngine()
    engine.mandatoryRemaining = 3
    engine.mineCount = 1
    return MissionInfoSheet(mission: .preview, engine: engine)
}
#endif
