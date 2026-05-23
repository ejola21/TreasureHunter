// Views/Components/StarRatingView.swift
import SwiftUI

/// 읽기 전용 별점 표시 — 0.5 단위로 반쪽 별 지원.
/// SF Symbols 사용 (asset PNG 의 흰색 별이 light 배경에서 안 보이던 문제 해결).
struct StarRatingView: View {
    let rating: Double
    let maxStars: Int = 5
    var starSize: CGFloat = 16
    var fillColor: Color = .yellow

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<maxStars, id: \.self) { index in
                Image(systemName: symbolName(for: index))
                    .resizable()
                    .scaledToFit()
                    .frame(width: starSize, height: starSize)
                    .foregroundStyle(fillColor)
            }
        }
    }

    /// `index` 번째 별의 상태 — 채움 / 반쪽 / 비움.
    private func symbolName(for index: Int) -> String {
        let v = rating - Double(index)
        if v >= 0.75 { return "star.fill" }
        if v >= 0.25 { return "star.leadinghalf.filled" }
        return "star"
    }
}

#if DEBUG
#Preview("StarRating") {
    VStack(alignment: .leading, spacing: 12) {
        StarRatingView(rating: 0)
        StarRatingView(rating: 2.5)
        StarRatingView(rating: 4)
        StarRatingView(rating: 5, starSize: 28)
    }
    .padding()
}
#endif
