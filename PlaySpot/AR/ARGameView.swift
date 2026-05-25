// AR/ARGameView.swift
import SwiftUI
import AVFoundation
import CoreLocation

/// 기존 ARViewController + ARGeoViewController 통합
/// 카메라 피드 위에 아이템 오버레이를 표시하는 AR 뷰
struct ARGameView: View {
    let items: [MissionItem]
    let locationService: LocationService
    let motionService: MotionService
    let itemStatuses: [Int: String]  // itemID -> endYN
    let engine: GameEngine
    var onItemTapped: ((MissionItem) -> Void)?
    var onMapTapped: (() -> Void)?

    // 기존 뷰포트 상수
    private let viewportWidthRadians: Double = 0.5
    private let viewportHeightRadians: Double = 0.7392
    private let maximumScaleDistance: Double = 500.0

    /// 흔들기 획득 연타 방지 (레거시 getItemAnimation 0.5초 쿨다운)
    @State private var lastShakeAcquireTime: Date = .distantPast
    private let shakeAcquireCooldown: TimeInterval = 0.5

    /// AR 화면에서 mine 자동 폭발 처리 중인지 (cover 닫히는 사이 onChange 중복 발화 방지)
    @State private var mineBlastTriggered = false

    var body: some View {
        ZStack {
            // 카메라 피드
            ARCameraView()
                .ignoresSafeArea()

            // 아이템 오버레이
            GeometryReader { geometry in
                ForEach(visibleItems) { item in
                    if let position = screenPosition(for: item, in: geometry.size) {
                        ARItemView(
                            item: item,
                            isAcquired: itemStatuses[item.itemID] == "Y",
                            isHiddenByShowType: nearestItemIsHiddenByShowType
                        )
                        .position(position)
                        .scaleEffect(nearestItemIsHiddenByShowType ? 1.0 : scaleFactor(for: item))
                        .onTapGesture {
                            onItemTapped?(item)
                        }
                    }
                }
            }

            // Candy 크롬: 상단 hudTeal 그라데이션 (MAP + digit clock) / 하단 hudDark (라벨 + radar)
            VStack {
                HStack(spacing: 8) {
                    Button {
                        onMapTapped?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("MAP")
                                .font(.duoDisplay(size: 12))
                                .kerning(0.6)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.hudDarkEnd))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1.5))
                    }

                    Spacer(minLength: 4)

                    DigitClock(
                        seconds: arSeconds,
                        style: .light,
                        digitFontSize: 16,
                        digitWidth: 16,
                        digitHeight: 26
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(LinearGradient.hudTeal.ignoresSafeArea(edges: .top))

                Spacer()

                radarBar
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .onAppear {
            motionService.startUpdates()
            detectMineBlast()  // AR 진입 즉시 mine 범위 안에 있으면 폭발
        }
        .onDisappear { motionService.stopUpdates() }
        .onChange(of: motionService.isShaking) { _, shaking in
            guard shaking else { return }
            handleShake()
        }
        // 레거시 ARViewController.viewportContainsCoordinate:1232-1240 의 mine 자동 폭발 포팅.
        // 위치 픽스가 갱신될 때마다 mine 범위 진입 여부 검사.
        .onChange(of: locationService.currentLocation) { _, _ in
            detectMineBlast()
        }
    }

    /// 레거시 ARViewController: viewportContainsCoordinate 안에서 mine 의 rangeAR 안에 들어가면
    /// 자동으로 mineBlast 트리거. AR 화면에 mine 아이콘은 그리지 않지만 폭발 이벤트는 발생한다.
    private func detectMineBlast() {
        guard !mineBlastTriggered, let location = locationService.currentLocation else { return }
        for item in items {
            guard item.itemType == .mine,
                  itemStatuses[item.itemID] != "Y" else { continue }
            if location.distance(from: item.location) <= Double(item.rangeAR) {
                mineBlastTriggered = true
                // MissionPlayView.handleItemTap 의 .mineExplode 분기를 거쳐
                // engine.handleMineBlast(item:) 호출되고 AR 화면은 자동 닫힌다.
                onItemTapped?(item)
                return
            }
        }
    }

    /// 레거시 ARViewController: 흔들기 감지 시 가장 가까운 (뷰포트 내 미획득) 아이템 자동 획득.
    private func handleShake() {
        let now = Date()
        guard now.timeIntervalSince(lastShakeAcquireTime) >= shakeAcquireCooldown else { return }
        guard let location = locationService.currentLocation else { return }

        let target = visibleItems
            .filter { location.distance(from: $0.location) <= Double($0.rangeAR) }
            .min(by: { location.distance(from: $0.location) < location.distance(from: $1.location) })

        guard let item = target else { return }
        lastShakeAcquireTime = now
        onItemTapped?(item)
    }

    // MARK: - 디지트 시계 / 레이더 바 (Phase 4 candy)

    /// DigitClock 으로 전달할 초 단위 시간.
    private var arSeconds: Int {
        if engine.isTimeOutActive {
            return max(0, Int(engine.remainingRunTime))
        } else {
            return Int(engine.elapsedTime)
        }
    }

