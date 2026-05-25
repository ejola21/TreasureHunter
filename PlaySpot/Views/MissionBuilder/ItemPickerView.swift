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
                toolbarHeader
                header
                wheelRow
                Spacer(minLength: 0)
            }
            .background(Color.duoSnow.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                if selectedType == nil { selectedType = .start }
            }
        }
    }

    // MARK: - 다크 toolbar (CANCEL / 라벨 / DONE)

    private var toolbarHeader: some View {
        HStack(spacing: 8) {
            Button("CANCEL") { dismiss() }
                .font(.duoDisplay(size: 11))
                .kerning(0.66)
                .foregroundColor(.white.opacity(0.85))

            Spacer()

            VStack(spacing: 0) {
                Text("ITEM · DISPLAY · VISIBLE RANGE")
                    .font(.duoDisplay(size: 9))
                    .kerning(0.5)
                    .foregroundColor(.white.opacity(0.75))
            }

            Spacer()

            Button("DONE") {
                onConfirm()
                dismiss()
            }
            .font(.duoDisplay(size: 11))
            .kerning(0.66)
            .foregroundColor(selectedType == nil ? .white.opacity(0.4) : .duoBee)
            .disabled(selectedType == nil)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: 0x3D3D3D))
    }

    // MARK: - 선택 미리보기 (candy 카드)

    private var header: some View {
        HStack(spacing: 12) {
            if let type = selectedType {
                ItemPin(type, size: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayLabel)
                        .font(.duoDisplay(size: 16))
                        .foregroundColor(.duoEel2)
                    HStack(spacing: 6) {
                        DuoChip.blue(Self.label(for: showType))
                        DuoChip.green("\(rangeAR) m")
                    }
                }
            } else {
                Text("아이템을 선택하세요")
                    .font(.duoBody(size: 14, weight: .semibold))
                    .foregroundColor(.duoHare)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white)
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
