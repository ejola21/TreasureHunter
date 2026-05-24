// Views/MissionBuilder/ItemDetailView.swift — itemType 별 SubForm 으로 분기 디스패처
// plan_designer.md §7.1 — switch 분기로 16개 SubForm 호출.
import SwiftUI

struct ItemDetailView: View {
    /// 편집용 로컬 복사본. viewModel.items 를 직접 인덱싱하지 않으므로,
    /// 삭제로 배열 길이가 바뀌어도 Index out of range 크래시가 없다.
    /// "완료" 시 viewModel.updateItem 으로 반영, "삭제" 시 viewModel.removeItem 호출.
    @State private var item: MissionItem
    let viewModel: MissionBuilderViewModel
    @Environment(\.dismiss) private var dismiss

    init(item: MissionItem, viewModel: MissionBuilderViewModel) {
        _item = State(initialValue: item)
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            // 아이템 정보 — 아이콘 + 한글 이름 + 게임 내 효과 + 디자이너 배치 팁.
            // (item_design.md 기반. #코드/좌표는 사용자 요청에 따라 미표시.)
            Section("아이템 정보") {
                HStack(alignment: .top, spacing: 12) {
                    Image(item.itemType.mapIcon(mandatory: item.isMandatory))
                        .resizable().frame(width: 54, height: 54)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.itemType.displayLabel).font(.headline)
                        Text(item.itemType.detailGuide.effect)
                            .font(.callout)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                HStack(alignment: .top, spacing: 6) {
                    Text("💡").font(.callout)
                    Text(item.itemType.detailGuide.tip)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // itemType 별 SubForm 분기
            switch item.itemType {
            case .start:        StartItemForm(item: $item)
            case .end:          EndItemForm(item: $item)
            case .simple:       HintItemForm(item: $item)
            case .quiz, .quiz20: QuizItemForm(item: $item, viewModel: viewModel)
            case .timeoutStart: RunStartItemForm(item: $item)
            case .timeoutEnd:   RunEndItemForm(item: $item)
            case .mine:         MineItemForm(item: $item)
            case .black:        DarkItemForm(item: $item)
            case .mineNoBomb:   DefenseItemForm(item: $item)
            case .random:       GambleItemForm(item: $item)
            case .solution:     SolutionItemForm(item: $item)
            case .radarAR:      RadarItemForm(item: $item, title: "Stealth Radar")
            case .radarMap:     RadarItemForm(item: $item, title: "Map Radar")
            case .radarMine:    RadarItemForm(item: $item, title: "Mine Radar")
            case .coupon:       CouponItemForm(item: $item)
            case .store:        StoreItemForm(item: $item)
            default:
                Section { Text("이 아이템 유형은 빌더에서 편집할 수 없습니다.") }
            }

            Section {
                Button(role: .destructive) {
                    // dismiss 를 먼저 호출해 sheet 를 닫은 뒤 삭제 — 표시 중인 뷰가
                    // 사라진 아이템을 참조하지 않도록 한다.
                    let id = item.itemID
                    dismiss()
                    viewModel.removeItem(itemID: id)
                } label: {
                    Label("아이템 삭제", systemImage: "trash")
                }
            }
        }
        .navigationTitle("아이템 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("완료") {
                    viewModel.updateItem(item)
                    dismiss()
                }
            }
        }
    }
}

#if DEBUG
#Preview("ItemDetail") {
    NavigationStack {
        ItemDetailView(item: .preview, viewModel: MissionBuilderViewModel(userID: "preview"))
    }
}
#endif
