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

            // 레거시 크롬: 상단 Map 버튼 + flip counter / 하단 레이더 + 상태바
            VStack {
                HStack(spacing: 8) {
                    Button {
                        onMapTapped?()
                    } label: {
                        HStack(spacing: 4) {
                            Image("UI/button_map")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 24)
                            Text("Map")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Spacer(minLength: 4)

                    flipCounter
                        .padding(.trailing, 8)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)

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

    // MARK: - 플립 카운터 (MissionPlayView와 동일 룩)

    private var flipCounter: some View {
        HStack(spacing: 2) {
            ForEach(Array(timeString.enumerated()), id: \.offset) { _, ch in
                Text(String(ch))
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(isTimeOutWarning ? .red : .white)
                    .frame(width: 18, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.black)
                            .overlay(
                                Rectangle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(height: 1)
                            )
                    )
            }
        }
    }

    private var timeString: String {
        let seconds: Int
        if engine.isTimeOutActive {
            seconds = max(0, Int(engine.remainingRunTime))
        } else {
            seconds = Int(engine.elapsedTime)
        }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d%02d%02d", h, m, s)
    }

    private var isTimeOutWarning: Bool {
        engine.isTimeOutActive && engine.remainingRunTime < 10
    }

    /// 레거시 radar_body(319x61)는 화면 전폭을 차지. Hint/유효 반경 라벨을 그 위에 겹쳐 표시.
    private var radarBar: some View {
        GeometryReader { geo in
            let scale = geo.size.width / 319.0
            let radarHeight = 61.0 * scale

            ZStack {
                Color.black.opacity(0.55)

                ARRadarView(
                    items: items,
                    itemStatuses: itemStatuses,
                    locationService: locationService,
                    suppressArrows: nearestItemIsHiddenByShowType
                )
                .frame(width: 319, height: 61)
                .scaleEffect(scale)

                HStack {
                    Text(hintDistanceText)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2)

                    Spacer()

                    Text(effectiveRangeText)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2)
                }
                .padding(.horizontal, 12)
            }
            .frame(width: geo.size.width, height: radarHeight)
        }
        .frame(height: UIScreen.main.bounds.width * 61.0 / 319.0)
    }

    /// 가장 가까운 미완료 Hint(=simple) 아이템까지의 거리 표시 (없으면 빈 문자열)
    private var hintDistanceText: String {
        guard let location = locationService.currentLocation else { return "" }
        let hint = items
            .filter { $0.itemType == .simple && itemStatuses[$0.itemID] != "Y" }
            .min(by: { location.distance(from: $0.location) < location.distance(from: $1.location) })
        guard let h = hint else { return "" }
        return "Hint:\(Int(location.distance(from: h.location)))m"
    }

    /// AR 작동 유효 반경 (레거시: 100m 고정 표시 — viewportWidthRadians 환산 대신 단순 표기)
    private var effectiveRangeText: String { "유효 반경:100m" }

    /// 레거시 ARViewController.viewportContainsCoordinate: + 가장 가까운 1개만 그리는 동작 포팅.
    /// AR 화면에는 한 번에 **1개**의 아이템만 표시되며, 그 1개는 다음 모든 조건을 통과한 후보 중 거리 최소인 항목이다.
    /// - 미획득 (`itemStatuses[id] != "Y"`)
    /// - 거리 ≤ `item.rangeAR`
    /// - `missionStarted == false` 이면 **`.start` 만** 후보 (레거시 ARViewController.m:1538 의 `else if I_START` 분기와 일치).
    ///   END 는 outer filter 통과는 가능하나 inner branch 가 START 만 minDistItem 으로 등록.
    /// - `.black` 은 항상 제외 (보이지 않음), `.mine` 은 범위 진입 시 별도 폭발 로직이라 표시 제외.
    ///   단, `.mineNoBomb`(Defence)는 후보 포함 — 레거시 ARViewController.m:1506 의 I_MINE 단독 체크 일치.
    /// - `.timeoutStart` 는 이미 타임아웃이 진행 중이면 제외
    /// - `.end` 는 아직 다른 필수 아이템이 1개 초과 남아 있으면 제외
    /// - F-4 (b): Stealth/Hidden ShowType 도 후보에 포함되며, 화면 그릴 때 `nearestItemIsHiddenByShowType`
    ///   에 따라 ARItemView 가 "Hidden" 안내 플레이스홀더로 렌더링된다 (레거시 충실).
    private var visibleItems: [MissionItem] {
        guard let nearest = nearestVisibleItem else { return [] }
        return [nearest]
    }

    /// F-4 (b): visibleItems 의 nearest 가 Stealth/Hidden + 적절한 레이더 없음 상태인가?
    /// true 일 때 ARItemView 는 "Hidden" 플레이스홀더로 그리고 ARRadarView 의 화살표를 숨긴다.
    private var nearestItemIsHiddenByShowType: Bool {
        guard let nearest = visibleItems.first else { return false }
        let hasRadarAR = engine.dicRnPTaken[ItemType.radarAR.rawValue] != nil
        let hasRadarAll = engine.dicRnPTaken[ItemType.radarAll.rawValue] != nil
        return !nearest.showType.isVisibleInAR(hasRadarAR: hasRadarAR, hasRadarAll: hasRadarAll)
    }

    private var nearestVisibleItem: MissionItem? {
        guard let location = locationService.currentLocation,
              let heading = locationService.heading else { return nil }

        let headingRadians = heading.trueHeading * .pi / 180.0
        let devicePitch = motionService.pitch - .pi / 2

        var bestItem: MissionItem?
        var bestDistance = Double.greatestFiniteMagnitude

        for item in items {
            // 미획득
            guard itemStatuses[item.itemID] != "Y" else { continue }

            // 미션 시작 전엔 start 만 후보로 허용 (레거시 ARViewController.m:1538 분기 일치).
            // END 가 더 가깝게 배치돼도 pre-start 단계에선 표시되지 않는다.
            if !engine.missionStarted, item.itemType != .start {
                continue
            }

            // F-3: 폭발 지뢰만 제외. mineNoBomb(Defence) 는 흔들기 획득 가능하게 허용.
            if item.itemType == .black || item.itemType == .mine { continue }

            // 타임아웃 중인데 또 다른 timeoutStart 표시 금지
            if item.itemType == .timeoutStart, engine.isTimeOutActive { continue }

            // end 는 다른 필수 아이템이 1개 초과 남아 있으면 숨김 (1개 = end 자신)
            if item.itemType == .end, engine.mandatoryRemaining > 1 { continue }

            // F-4 (b): Stealth/Hidden ShowType 은 후보에 포함시키되,
            // 화면 그릴 때 nearestItemIsHiddenByShowType 분기로 "Hidden" 플레이스홀더로 표시.

            // 거리/뷰포트 체크
            let coord = ARCoordinate.from(location: item.location, origin: location)
            if coord.radialDistance > Double(item.rangeAR) { continue }

            let relativeAzimuth = coord.azimuth - headingRadians
            if abs(relativeAzimuth) > viewportWidthRadians / 2 { continue }

            let relativePitch = coord.inclination - devicePitch
            if abs(relativePitch) > viewportHeightRadians / 2 { continue }

            if coord.radialDistance < bestDistance {
                bestDistance = coord.radialDistance
                bestItem = item
            }
        }

        return bestItem
    }

    /// 기존 ARViewController의 pointForCoordinate: 대체
    private func screenPosition(for item: MissionItem, in size: CGSize) -> CGPoint? {
        guard let location = locationService.currentLocation,
              let heading = locationService.heading else { return nil }

        let coord = ARCoordinate.from(location: item.location, origin: location)
        let headingRadians = heading.trueHeading * .pi / 180.0
        let relativeAzimuth = coord.azimuth - headingRadians

        // 수평 위치: 방위각 기반
        let x = size.width / 2.0 + (relativeAzimuth / viewportWidthRadians) * (size.width / 2.0)

        // 수직 위치: 기울기 기반.
        // CMDeviceMotion.attitude.pitch는 폰을 평평하게 눕히면 0, 직립(카메라 정면 응시)일 때 ≈ π/2.
        // 레거시 ARViewController는 "직립=수평선 정조준"을 0으로 다뤘으므로 π/2 만큼 빼서 정규화한다.
        let devicePitch = motionService.pitch - .pi / 2
        let y = size.height / 2.0 - (coord.inclination - devicePitch) / viewportHeightRadians * (size.height / 2.0)

        return CGPoint(x: x, y: y)
    }

    /// 기존 ARViewController의 거리 기반 스케일링
    private func scaleFactor(for item: MissionItem) -> CGFloat {
        guard let distance = locationService.distance(to: item.coordinate) else { return 1.0 }
        let scale = 1.0 - (min(distance, maximumScaleDistance) / maximumScaleDistance) * 0.7
        return CGFloat(max(scale, 0.3))
    }
}
