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

    /// 화면 설명 오버레이 표시 여부 (상단 ? 버튼).
    @State private var showHelp = false

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

            // 상단: 투명 오버레이 (status bar 아래 36px) — 타이머 가운데, MAP 좌측
            // 하단: 흰 카드 + chip + 부유 레이더 (mockup v4)
            VStack {
                ZStack {
                    WhitePillTimer(
                        seconds: arSeconds,
                        isRunActive: isCountdownWarning
                    )
                    HStack {
                        CandyIconButton(
                            systemImage: "map.fill",
                            size: 44,
                            tint: .duoGreen500,
                            fg: .white,
                            shadowColor: .duoGreen700
                        ) {
                            onMapTapped?()
                        }
                        Spacer()
                        CandyIconButton(
                            systemImage: "questionmark",
                            size: 44,
                            tint: .duoMacaw,
                            fg: .white,
                            shadowColor: .duoHumpback
                        ) {
                            withAnimation(.easeOut(duration: 0.2)) { showHelp = true }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 36)

                Spacer()

                radarBar
                    .padding(.horizontal, 14)
                    .padding(.bottom, 18)
            }

            // 화면 설명 오버레이 (상단 ? 버튼)
            if showHelp {
                let (itemLabel, itemValue) = leftLabelValue
                let (rangeLabel, rangeValue) = rightLabelValue
                ARHelpOverlay(
                    itemKicker: itemValue.isEmpty ? itemLabel : "\(itemLabel) · \(itemValue)",
                    rangeKicker: rangeValue.isEmpty ? rangeLabel : "\(rangeLabel) · \(rangeValue)"
                ) {
                    withAnimation(.easeOut(duration: 0.2)) { showHelp = false }
                }
                .transition(.opacity)
                .zIndex(10)
            }
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

    /// 상단 타이머 표시 초. MissionPlayView.timeString 과 동일 로직 (3분기).
    ///   1) Run Start 활성 → run 카운트다운 (remainingRunTime)
    ///   2) 미션 제한시간 > 0 → 미션 카운트다운 (remainingMissionTime)
    ///   3) 그 외 → 경과시간 카운트업 (elapsedTime)
    private var arSeconds: Int {
        if engine.isTimeOutActive {
            return max(0, Int(engine.remainingRunTime))
        } else if engine.missionLimitSeconds > 0 {
            return max(0, Int(engine.remainingMissionTime))
        } else {
            return Int(engine.elapsedTime)
        }
    }

    /// 카운트다운 경고 — Run 진행 중 10초 미만 또는 미션 카운트다운 10초 미만.
    private var isCountdownWarning: Bool {
        (engine.isTimeOutActive && engine.remainingRunTime < 10)
            || (engine.missionLimitSeconds > 0
                && !engine.isTimeOutActive
                && engine.remainingMissionTime < 10)
    }

    /// 타이머 카운트다운 모드 — 빨강 강조 트리거.
    private var isCountdownMode: Bool {
        engine.isTimeOutActive || engine.missionLimitSeconds > 0
    }

    /// 하단 HUD. Stealth 아이템이 nearest 면 전용 레이아웃(글자 공간 확보 + 스텔스 레이더 강조),
    /// 그 외는 공용 RadarPillHUD (미니게임/AR Searching 와 통일).
    @ViewBuilder
    private var radarBar: some View {
        if nearestItemIsHiddenByShowType {
            stealthHUD
        } else {
            let (leftLabel, leftValue) = leftLabelValue
            let (rightLabel, rightValue) = rightLabelValue
            RadarPillHUD(
                leftLabel: leftLabel.uppercased(),
                leftValue: leftValue.isEmpty ? "—" : leftValue,
                rightLabel: rightLabel,
                rightValue: rightValue.isEmpty ? "—" : rightValue
            ) {
                ARRadarView(
                    items: items,
                    itemStatuses: itemStatuses,
                    locationService: locationService,
                    suppressArrows: false
                )
                .frame(width: 76, height: 76)
            }
        }
    }

    /// Stealth 전용 하단 HUD — 레이더(화살표 숨김) + 아이템 이름/속성 + "스텔스 레이더" 강조 안내.
    /// 좌우 분할 대신 가로 전체를 안내문에 할애해 글자가 잘리지 않음.
    private var stealthHUD: some View {
        HStack(spacing: 12) {
            ARRadarView(
                items: items,
                itemStatuses: itemStatuses,
                locationService: locationService,
                suppressArrows: true
            )
            .frame(width: 58, height: 58)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(nearestCandidateItem?.itemType.displayLabel ?? "Item")
                        .font(.duoDisplay(size: 18))
                        .foregroundColor(.duoEel2)
                        .lineLimit(1)
                    DuoChip.purple(NSLocalizedString("ar_stealth_attr", comment: ""))
                }
                stealthRotatingMessage
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
        )
    }

    /// 2.5초마다 두 문구를 교차: ①스텔스 레이더 획득 시 거리/방향 표시 ②지금도 폰을 움직여 획득.
    /// TimelineView 자체 스케줄로 토글 — AR 화면의 잦은 리렌더와 무관하게 확실히 전환.
    private var stealthRotatingMessage: some View {
        TimelineView(.periodic(from: .now, by: 2.5)) { context in
            let idx = Int(context.date.timeIntervalSinceReferenceDate / 2.5) % 2
            ZStack(alignment: .leading) {
                stealthRadarText.opacity(idx == 0 ? 1 : 0)
                stealthActionText.opacity(idx == 1 ? 1 : 0)
            }
            .animation(.easeInOut(duration: 0.35), value: idx)
        }
    }

    /// 교차 문구 ① — 스텔스 레이더(green 강조) + 획득 시 거리/방향 표시.
    private var stealthRadarText: some View {
        (
            Text(NSLocalizedString("ar_stealth_radar", comment: ""))
                .foregroundColor(.duoGreen500)
            + Text(" " + NSLocalizedString("ar_stealth_reveal", comment: ""))
                .foregroundColor(.duoWolf)
        )
        .font(.duoBody(size: 13, weight: .bold))
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// 교차 문구 ② — 지금도 폰을 움직여 거리·방향을 맞추면 획득.
    private var stealthActionText: some View {
        Text(NSLocalizedString("ar_stealth_action", comment: ""))
            .font(.duoBody(size: 13, weight: .bold))
            .foregroundColor(.duoFox)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// 좌하단 HUD (label, value) — 일반 아이템. (Stealth 는 stealthHUD 가 처리)
    /// - 후보 없음 → ("HINT", "")
    /// - 일반 → 라벨 = 아이템 타입 / 값 = 거리 (예: "Quiz" / "732m")
    private var leftLabelValue: (String, String) {
        guard let item = nearestCandidateItem,
              let location = locationService.currentLocation else { return ("HINT", "") }
        let distance = Int(location.distance(from: item.location))
        return (item.itemType.displayLabel, "\(distance)m")
    }

    /// 우하단 HUD (label, value) — 일반 아이템.
    /// - 후보 없음 → ("미션 종료!", "")
    /// - 일반 → 라벨 "Visible range" / 값 = rangeAR (예: "Visible range" / "50m")
    private var rightLabelValue: (String, String) {
        guard let item = nearestCandidateItem else {
            return (NSLocalizedString("mission_completed", comment: ""), "")
        }
        return (NSLocalizedString("radius_of_visibility", comment: ""), "\(item.rangeAR)m")
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

// MARK: - 화면 설명 오버레이 (상단 ? 버튼)

/// AR 화면 HUD 요소를 말풍선으로 가리키는 반투명 오버레이. 어디든 탭하면 닫힘.
/// 실제 HUD(타이머·레이더·START/유효반경)는 dim 너머로 비치고, 말풍선이 위에서 지목.
private struct ARHelpOverlay: View {
    /// 좌하단 HUD 의 현재 값 (예: "START · 0m") — 하드코딩 대신 실데이터 반영.
    let itemKicker: String
    /// 우하단 HUD 의 현재 값 (예: "유효 반경 · 50m").
    let rangeKicker: String
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.5).ignoresSafeArea()

            // 상단 우측 X 닫기 (타이머 줄과 정렬)
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.duoEel2)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 36)

            VStack(spacing: 16) {
                // 화면 설명 pill — 타이머 바로 아래
                Text("화면 설명")
                    .font(.duoDisplay(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.duoMacaw))
                    .padding(.top, 92)

                // Shake 안내 (좌측, 아이템 등장 영역 지목)
                HStack {
                    bubble {
                        VStack(spacing: 2) {
                            Text("아이템이 나오면")
                                .font(.duoDisplay(size: 17))
                                .foregroundColor(.duoEel2)
                            Text("Shake it!!")
                                .font(.duoDisplay(size: 28))
                                .foregroundColor(.duoCardinal)
                        }
                    }
                    Spacer()
                }

                Spacer()

                // 거리 두 개 (좌: 아이템 거리 / 우: 유효 반경) — 레이더 말풍선 바로 위.
                // kicker 는 현재 HUD 실데이터 반영 (하드코딩 제거).
                HStack(alignment: .top, spacing: 12) {
                    bubble {
                        infoContent(kicker: itemKicker,
                                    kickerColor: .duoFoxDeep,
                                    title: "아이템과 사용자\n간의 거리")
                    }
                    Spacer(minLength: 16)
                    bubble {
                        infoContent(kicker: rangeKicker,
                                    kickerColor: .duoGreen800,
                                    title: "아이템 화면\n표시 거리")
                    }
                }

                // 레이더 범례 (가운데) — 하단 레이더 디스크 지목
                bubble {
                    VStack(alignment: .leading, spacing: 12) {
                        DuoKicker(text: "레이더", color: .duoHare)
                        legendRow(icon: itemArrow, title: "노란 바늘 · 아이템 방향", sub: "ITEM")
                        legendRow(icon: phoneDisc, title: "흰색 반경 · 폰 방향", sub: "PHONE")
                    }
                }
                .padding(.bottom, 120)
            }
            .padding(.horizontal, 18)
        }
        .contentShape(Rectangle())
        .onTapGesture { onClose() }
    }

    // MARK: 말풍선 (아래로 향한 꼬리)

    private func bubble<C: View>(@ViewBuilder content: () -> C) -> some View {
        VStack(spacing: -0.5) {
            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
            DownTriangle()
                .fill(Color.white)
                .frame(width: 20, height: 11)
        }
        .shadow(color: Color.black.opacity(0.22), radius: 7, x: 0, y: 3)
    }

    private func infoContent(kicker: String, kickerColor: Color, title: String) -> some View {
        VStack(spacing: 6) {
            DuoKicker(text: kicker, color: kickerColor)
            Text(title)
                .font(.duoDisplay(size: 15))
                .foregroundColor(.duoEel2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func legendRow<Icon: View>(icon: Icon, title: String, sub: String) -> some View {
        HStack(spacing: 12) {
            icon.frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.duoDisplay(size: 15))
                    .foregroundColor(.duoEel2)
                Text(sub)
                    .font(.duoBody(size: 10, weight: .heavy))
                    .foregroundColor(.duoHare)
            }
        }
    }

    private var itemArrow: some View {
        Image(systemName: "arrow.up")
            .font(.system(size: 22, weight: .black))
            .foregroundColor(.duoBee)
    }

    private var phoneDisc: some View {
        ZStack {
            Circle().fill(Color.duoGreen500)
            // 레이더의 '폰 방향' 흰 부채꼴 (위로 향함)
            PhoneWedge()
                .fill(Color.white)
                .padding(4)
        }
    }
}

/// 말풍선 아래쪽 꼬리 삼각형.
private struct DownTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// 레이더 디스크의 '폰 방향' 흰 부채꼴 — 중심(꼭지점)에서 위(12시)로 벌어지는 wedge.
private struct PhoneWedge: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let halfWidth = rect.width * 0.34
        p.move(to: CGPoint(x: rect.midX, y: rect.midY))               // 중심 = 꼭지점
        p.addLine(to: CGPoint(x: rect.midX - halfWidth, y: rect.minY)) // 좌상
        p.addLine(to: CGPoint(x: rect.midX + halfWidth, y: rect.minY)) // 우상
        p.closeSubpath()
        return p
    }
}
