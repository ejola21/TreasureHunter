// Views/MissionBuilder/ItemForms.swift — itemType 별 SubForm (plan_designer.md §7.1)
// ItemDetailView 가 분기해서 호출. 각 폼은 자기 타입에서 유효한 필드만 노출.
import SwiftUI

// MARK: - 공통 헬퍼
//
// 5개 입력 필드 — item_design2.md 의 새 라벨/설명 적용.
// 각 필드 한 줄 아래에 회색 caption 으로 1줄 안내 추가.

/// 발견 거리 — rangeAR Stepper (5~500 step 5).
private struct RangeARField: View {
    @Binding var item: MissionItem
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Stepper("발견 거리: \(item.rangeAR) m", value: $item.rangeAR, in: 5...500, step: 5)
            Text("AR 화면에서 아이템이 표시되는 유효 반경.")
                .font(.caption2).foregroundColor(.secondary)
        }
    }
}

/// 표시 방식 — showType Picker (Visible / Hidden / Stealth).
private struct ShowTypeField: View {
    @Binding var item: MissionItem
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Picker("표시 방식", selection: $item.showType) {
                ForEach(ShowType.selectableCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            Text(item.showType.helpText)
                .font(.caption2).foregroundColor(.secondary)
        }
    }
}

/// 미니게임 — itemGame Picker (0~3). 2·3 은 준비 중 표기.
private struct ItemGameField: View {
    @Binding var item: MissionItem
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Picker("미니게임", selection: $item.itemGame) {
                Text("없음").tag(0)
                Text("흔들기 게임").tag(1)
                Text("터치 게임 (준비 중)").tag(2)
                Text("랜덤 게임 (준비 중)").tag(3)
            }
            Text("아이템 획득 시 필요한 게임을 추가할 수 있어요.")
                .font(.caption2).foregroundColor(.secondary)
        }
    }
}

/// 안내 문구 — info TextEditor. 라벨은 itemType 별로 다를 수 있어 외부 주입.
private struct InfoField: View {
    @Binding var item: MissionItem
    var title: LocalizedStringKey = "안내 문구"
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            TextEditor(text: $item.info)
                .frame(minHeight: 80)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
            Text("아이템을 얻은 순간 알림에 보여줄 문구를 적어요.")
                .font(.caption2).foregroundColor(.secondary)
        }
    }
}

/// 필수 여부: 자동 켜짐 (편집 불가).
private struct MandatoryYReadonly: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("필수 여부").foregroundColor(.secondary)
                Spacer()
                Text("자동 — 켜짐").foregroundColor(.green)
            }
            Text("이 아이템은 미션 진행에 꼭 필요해 자동으로 필수 처리돼요.")
                .font(.caption2).foregroundColor(.secondary)
        }
    }
}

/// 필수 여부: 자동 꺼짐 (편집 불가).
private struct MandatoryNReadonly: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("필수 여부").foregroundColor(.secondary)
                Spacer()
                Text("자동 — 꺼짐").foregroundColor(.secondary)
            }
            Text("이 아이템은 미션 완료에 영향을 주지 않아요.")
                .font(.caption2).foregroundColor(.secondary)
        }
    }
}

/// 필수 여부: 사용자 선택 Toggle.
private struct MandatoryToggleField: View {
    @Binding var item: MissionItem
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Toggle("필수 여부", isOn: Binding(
                get: { item.isMandatory },
                set: { item.mandatory = $0 ? .mandatory : .optional }
            ))
            Text("미션을 끝내려면 꼭 얻어야 하는 아이템인지 정해요.")
                .font(.caption2).foregroundColor(.secondary)
        }
    }
}

// MARK: - SubForms (16개)

struct StartItemForm: View {
    @Binding var item: MissionItem
    var body: some View {
        Section("Start 아이템") {
            MandatoryYReadonly()
            ShowTypeField(item: $item)
            RangeARField(item: $item)
            InfoField(item: $item, title: "시작 안내문")
        }
    }
}

struct EndItemForm: View {
    @Binding var item: MissionItem
    var body: some View {
        Section("End 아이템") {
            MandatoryYReadonly()
            RangeARField(item: $item)
            InfoField(item: $item, title: "종료 안내문")
        }
    }
}

