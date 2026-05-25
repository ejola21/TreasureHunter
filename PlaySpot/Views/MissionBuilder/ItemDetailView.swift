// Views/MissionBuilder/ItemDetailView.swift — Item Detail v2 (Phase 5)
// 디자인: README §8 Item Detail v2 / screens-v2.jsx ScreenItemDetailV2
// 아이템 정보 카드 (ItemPin + display 이름 + 효과 설명) + 💡 yellow tip 카드 + 시스템 Form (SubForm 16개) + 삭제 CandyButton.
// SubForm 16개는 시스템 Form 디자인 유지 (변경 시 16곳을 다 수정해야 하므로 위험).
import SwiftUI

struct ItemDetailView: View {
    @State private var item: MissionItem
    let viewModel: MissionBuilderViewModel
    @Environment(\.dismiss) private var dismiss

    init(item: MissionItem, viewModel: MissionBuilderViewModel) {
        _item = State(initialValue: item)
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 아이템 정보 카드
                infoCard

                // 💡 tip 카드
                tipCard

                // SubForm — itemType 별 분기 (시스템 Form 그대로)
                formArea
                    .frame(minHeight: 360)
                    .frame(maxWidth: .infinity)

                // 삭제 버튼
                deleteButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .padding(.top, 16)
        }
        .background(Color.duoSnow.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { dismiss() }
                    .foregroundColor(.duoMacaw)
            }
            ToolbarItem(placement: .principal) {
                Text("아이템 상세")
                    .font(.duoDisplay(size: 16))
                    .foregroundColor(.duoEel2)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("완료") {
                    viewModel.updateItem(item)
                    dismiss()
                }
                .foregroundColor(.duoMacaw)
                .fontWeight(.heavy)
            }
        }
    }

    // MARK: - 카드들

    private var infoCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ItemPin(item.itemType, size: 56, active: item.isMandatory)
            VStack(alignment: .leading, spacing: 6) {
                DuoKicker(text: "Item · 아이템")
                Text(item.itemType.displayLabel)
                    .font(.duoDisplay(size: 18))
                    .foregroundColor(.duoEel2)
                Text(item.itemType.detailGuide.effect)
                    .font(.duoBody(size: 13))
                    .foregroundColor(.duoWolf2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.duoSwan2, lineWidth: 2))
        .padding(.horizontal, 16)
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("💡").font(.system(size: 18))
            Text(item.itemType.detailGuide.tip)
                .font(.duoBody(size: 12, weight: .semibold))
                .foregroundColor(.duoBeeDeep)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.duoBeeBg))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: 0xE8C878), lineWidth: 1.5)
        )
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var formArea: some View {
        Form {
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
        }
        .scrollContentBackground(.hidden)
        .background(Color.duoSnow)
    }

    private var deleteButton: some View {
        Button {
            let id = item.itemID
            dismiss()
            viewModel.removeItem(itemID: id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14, weight: .heavy))
                Text("아이템 삭제")
                    .font(.duoDisplay(size: 14))
                    .kerning(0.84)
                    .textCase(.uppercase)
            }
            .foregroundColor(.duoCardinal)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(RoundedRectangle(cornerRadius: DuoRadius.lg).fill(Color.white))
            .overlay(
                RoundedRectangle(cornerRadius: DuoRadius.lg)
                    .stroke(Color.duoCardinal, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("ItemDetail") {
    NavigationStack {
        ItemDetailView(item: .preview, viewModel: MissionBuilderViewModel(userID: "preview"))
    }
}
#endif