    private var isTimeOutWarning: Bool {
        engine.isTimeOutActive && engine.remainingRunTime < 10
    }

    /// 하단 HUD — hudDark 그라데이션 + 좌 라벨(Hint·거리) + 중앙 레이더(ARRadarView 기존 위젯 유지) + 우 라벨(유효 반경).
    private var radarBar: some View {
        ZStack {
            LinearGradient.hudDark
                .frame(height: 88)

            HStack(alignment: .center, spacing: 0) {
                // 좌측 정보 (방향 / 거리)
                VStack(alignment: .leading, spacing: 2) {
                    Text(nearestItemInfoText)
                        .font(.duoDisplay(size: 13))
                        .foregroundColor(.duoBee)
                        .shadow(color: .black.opacity(0.4), radius: 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)

                // 중앙 — 기존 ARRadarView (레거시 컴파스/needle) 그대로 사용. 시야각 미세 조정만.
                ARRadarView(
                    items: items,
                    itemStatuses: itemStatuses,
                    locationService: locationService,
                    suppressArrows: nearestItemIsHiddenByShowType
                )
                .frame(width: 100, height: 60)

                // 우측 정보 (유효 반경)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(effectiveRangeText)
                        .font(.duoDisplay(size: 13))
                        .foregroundColor(.duoMacaw)
                        .shadow(color: .black.opacity(0.4), radius: 2)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
            }
            .frame(height: 88)
        }
    }

    /// 좌하단 라벨 — 레거시 ar_infoView 포팅 ([`ARViewController.m:1615-1653`](Classes/ARViewController.m#L1615-L1653)).
    /// **viewport 무관** — `nearestCandidateItem` 의 displayLabel 과 거리를 항상 표시.
    /// - 후보 없음 (모든 필수 획득) → 빈 문자열 (레거시 `setTitle:@""`)
    /// - Stealth/Hidden + radar 없음 → `ar_clear1` ("Stealth disvoery!")
    /// - 일반 → `"{타입}:{거리}m"` (예: "Quiz:732m")
    private var nearestItemInfoText: String {
        guard let item = nearestCandidateItem,
              let location = locationService.currentLocation else { return "" }
        if nearestItemIsHiddenByShowType {
            return NSLocalizedString("ar_clear1", comment: "")
        }
        let distance = Int(location.distance(from: item.location))
        return "\(item.itemType.displayLabel):\(distance)m"
    }

    /// 우하단 라벨 — 레거시 ar_infoView1 포팅 ([`ARViewController.m:1615-1653`](Classes/ARViewController.m#L1615-L1653)).
    /// **viewport 무관** — `nearestCandidateItem` 의 rangeAR 항상 표시.
    /// - 후보 없음 → `mission_completed` ("미션 종료!" / "Mission Complete!")
    /// - Stealth/Hidden + radar 없음 → `ar_clear2` ("Stealth Radar needed!")
    /// - 일반 → `"{Visible range}:{rangeAR}m"`
    private var effectiveRangeText: String {
        guard let item = nearestCandidateItem else {
            return NSLocalizedString("mission_completed", comment: "")
        }
        if nearestItemIsHiddenByShowType {
            return NSLocalizedString("ar_clear2", comment: "")
        }
        return "\(NSLocalizedString("radius_of_visibility", comment: "")):\(item.rangeAR)m"
    }

    /// 레거시 ARViewController 의 `minDistItem` 선정 로직 포팅.
    /// **viewport (rangeAR/azimuth/pitch) 검사 없이** 가장 가까운 유효 후보 1개를 잡는다.
    /// 하단 라벨 / 레이더 화살표 / showType 분기는 모두 이 candidate 에 기반.
    /// 후보 자격:
    /// - 미획득 (`itemStatuses[id] != "Y"`)
    /// - `missionStarted == false` 이면 **`.start` 만** ([`ARViewController.m:1538`](Classes/ARViewController.m#L1538))
    /// - `.black`, `.mine` 영구 제외 ([`ARViewController.m:1506-1507`](Classes/ARViewController.m#L1506-L1507))
    ///   단 `.mineNoBomb`(Defense) 는 포함 (F-3 — 레거시 I_MINE 단독 제외 일치)
    /// - `.timeoutStart` 는 이미 타임아웃 진행 중이면 제외 ([`ARViewController.m:1522-1526`](Classes/ARViewController.m#L1522-L1526))
    /// - `.end` 는 다른 필수 1개 초과 남아 있으면 제외 ([`ARViewController.m:1527-1530`](Classes/ARViewController.m#L1527-L1530))
    private var nearestCandidateItem: MissionItem? {
        guard let location = locationService.currentLocation else { return nil }

        var bestItem: MissionItem?
        var bestDistance = Double.greatestFiniteMagnitude

        for item in items {
            guard itemStatuses[item.itemID] != "Y" else { continue }
            if !engine.missionStarted, item.itemType != .start { continue }
            if item.itemType == .black || item.itemType == .mine { continue }
            if item.itemType == .timeoutStart, engine.isTimeOutActive { continue }
            if item.itemType == .end, engine.mandatoryRemaining > 1 { continue }

            let distance = location.distance(from: item.location)
            if distance < bestDistance {
                bestDistance = distance
                bestItem = item
            }
        }
        return bestItem
    }

    /// 그리기 대상 — `nearestCandidateItem` 이 viewport (rangeAR + azimuth + pitch) 안에 있을 때만 1개.
    /// 레거시 [`ARViewController.m:1549-1613`](Classes/ARViewController.m#L1549-L1613) — `minDistItem` 이 viewportContainsCoordinate 통과해야 그림.
    private var visibleItems: [MissionItem] {
        guard let nearest = nearestVisibleItem else { return [] }
        return [nearest]
    }

    /// F-4 (b): nearest **candidate** 가 Stealth/Hidden + 레이더 없음 상태인가?
    /// 레거시 [`ARViewController.m:1624-1627`](Classes/ARViewController.m#L1624-L1627) 의 `minDistItem.showType` 검사.
    /// true 일 때:
    ///   - 좌하단 라벨: ar_clear1 ("Stealth disvoery!")
    ///   - 우하단 라벨: ar_clear2 ("Stealth Radar needed!")
    ///   - 레이더 화살표 (phone/item) 둘 다 숨김
    ///   - viewport 안에 들어가면 ARItemView 는 Hidden 플레이스홀더로
    private var nearestItemIsHiddenByShowType: Bool {
        guard let candidate = nearestCandidateItem else { return false }
        let hasRadarAR = engine.dicRnPTaken[ItemType.radarAR.rawValue] != nil
        let hasRadarAll = engine.dicRnPTaken[ItemType.radarAll.rawValue] != nil
        return !candidate.showType.isVisibleInAR(hasRadarAR: hasRadarAR, hasRadarAll: hasRadarAll)
    }

    private var nearestVisibleItem: MissionItem? {
        guard let candidate = nearestCandidateItem,
              let location = locationService.currentLocation else { return nil }

        let coord = ARCoordinate.from(location: candidate.location, origin: location)
        if coord.radialDistance > Double(candidate.rangeAR) { return nil }

        // pitch(수직) 검사는 의도적으로 생략.
        // 이유: ARCoordinate.from 이 inclination=0 으로 고정 (지면 평면 가정) 이라 검사 자체가 무의미.
        // 또한 CMDeviceMotion 은 시뮬레이터에서 데이터를 제공하지 않아 pitch=0 → devicePitch=-π/2 →
        // relativePitch=π/2 가 되어 모든 아이템이 항상 viewport 밖으로 판정되는 버그 유발.
        // 레거시 ARGeoCoordinate 는 altitude 차이로 실제 inclination 을 계산했지만 우리는 평면 가정이므로
        // pitch 검사 제거가 정확. 거리(rangeAR) 만으로 가시성 판정.

        // azimuth(수평) 검사: heading 이 있을 때만. 시뮬레이터에서 heading nil 이면 통과.
        if let heading = locationService.heading {
            let headingRadians = heading.trueHeading * .pi / 180.0
            let relativeAzimuth = normalizeAngle(coord.azimuth - headingRadians)
            if abs(relativeAzimuth) > viewportWidthRadians / 2 { return nil }
        }

        return candidate
    }

    /// 각도를 -π ~ π 범위로 정규화 (방위각 wrap-around 보정).
    private func normalizeAngle(_ angle: Double) -> Double {
        var a = angle
        while a > .pi { a -= 2 * .pi }
        while a < -.pi { a += 2 * .pi }
        return a
    }

    /// 기존 ARViewController의 pointForCoordinate: 대체.
    /// y(수직) 는 항상 화면 중앙에 고정 — ARCoordinate.from 이 inclination=0 (평면 가정) 이라
    /// pitch 기반 수직 위치 계산이 무의미하기 때문. 시뮬레이터 motion 누락 문제도 함께 회피.
    /// x(수평) 는 heading 있을 때 azimuth 기반, 없으면 화면 중앙.
    private func screenPosition(for item: MissionItem, in size: CGSize) -> CGPoint? {
        guard let location = locationService.currentLocation else { return nil }

        let coord = ARCoordinate.from(location: item.location, origin: location)

        let x: CGFloat
        if let heading = locationService.heading {
            let headingRadians = heading.trueHeading * .pi / 180.0
            let relativeAzimuth = normalizeAngle(coord.azimuth - headingRadians)
            x = size.width / 2.0 + CGFloat(relativeAzimuth / viewportWidthRadians) * (size.width / 2.0)
        } else {
            x = size.width / 2.0
        }
        let y = size.height / 2.0

        return CGPoint(x: x, y: y)
    }

    /// 기존 ARViewController의 거리 기반 스케일링
    private func scaleFactor(for item: MissionItem) -> CGFloat {
        guard let distance = locationService.distance(to: item.coordinate) else { return 1.0 }
        let scale = 1.0 - (min(distance, maximumScaleDistance) / maximumScaleDistance) * 0.7
        return CGFloat(max(scale, 0.3))
    }
}
