// Views/Components/StarRatingPicker.swift
// 사용자 입력용 별점 컨트롤 — 별 1~5 탭으로 정수 점수 선택.
// SF Symbols 사용 (asset PNG 의 흰색 별이 light 배경에서 안 보이던 문제 해결).
import SwiftUI

struct StarRatingPicker: View {
    @Binding var rating: Int   // 0 ~ 5
    var maxStars: Int = 5
    var starSize: CGFloat = 32
    var fillColor: Color = .orange

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...maxStars, id: \.self) { i in
                Button {
                    rating = (rating == i) ? i - 1 : i   // 같은 별 다시 누르면 한 단계 감소
                } label: {
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .resizable()
                        .scaledToFit()
                        .frame(width: starSize, height: starSize)
                        .foregroundStyle(fillColor)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#if DEBUG
private struct StarRatingPickerPreviewWrapper: View {
    @State var rating: Int = 3
    var body: some View {
        VStack(spacing: 16) {
            StarRatingPicker(rating: $rating)
            Text("선택: \(rating) 점")
        }
        .padding()
    }
}

#Preview("StarRatingPicker") {
    StarRatingPickerPreviewWrapper()
}
#endif
