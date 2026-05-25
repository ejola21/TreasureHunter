// Views/MissionPlay/QuizView.swift
// Phase 4 — Candy 보정. 질문 카드 + 답안 TextField + 정답/오답 피드백 + Submit CandyButton.
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
            ScrollView {
                VStack(spacing: 20) {
                    if let quiz = currentQuiz {
                        // 퀴즈 핀 + 질문 카드
                        VStack(spacing: 14) {
                            ItemPin(.quiz, size: 56)
                            DuoKicker(text: "Quiz")
                            Text(quiz.quiz)
                                .font(.duoDisplay(size: 18))
                                .foregroundColor(.duoEel2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            if !hintText.isEmpty {
                                Text(hintText)
                                    .font(.duoBody(size: 13, weight: .semibold))
                                    .foregroundColor(.duoFoxDeep)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10).fill(Color.duoFoxBg)
                                    )
                                    .padding(.horizontal)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.duoSwan2, lineWidth: 2))
                        .padding(.horizontal)

                        // 답안 입력
                        TextField("Answer", text: $userAnswer)
                            .font(.duoBody(size: 16, weight: .semibold))
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.duoSnow))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.duoSwan, lineWidth: 1.5))
                            .padding(.horizontal)

                        if let isCorrect {
                            HStack(spacing: 6) {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                Text(isCorrect ? "Correct!" : "Wrong!")
                            }
                            .font(.duoDisplay(size: 16))
                            .foregroundColor(isCorrect ? .duoGreen800 : .duoCardinalDeep)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(isCorrect ? Color.duoGreen100 : Color.duoCardinalBg))
                        }

                        Button("Submit") { checkAnswer(quiz) }
                            .buttonStyle(.primary)
                            .padding(.horizontal)
                            .disabled(userAnswer.isEmpty)
                    } else {
                        Text("No quiz available")
                            .font(.duoBody(size: 14))
                            .foregroundColor(.duoHare)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.duoSnow.ignoresSafeArea())
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
        currentQuiz = quizzes.randomElement()
    }

    private func checkAnswer(_ quiz: ItemQuiz) {
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
