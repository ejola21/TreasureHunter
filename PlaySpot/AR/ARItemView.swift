// AR/ARItemView.swift — 기존 viewForCoordinate 대체
import SwiftUI

struct ARItemView: View {
    let item: MissionItem
    let isAcquired: Bool

    /// 레거시 ARViewController.m:1622-1638 충실: Stealth/Hidden + radar 없음 상태에서도
    /// **아이콘 자체는 그대로 그려진다** (위치는 보임). 차단되는 것은 하단 정보 라벨
    /// (`ar_clear1`/`ar_clear2`) 과 레이더 화살표뿐. 즉 "유효반경, 거리"가 안 보일 뿐
    /// "어디에 뭔가 있다"는 것은 보인다.
    /// 이 파라미터는 호환성을 위해 유지하지만 본문에서는 사용하지 않는다.
    var isHiddenByShowType: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Image(item.arIconName)
                .resizable()
                .scaledToFit()
                .frame(width: 108, height: 108)
                .opacity(isAcquired ? 0.4 : 1.0)

            if item.isMandatory {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
    }
}

#if DEBUG
#Preview("ARItem") {
    HStack(spacing: 24) {
        ARItemView(item: .preview, isAcquired: false)
        ARItemView(item: .preview, isAcquired: true)
    }
    .padding()
    .background(Color.black)
}
#endif
