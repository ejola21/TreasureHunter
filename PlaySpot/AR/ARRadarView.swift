// AR/ARRadarView.swift — 레거시 레이더 PNG 자산 기반
import SwiftUI
import CoreLocation

/// 기존 ARViewController.m의 radar (radianPanel/radianCenter/radianItem/radianPhone) 재현.
/// radar_body(319x61) 위에 cross/phone/item을 겹쳐 표시.
/// phone은 디바이스 방위각, item은 가장 가까운 필수 아이템 방위각에 따라 회전.
struct ARRadarView: View {
    let items: [MissionItem]
    let itemStatuses: [Int: String]   // itemID -> "Y"/"N"
    let locationService: LocationService
    /// F-4 (b): nearest 아이템이 Stealth/Hidden + 레이더 없음 상태일 때 화살표 숨김.
    /// 레거시 ARViewController.m:1635-1636 의 `[radianItem removeFromSuperview];
    /// [radianPhone removeFromSuperview];` 와 동일.
    var suppressArrows: Bool = false

    var body: some View {
        ZStack {
            // 1) 배경 패널 (가로 띠형)
            Image("Radar/radar_body")
                .resizable()
                .frame(width: 319, height: 61)

            // 2) 중심 크로스헤어
            Image("Radar/radar_cross")
                .frame(width: 61, height: 61)

            if !suppressArrows {
                // 3) 디바이스 방향 (radar_myway) — 화면 헤딩에 따라 회전
                //    레거시 anchorPoint=(0.5, 1.0) → SwiftUI anchor: .bottom
                Image("Radar/radar_myway")
                    .frame(width: 33, height: 28)
                    .rotationEffect(.radians(deviceBearingRadians), anchor: .bottom)
                    .offset(y: -14)  // 이미지 높이의 절반만큼 위로 올려 anchor가 중심에 오도록

                // 4) 최근접 필수 아이템 방향 (radar_item)
                if let itemBearing = nearestMandatoryBearing {
                    Image("Radar/radar_item")
                        .frame(width: 11, height: 25)
                        .rotationEffect(.radians(itemBearing), anchor: .bottom)
                        .offset(y: -12.5)
                }
            }
        }
        .frame(width: 319, height: 61)
    }

    /// 디바이스 진북 방위각(라디안). heading 없으면 0.
    private var deviceBearingRadians: Double {
        guard let heading = locationService.heading else { return 0 }
        return heading.trueHeading * .pi / 180.0
    }

    /// 미완료 필수 아이템 중 가장 가까운 것까지의 상대 방위각(라디안).
    private var nearestMandatoryBearing: Double? {
        guard let location = locationService.currentLocation else { return nil }

        let active = items.filter {
            $0.isMandatory && itemStatuses[$0.itemID] != "Y"
        }
        guard !active.isEmpty else { return nil }

        let nearest = active.min(by: {
            location.distance(from: $0.location) < location.distance(from: $1.location)
        })
        guard let target = nearest else { return nil }

        return ARCoordinate.bearing(
            from: location.coordinate,
            to: target.coordinate
        )
    }
}
