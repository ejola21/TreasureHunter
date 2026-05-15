// Views/Components/StarRatingView.swift
import SwiftUI

struct StarRatingView: View {
    let rating: Double
    let maxStars: Int = 5
    var starSize: CGFloat = 16

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<maxStars, id: \.self) { index in
                Image(assetName(for: index))
                    .resizable()
                    .scaledToFit()
                    .frame(width: starSize, height: starSize)
            }
        }
    }

    /// 채워진 별=UI/star-gold32, 빈 별=UI/star-white32.
    /// 0.5 이상이면 채워진 별로 표시(반쪽 별은 별도 자산 없음).
    private func assetName(for index: Int) -> String {
        let threshold = Double(index) + 1
        return rating >= threshold - 0.5 ? "UI/star-gold32" : "UI/star-white32"
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
