// AR/ARRadarView.swift — 레거시 레이더 PNG 자산 기반
import SwiftUI
import CoreLocation

/// 레거시 radianPanel/radianCenter/radianItem/radianPhone 의 candy 재해석.
/// Phase 4 redesign — 기존 radar_body(319×61) 갈색 PNG 띠 대신 64px 원형 candy 디스크 사용.
/// cross/myway/item PNG (방위각 회전) 는 보존 — 이 위에 그려진다.
struct ARRadarView: View {
    let items: [MissionItem]
    let itemStatuses: [Int: String]
    let locationService: LocationService
    /// nearest 아이템이 Stealth/Hidden + 레이더 없음 상태일 때 화살표 숨김.
    var suppressArrows: Bool = false

    private let discSize: CGFloat = 76

    var body: some View {
        ZStack {
            // Candy 디스크 — green radial + 흰 보더 + 내부 다크 stroke + 동심원 2개 + 십자선.
            ZStack {
                Circle().fill(RadialGradient.radarDisc)
                Circle().stroke(Color.white, lineWidth: 2)
                Circle().inset(by: 2).stroke(Color.black.opacity(0.35), lineWidth: 1.5)
                Circle().inset(by: discSize * 0.18).stroke(Color.white.opacity(0.35), lineWidth: 1)
                Circle().inset(by: discSize * 0.32).stroke(Color.white.opacity(0.30), lineWidth: 1)

                // 십자선 (40% opacity)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: discSize / 2))
                    p.addLine(to: CGPoint(x: discSize, y: discSize / 2))
                    p.move(to: CGPoint(x: discSize / 2, y: 0))
                    p.addLine(to: CGPoint(x: discSize / 2, y: discSize))
                }
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
            }
            .frame(width: discSize, height: discSize)

            if !suppressArrows {
                // 디바이스 방향 (radar_myway PNG, 원본 비율 28×24 유지) — discSize 비례.
                // anchor=.bottom + offset=-height/2 → 화살표 바닥이 disc 중심에 정확히 위치, 끝이 disc 반경의 ~84%.
                let mywayH = discSize * 0.42
                Image("Radar/radar_myway")
                    .resizable()
                    .aspectRatio(28.0 / 24.0, contentMode: .fit)
                    .frame(height: mywayH)
                    .rotationEffect(.radians(deviceBearingRadians), anchor: .bottom)
                    .offset(y: -mywayH / 2)

                // 최근접 필수 아이템 방향 (radar_item PNG, 원본 비율 9×21 유지) — discSize 비례.
                if let itemBearing = nearestMandatoryBearing {
                    let itemH = discSize * 0.45
                    Image("Radar/radar_item")
                        .resizable()
                        .aspectRatio(9.0 / 21.0, contentMode: .fit)
                        .frame(height: itemH)
                        .rotationEffect(.radians(itemBearing), anchor: .bottom)
                        .offset(y: -itemH / 2)
                }
            }

            // 중앙 hub (bee yellow)
            Circle().fill(Color.duoBee)
                .frame(width: 7, height: 7)
                .overlay(Circle().stroke(Color.duoEel2, lineWidth: 1.2))
                .shadow(color: Color.duoBee.opacity(0.7), radius: 3)
        }
        .frame(width: discSize, height: discSize)
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
