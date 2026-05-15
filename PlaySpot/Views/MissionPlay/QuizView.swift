// Views/MissionPlay/QuizView.swift
import SwiftUI

struct QuizView: View {
    let item: MissionItem
    let engine: GameEngine
    @State private var userAnswer = ""
    @State private var currentQuiz: ItemQuiz?
    @State private var isCorrect: Bool?
    @State private var failCnt: Int = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let quiz = currentQuiz {
                    Text(quiz.quiz)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .padding()

                    // 레거시 QuizPlayAlert.m:113-124 — failCnt 별 힌트 표시.
                    if !hintText.isEmpty {
                        Text(hintText)
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    TextField("Answer", text: $userAnswer)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    if let isCorrect {
                        Text(isCorrect ? "Correct!" : "Wrong!")
                            .font(.headline)
                            .foregroundColor(isCorrect ? .green : .red)
                    }

                    Button("Submit") {
                        checkAnswer(quiz)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(userAnswer.isEmpty)
                } else {
                    Text("No quiz available")
                }
            }
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            failCnt = engine.quizFailCount(for: item)
            selectQuiz()
        }
    }

    /// 레거시 QuizPlayAlert.m:113-124 의 quiz_0 / quiz_1 힌트.
    /// - failCnt == 0: 힌트 없음
    /// - failCnt == 1: "정답은 N자입니다" (글자 수)
    /// - failCnt >= 2: "정답은 N자이며 첫 글자는 'X' 입니다"
    private var hintText: String {
        guard let answer = currentQuiz?.answer, !answer.isEmpty, failCnt > 0 else { return "" }
        let count = answer.count
        if failCnt == 1 || count < 2 {
            return "Hint: The answer is \(count) characters long."
        }
        let first = String(answer.prefix(1))
        return "Hint: \(count) characters, starts with '\(first)'."
    }

    private func selectQuiz() {
        let quizzes = item.quizzes
        guard !quizzes.isEmpty else { return }

        // 레거시 QuizPlayAlert.m:127 — arc4random()%count 단순 균등 랜덤.
        // probability 필드는 레거시에서도 출제 가중치로 사용 안 함 (저장만).
        currentQuiz = quizzes.randomElement()
    }

    private func checkAnswer(_ quiz: ItemQuiz) {
        // 레거시 QuizPlayAlert.m:202 — lowercase 비교만 (trim 안 함).
        // 신규 포트는 사용자 UX 향상을 위해 trim 도 적용 (의도된 차이).
        let correct = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() == quiz.answer.lowercased()
        isCorrect = correct

        if correct {
            SoundService.shared.play(.quizCorrect)
            try? engine.acquireItem(item)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
            }
        } else {
            SoundService.shared.play(.quizWrong)
            // 레거시 QuizPlayAlert.m:226-237 — failCnt += 1 + DB 저장.
            // 다음에 같은 퀴즈 재진입 시 hintText 가 활성화.
            let usedSeq = quiz.seq
            try? engine.recordQuizFailure(for: item, quizSeq: usedSeq)
            failCnt += 1
            userAnswer = ""
        }
    }
}

#if DEBUG
#Preview("Quiz") {
    QuizView(item: .preview, engine: GameEngine())
}
#endif
