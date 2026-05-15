// Views/MissionPlay/QuizView.swift
import SwiftUI

struct QuizView: View {
    let item: MissionItem
    let engine: GameEngine
    @State private var userAnswer = ""
    @State private var currentQuiz: ItemQuiz?
    @State private var isCorrect: Bool?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let quiz = currentQuiz {
                    Text(quiz.quiz)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .padding()

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
            selectQuiz()
        }
    }

    private func selectQuiz() {
        // 기존: 확률 기반 퀴즈 선택
        let quizzes = item.quizzes
        guard !quizzes.isEmpty else { return }

        let totalProb = quizzes.reduce(0) { $0 + $1.probability }
        let random = Int.random(in: 0..<max(1, totalProb))
        var cumulative = 0
        for quiz in quizzes {
            cumulative += quiz.probability
            if random < cumulative {
                currentQuiz = quiz
                return
            }
        }
        currentQuiz = quizzes.first
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
            userAnswer = ""
        }
    }
}

#if DEBUG
#Preview("Quiz") {
    QuizView(item: .preview, engine: GameEngine())
}
#endif
