// Views/MissionBuilder/ItemPickerView.swift
// 레거시 UIPickerView (3-컬럼 휠) 의 SwiftUI 재현.
// old_img/design_img/지뢰 아이템 설정배치화면.png · 미션 End 아이템 설정배치화면1.png 와 동일 레이아웃.
// 컬럼: Item · Display · Visible Range. sheet(.medium) 으로 띄워 지도가 위에 보이게 한다.
import SwiftUI

struct ItemPickerView: View {
    @Binding var selectedType: ItemType?
    @Binding var showType: ShowType
    @Binding var rangeAR: Int
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    /// 빌더에서 노출하는 itemType. timeoutEnd 는 timeoutStart 배치 시 자동 페어링되므로 picker 에는 없음.
    /// 레거시 화면 순서 (Start → End → Hint → Quiz → Gambling → Run → Mine → Defense → 레이더 → …) 유지.
    private static let pickableTypes: [ItemType] = [
        .start, .end, .simple, .quiz,
        .random, .timeoutStart,
        .mine, .black, .mineNoBomb,
        .solution, .coupon, .store,
        .radarAR, .radarMap, .radarMine,
    ]

    /// showType 라벨. showType 1(전체 숨김)은 미사용 — picker 에 노출하지 않는다.
    /// 2=AR 숨김 / 3=MAP 숨김 / 4=숨김없음 (item_design2.md).
    private static let showTypeOptions: [(ShowType, String)] = [
        (.all,     "숨김없음"),    // 4 — 지도/AR 모두 노출
        (.arOnly,  "AR 숨김"),    // 2
        (.mapOnly, "MAP 숨김"),   // 3
    ]

    /// rangeAR 프리셋 — 레거시 AppDelegate.rangeAR 동일.
    private static let rangePresets: [Int] = [10, 20, 30, 40, 50, 60, 70, 80, 100, 150, 200, 300, 500]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                Divider()
                wheelRow
                Spacer(minLength: 0)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text("Item · Display · Visible Range")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onConfirm()
                        dismiss()
                    }
                    .disabled(selectedType == nil)
                }
            }
            .onAppear {
                if selectedType == nil { selectedType = .start }
            }
        }
    }

    // MARK: - 헤더 — 선택 미리보기

    private var header: some View {
        HStack(spacing: 12) {
            if let type = selectedType {
                Image(type.mapIcon(mandatory: false))
                    .resizable().frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayLabel).font(.headline)
                    Text("#\(type.rawValue)  ·  \(Self.label(for: showType))  ·  \(rangeAR) m")
                        .font(.caption).foregroundColor(.secondary)
                }
            } else {
                Text("아이템을 선택하세요").foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal).padding(.vertical, 8)
    }

    // MARK: - 3-컬럼 휠

    private var wheelRow: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                Picker("Item", selection: Binding(
                    get: { selectedType ?? .start },
                    set: { selectedType = $0 }
                )) {
                    ForEach(Self.pickableTypes, id: \.self) { type in
                        Text(type.displayLabel).tag(type)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: proxy.size.width * 0.45)
                .clipped()

                Picker("Display", selection: $showType) {
                    ForEach(Self.showTypeOptions, id: \.0) { pair in
                        Text(pair.1).tag(pair.0)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: proxy.size.width * 0.30)
                .clipped()

                Picker("Range", selection: $rangeAR) {
                    ForEach(Self.rangePresets, id: \.self) { r in
                        Text("\(r)").tag(r)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: proxy.size.width * 0.25)
                .clipped()
            }
        }
        .frame(height: 200)
    }

    private static func label(for show: ShowType) -> String {
        showTypeOptions.first { $0.0 == show }?.1 ?? "숨김없음"
    }
}

#if DEBUG
private struct ItemPickerPreviewWrapper: View {
    @State var type: ItemType? = .mine
    @State var show: ShowType = .all
    @State var range: Int = 60
    var body: some View {
        ItemPickerView(selectedType: $type, showType: $show, rangeAR: $range) { }
    }
}

#Preview("ItemPicker (Wheel)") {
    Color.gray.opacity(0.2).ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ItemPickerPreviewWrapper()
                .presentationDetents([.medium])
        }
}
#endif
