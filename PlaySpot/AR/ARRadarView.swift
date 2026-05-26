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
                // 디바이스 방향 wedge — 안쪽은 뾰족, 바깥쪽은 disc 곡률과 같은 호로 둥글게.
                // 각도 50° 로 호의 sagitta 가 ~3pt 까지 부풀어 시각적으로 명확히 둥근 모양.
                // 투명도 0.65 — disc 의 conic sweep / 동심원이 살짝 비침.
                RadarSectorWedge(radiusRatio: 0.86, angleDegrees: 50)
                    .fill(Color.white.opacity(0.65))
                    .overlay(
                        RadarSectorWedge(radiusRatio: 0.86, angleDegrees: 50)
                            .stroke(Color.duoEel2.opacity(0.45), lineWidth: 1)
                    )
                    .frame(width: discSize, height: discSize)
                    .rotationEffect(.radians(deviceBearingRadians))
                    .shadow(color: Color.white.opacity(0.35), radius: 3)

                // 최근접 필수 아이템 방향 — 기존 radar_item PNG 바늘 디자인 유지.
                // 원본 비율 9×21 유지, discSize 비례로 disc 반경의 ~89% 까지 도달.
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

// MARK: - Radar wedge shape

/// 디스크 중심에서 위로 향하는 부채꼴(pie sector).
/// 바깥 끝단이 디스크와 같은 곡률의 호(arc)로 끝나서 disc 원형과 시각적으로 일관됨.
/// 회전은 `.rotationEffect(angle)` (default anchor=.center) 으로 disc 중심 기준 회전.
private struct RadarSectorWedge: Shape {
    /// 디스크 반경 대비 wedge 외측 반경 (0…1). 0.84 → 디스크 보더 안쪽 16% 마진.
    var radiusRatio: CGFloat
    /// 꼭지각 (도). 좁을수록 needle 같음.
    var angleDegrees: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2 * radiusRatio
        let halfAngle = Double(angleDegrees) / 2
        // 12시(위)가 0°. 좌측 가장자리 → 우측 가장자리로 시계방향 호.
        let startAngle = Angle.degrees(-90 - halfAngle)
        let endAngle = Angle.degrees(-90 + halfAngle)
        p.move(to: center)
        p.addArc(center: center, radius: r,
                 startAngle: startAngle, endAngle: endAngle,
                 clockwise: false)
        p.closeSubpath()
        return p
    }
}
