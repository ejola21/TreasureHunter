// AR/ARItemView.swift — 기존 viewForCoordinate 대체
import SwiftUI

struct ARItemView: View {
    let item: MissionItem
    let isAcquired: Bool
    /// F-4 (b): Stealth/Hidden ShowType + 적절한 레이더가 없을 때 true.
    /// 레거시 ARViewController.m:1622-1638 의 "ar_clear1/ar_clear2" 안내 표시 흉내.
    var isHiddenByShowType: Bool = false

    var body: some View {
        if isHiddenByShowType {
            hiddenPlaceholder
        } else {
            iconBody
        }
    }

    private var iconBody: some View {
        VStack(spacing: 4) {
            Image(item.arIconName)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .opacity(isAcquired ? 0.4 : 1.0)

            if item.isMandatory {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
    }

    /// Stealth/Hidden 아이템이지만 radar 없는 상태 — 아이콘 대신 안내 플레이스홀더.
    /// 위치는 그대로 두므로 흔들기로 획득은 가능하지만 어떤 아이템인지 알 수 없음.
    private var hiddenPlaceholder: some View {
        VStack(spacing: 4) {
            Image(systemName: "questionmark.diamond.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .foregroundColor(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.6), radius: 2)

            Text("Hidden")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)

            Text("Stealth Radar required")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .background(Color.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#if DEBUG
#Preview("ARItem") {
    HStack(spacing: 24) {
        ARItemView(item: .preview, isAcquired: false)
        ARItemView(item: .preview, isAcquired: true)
        ARItemView(item: .preview, isAcquired: false, isHiddenByShowType: true)
    }
    .padding()
    .background(Color.black)
}
#endif
