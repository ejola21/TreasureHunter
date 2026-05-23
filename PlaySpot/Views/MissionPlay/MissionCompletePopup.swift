// Views/MissionPlay/MissionCompletePopup.swift
import SwiftUI

/// 미션 완료 후 리뷰 입력 팝업 — 별점(1~5) + 간단한 댓글 + 제출/건너뛰기.
/// 사용자가 별점을 선택하지 않거나 비워두고 닫아도 닫을 수 있다 (건너뛰기).
struct MissionCompletePopup: View {
    /// 별점(0 = 미선택) 과 댓글 텍스트를 전달. score==0 / reply==빈문자열 도 호출자 판단으로 처리.
    /// 닫기는 무조건 onClose 로 통일 — 호출자가 submit 처리 후 직접 dismiss.
    let onSubmit: (_ score: Int, _ reply: String) -> Void
    let onSkip: () -> Void

    @State private var rating: Int = 0
    @State private var replyText: String = ""
    @FocusState private var isReplyFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { isReplyFocused = false }

            VStack(spacing: 16) {
                Image("Auth/loginbg_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 70)

                Text("미션 완료!")
                    .font(.title2.bold())

                Text("이 미션은 어땠나요?")
                    .font(.callout)
                    .foregroundColor(.secondary)

                StarRatingPicker(rating: $rating)
                    .padding(.vertical, 4)

                ZStack(alignment: .topLeading) {
                    if replyText.isEmpty {
                        Text("간단한 한 줄 후기를 적어주세요 (선택)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                    }
                    TextEditor(text: $replyText)
                        .scrollContentBackground(.hidden)
                        .frame(height: 70)
                        .padding(4)
                        .focused($isReplyFocused)
                }
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))

                HStack(spacing: 12) {
                    Button(action: onSkip) {
                        Text("건너뛰기")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Button {
                        onSubmit(rating, replyText.trimmingCharacters(in: .whitespacesAndNewlines))
                    } label: {
                        Text("후기 남기기")
                            .font(.callout.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(rating > 0 ? Color.orange : Color.orange.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(rating == 0)
                }
                .padding(.top, 4)
            }
            .padding(20)
            .background(
                Image("UI/popup1")
                    .resizable(capInsets: EdgeInsets(top: 30, leading: 30, bottom: 30, trailing: 30),
                              resizingMode: .stretch)
            )
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
