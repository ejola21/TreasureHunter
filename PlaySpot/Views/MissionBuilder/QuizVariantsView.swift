// Views/MissionBuilder/QuizVariantsView.swift — Quiz 아이템의 변형 N개 인라인 편집
// plan_designer.md §3.2-#6 / MissionBuilderDetail.m:682-694
import SwiftUI

struct QuizVariantsView: View {
    let itemID: Int
    /// ViewModel 은 @Bindable 로 받지 않고 직접 접근 — quizzesByItem 은 @Observable 의 dict 라
    /// 변경 시 자동으로 SwiftUI 가 재평가한다.
    let viewModel: MissionBuilderViewModel

    private var variants: [ItemQuiz] {
        viewModel.quizzesByItem[itemID] ?? []
    }

    var body: some View {
        Section(header: HStack {
            Text("Quiz 변형 (\(variants.count)개)")
            Spacer()
            Button {
                viewModel.addQuizVariant(toItemID: itemID)
            } label: {
                Label("Add", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderless)
        }) {
            if variants.isEmpty {
                Text("최소 1개의 변형을 추가하세요 (필수).")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            ForEach(variants, id: \.seq) { variant in
                QuizVariantRow(itemID: itemID, seq: variant.seq, viewModel: viewModel)
            }
            .onDelete { offsets in
                for idx in offsets {
                    let seq = variants[idx].seq
                    viewModel.removeQuizVariant(itemID: itemID, seq: seq)
                }
            }
        }
    }
}

private struct QuizVariantRow: View {
    let itemID: Int
    let seq: Int
    let viewModel: MissionBuilderViewModel

    @State private var quizText: String = ""
    @State private var answerText: String = ""
    @State private var loaded = false

    private var current: ItemQuiz? {
        viewModel.quizzesByItem[itemID]?.first { $0.seq == seq }
    }

    var body: some View {
        // 변형 출제는 균등 랜덤 (QuizView.selectQuiz). probability 필드는 레거시 호환을 위해
        // 모델/DTO 에는 유지하지만 빌더 UI 에서는 노출하지 않는다 (출제 가중치로 미사용).
        VStack(alignment: .leading, spacing: 6) {
            Text("#\(seq)").font(.caption2).foregroundColor(.secondary)
            TextField("퀴즈 질문", text: $quizText, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
                .onChange(of: quizText) { _, new in
                    viewModel.updateQuizVariant(itemID: itemID, seq: seq, quiz: new)
                }
            TextField("정답", text: $answerText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: answerText) { _, new in
                    viewModel.updateQuizVariant(itemID: itemID, seq: seq, answer: new)
                }
        }
        .padding(.vertical, 4)
        .onAppear {
            guard !loaded, let c = current else { return }
            quizText = c.quiz
            answerText = c.answer
            loaded = true
        }
    }
}
