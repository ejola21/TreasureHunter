// Views/MissionBuilder/ItemDetailView.swift
import SwiftUI

struct ItemDetailView: View {
    @Binding var item: MissionItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Item Type") {
                Picker("Type", selection: $item.itemType) {
                    ForEach(ItemType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
            }

            Section("Properties") {
                Toggle("Mandatory", isOn: Binding(
                    get: { item.mandatory == .mandatory },
                    set: { item.mandatory = $0 ? .mandatory : .optional }
                ))

                Picker("Show Type", selection: $item.showType) {
                    Text("Normal").tag(ShowType.all)
                    Text("Hidden").tag(ShowType.arOnly)
                    Text("Stealth").tag(ShowType.mapOnly)
                    Text("Transparent").tag(ShowType.transparent)
                }

                Stepper("AR Range: \(item.rangeAR)m", value: $item.rangeAR, in: 5...500, step: 5)
            }

            Section("Effects") {
                Stepper("Black Count: \(item.blackCnt)", value: $item.blackCnt, in: 0...100)
                Stepper("Black Time: \(item.blackTime)s", value: $item.blackTime, in: 0...3600, step: 30)
                Stepper("Effective Range: \(item.effectiveRange)m", value: $item.effectiveRange, in: 0...1000, step: 10)
                Stepper("Effective Time: \(item.effectiveTime)s", value: $item.effectiveTime, in: 0...3600, step: 30)
            }

            Section("Info") {
                TextField("Item Info / Hint", text: $item.info)
            }
        }
        .navigationTitle("Item Detail")
    }
}

#if DEBUG
private struct ItemDetailPreviewWrapper: View {
    @State var item = MissionItem.preview
    var body: some View {
        NavigationStack { ItemDetailView(item: $item) }
    }
}

#Preview("ItemDetail") { ItemDetailPreviewWrapper() }
#endif
