// Views/MissionBuilder/ItemPickerView.swift
import SwiftUI

struct ItemPickerView: View {
    @Binding var selectedType: ItemType
    @Environment(\.dismiss) private var dismiss

    private let categories: [(String, [ItemType])] = [
        ("Mission", [.start, .end]),
        ("Quiz", [.quiz, .quiz20]),
        ("Timer", [.timeoutStart, .timeoutEnd]),
        ("Items", [.simple, .random, .solution, .coupon]),
        ("Hazards", [.mine, .mineNoBomb, .black]),
        ("Radar", [.radarAR, .radarMap, .radarAll, .radarMine]),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories, id: \.0) { category, types in
                    Section(category) {
                        ForEach(types, id: \.self) { type in
                            Button {
                                selectedType = type
                                dismiss()
                            } label: {
                                HStack {
                                    Image(type.mapIcon(mandatory: false))
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                    Text(type.displayName)
                                    Spacer()
                                    if type == selectedType {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Select Item Type")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#if DEBUG
private struct ItemPickerPreviewWrapper: View {
    @State var type: ItemType = .quiz
    var body: some View { ItemPickerView(selectedType: $type) }
}

#Preview("ItemPicker") { ItemPickerPreviewWrapper() }
#endif