struct HintItemForm: View {
    @Binding var item: MissionItem
    var body: some View {
        Section("Hint 아이템") {
            MandatoryToggleField(item: $item)
            ShowTypeField(item: $item)
            RangeARField(item: $item)
            ItemGameField(item: $item)
            InfoField(item: $item, title: "힌트 텍스트")
        }
    }
}

struct QuizItemForm: View {
    @Binding var item: MissionItem
    let viewModel: MissionBuilderViewModel
    var body: some View {
        Section("Quiz 아이템") {
            MandatoryYReadonly()
            ShowTypeField(item: $item)
            RangeARField(item: $item)
        }
        QuizVariantsView(itemID: item.itemID, viewModel: viewModel)
    }
}

struct RunStartItemForm: View {
    @Binding var item: MissionItem
    var body: some View {
        Section("Run Start (타임 시작)") {
            MandatoryYReadonly()
            ShowTypeField(item: $item)
            RangeARField(item: $item)
            HStack {
                Text("페어 ID").foregroundColor(.secondary); Spacer()
                Text(item.relationItemID > 0 ? "#\(item.relationItemID)" : "—").foregroundColor(.secondary)
            }
            InfoField(item: $item)
        }
    }
}

struct RunEndItemForm: View {
    @Binding var item: MissionItem
    var body: some View {
        Section("Run End (타임 종료)") {
            MandatoryYReadonly()
            ShowTypeField(item: $item)
            RangeARField(item: $item)
            Stepper("제한 시간: \(item.effectiveTime)초",
                    value: $item.effectiveTime, in: 1...3600, step: 5)
            HStack {
                Text("거리 (자동)").foregroundColor(.secondary); Spacer()
                Text("\(item.effectiveRange) m").foregroundColor(.secondary)
            }
            HStack {
                Text("페어 ID").foregroundColor(.secondary); Spacer()
                Text(item.relationItemID > 0 ? "#\(item.relationItemID)" : "—").foregroundColor(.secondary)
            }
            InfoField(item: $item)
        }
    }
}

struct MineItemForm: View {
    @Binding var item: MissionItem
    var body: some View {
        Section("Mine (지뢰)") {
            MandatoryNReadonly()
            RangeARField(item: $item)
            Text("폭발 반경: \(item.rangeAR) m").font(.caption).foregroundColor(.orange)
        }
    }
}

struct DarkItemForm: View {
    @Binding var item: MissionItem
    var body: some View {
        Section("Dark (다크존)") {
            MandatoryNReadonly()
            RangeARField(item: $item)
            Text("다크존 반경: \(item.rangeAR) m").font(.caption).foregroundColor(.purple)
        }
    }
}

struct DefenseItemForm: View {
    @Binding var item: MissionItem
    var body: some View {
        Section("Defense (방어)") {
            MandatoryToggleField(item: $item)
            ShowTypeField(item: $item)
            RangeARField(item: $item)
            ItemGameField(item: $item)
            InfoField(item: $item)
        }
    }
}

struct GambleItemForm: View {
    @Binding var item: MissionItem
    var body: some View {
        Section("Gambling (랜덤)") {
            MandatoryToggleField(item: $item)
            ShowTypeField(item: $item)
            RangeARField(item: $item)
            ItemGameField(item: $item)
            InfoField(item: $item)
        }
    }
}

struct SolutionItemForm: View {
    @Binding var item: MissionItem
    var body: some View {
        Section("Solution (솔루션)") {
            MandatoryNReadonly()
            RangeARField(item: $item)
            ItemGameField(item: $item)
        }
    }
}

struct RadarItemForm: View {
    @Binding var item: MissionItem
    let title: LocalizedStringKey
    var body: some View {
        Section(title) {
            MandatoryToggleField(item: $item)
            ShowTypeField(item: $item)
            RangeARField(item: $item)
            InfoField(item: $item)
        }
    }
}

struct CouponItemForm: View {
    @Binding var item: MissionItem
    var body: some View {
        Section("Coupon (쿠폰)") {
            MandatoryToggleField(item: $item)
            ShowTypeField(item: $item)
            RangeARField(item: $item)
            ItemGameField(item: $item)
            InfoField(item: $item, title: "쿠폰 코드/안내문")
        }
    }
}

struct StoreItemForm: View {
    @Binding var item: MissionItem
    var body: some View {
        Section("Store (상점)") {
            MandatoryNReadonly()
            RangeARField(item: $item)
        }
    }
}
