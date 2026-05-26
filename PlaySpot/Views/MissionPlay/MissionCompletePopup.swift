// Views/MissionPlay/MissionCompletePopup.swift
// Phase 4 — Candy 모달. 트로피 아이콘 + 별점 + 후기 + 건너뛰기/제출 CandyButton.
import SwiftUI

struct MissionCompletePopup: View {
    let onSubmit: (_ score: Int, _ reply: String) -> Void
    let onSkip: () -> Void
    /// false 일 때(디자인 테스트 모드) 별점/후기 입력 UI를 숨기고 확인 버튼만 보여준다.
    var allowReply: Bool = true

    @State private var rating: Int = 0
    @State private var replyText: String = ""
    @FocusState private var isReplyFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { isReplyFocused = false }

            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.duoBeeBg)
                        .frame(width: 80, height: 80)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.duoBee)
                }
                .shadow(color: Color.duoBee.opacity(0.4), radius: 12)

                DuoKicker(text: "Mission Cleared")
                Text("미션 완료!")
                    .font(.duoDisplay(size: 26))
                    .foregroundColor(.duoEel2)

                if allowReply {
                    Text("이 미션은 어땠나요?")
                        .font(.duoBody(size: 14))
                        .foregroundColor(.duoWolf2)

                    StarRatingPicker(rating: $rating)
                        .padding(.vertical, 4)

                    ZStack(alignment: .topLeading) {
                        if replyText.isEmpty {
                            Text("간단한 한 줄 후기를 적어주세요 (선택)")
                                .font(.duoBody(size: 12))
                                .foregroundColor(.duoHare)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        }
                        TextEditor(text: $replyText)
                            .scrollContentBackground(.hidden)
                            .frame(height: 70)
                            .padding(6)
                            .focused($isReplyFocused)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8).fill(Color.duoSnow)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8).stroke(Color.duoSwan2, lineWidth: 1.5)
                    )

                    HStack(spacing: 10) {
                        Button("건너뛰기", action: onSkip)
                            .buttonStyle(CandyButtonStyle(tint: .white, shadowColor: .duoSwan2))
                            .overlay(
                                Text("건너뛰기")
                                    .font(.duoDisplay(size: 14))
                                    .kerning(0.84)
                                    .textCase(.uppercase)
                                    .foregroundColor(.duoWolf)
                            )

                        Button("후기 남기기") {
                            onSubmit(rating, replyText.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                        .buttonStyle(rating > 0 ? .orange : CandyButtonStyle(tint: .duoFox.opacity(0.4), shadowColor: .duoFoxDeep.opacity(0.4)))
                        .disabled(rating == 0)
                    }
                    .padding(.top, 4)
                } else {
                    Text("디자인 테스트 플레이가 완료되었습니다.")
                        .font(.duoBody(size: 13))
                        .foregroundColor(.duoWolf2)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 4)

                    Button("확인", action: onSkip)
                        .buttonStyle(.primary)
                        .padding(.top, 4)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18).fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18).stroke(Color.duoSwan2, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 8)
            .frame(maxWidth: 340)
            .padding(.horizontal, 20)
        }
        .transition(.opacity)
    }
}

#if DEBUG
#Preview("MissionComplete") {
    MissionCompletePopup(onSubmit: { _, _ in }, onSkip: {})
}
#endif
