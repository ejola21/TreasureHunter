// Views/MissionPlay/MissionPlayView.swift
import SwiftUI
import MapKit

struct MissionPlayView: View {
    @State private var engine = GameEngine()
    @State private var showAR = false
    @State private var showQuiz: MissionItem?
    @State private var showMiniGame: MissionItem?
    @State private var showInfo = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    let missionID: String
    let isNewStart: Bool
    let isVirtualMode: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                UserAnnotation()

                // SwiftUI Map 의 Annotation 은 ForEach 안의 `if` 조건만으로는
                // 가시성 변경을 즉시 반영하지 않을 수 있다 (annotation 캐싱).
                // filter 로 데이터 셋 자체를 줄여 강제 재렌더링.
                // 레거시 MissionPlay.m:1979-1981 의 didSelectAnnotationView 는 빈 함수 —
                // Map 핀 탭은 callout 표시 전용이고 획득은 절대 일어나지 않는다.
                // 모든 획득은 AR 화면에서만 (흔들기 / AR 아이콘 탭 / mine 자동 폭발).
                ForEach(engine.items.filter { engine.shouldShowOnMap($0) }, id: \.itemID) { item in
                    Annotation(item.itemType.displayLabel, coordinate: item.coordinate) {
                        PulseMapPin(item: item, engine: engine)
                    }
                }

                ForEach(engine.items.filter { shouldShowCircle($0) }, id: \.itemID) { item in
                    MapCircle(center: item.coordinate, radius: CLLocationDistance(item.rangeAR))
                        .foregroundStyle(circleColor(for: item).opacity(0.3))
                        .stroke(circleColor(for: item), lineWidth: 1)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                LegacyTopChrome(
                    timeString: timeString,
                    isRunActive: engine.isTimeOutActive,
                    isTimeOutWarning: isTimeWarning,
                    onExit: {
                        engine.stopTimer()
                        dismiss()
                    },
                    onRecenter: recenterCamera,
                    onInfo: { showInfo = true }
                )
                Spacer()
            }

            LegacyBottomBar(
                mineCount: engine.mineCount,
                mandatoryRemaining: engine.mandatoryRemaining,
                hiddenCount: engine.hiddenOnMapCount,
                stealthCount: engine.stealthOnARCount,
                onCamera: { showAR = true }
            )
        }
        .fullScreenCover(isPresented: $showAR) {
            ARGameView(
                items: engine.items,
                locationService: appState.locationService,
                motionService: appState.motionService,
                itemStatuses: engine.dicItemEnd,
                engine: engine,
                onItemTapped: { item in
                    showAR = false
                    handleItemTap(item)
                },
                onMapTapped: { showAR = false }
            )
        }
        .sheet(item: $showQuiz) { item in
            QuizView(item: item, engine: engine)
        }
        .sheet(item: $showMiniGame) { item in
            MiniGameView(item: item, engine: engine)
        }
        .alert("Mission Info", isPresented: $showInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(missionInfoText)
        }
        .overlay {
            if engine.missionCompleted {
                MissionCompletePopup(
                    onSubmit: { score, reply in
                        // 별점이 1점 이상이면 서버 전송 (댓글은 빈 문자열 허용).
                        // 호출 결과를 await 한 뒤 dismiss — 그래야 부모(MissionDetailView)
                        // 의 fullScreenCover onDismiss 가 새 리뷰 반영된 뒤 발화한다.
                        let mID = missionID
                        let uID = appState.userID
                        let nick = appState.userNickname
                        Task {
                            _ = try? await AppConfig.dataSource.submitReview(
                                missionID: mID,
                                userID: uID,
                                score: Float(score),
                                reply: reply
                            )
                            // 서버 GET /replies 가 아직 Nickname/WriteDate 를 안 돌려주는 동안
                            // (api_designer.md R6.1) 사용자가 본 후기에 본인 닉/시각이 보이도록
                            // 옵티미스틱 캐시에 저장. MissionDetailView 의 refreshAfterPlay() 가 이를 사용.
                            await MainActor.run {
                                ReplyOptimisticCache.shared.append(
                                    missionID: mID,
                                    reply: MissionReply(text: reply, score: Double(score),
                                                        nickname: nick.isEmpty ? nil : nick,
                                                        writeDate: Date())
                                )
                                engine.stopTimer()
                                dismiss()
                            }
                        }
                    },
                    onSkip: {
                        engine.stopTimer()
                        dismiss()
                    }
                )
            }
        }
        .overlay {
            if engine.missionTimedOut {
                MissionTimeoutPopup(elapsedText: TimerFormatter.format(engine.elapsedTime)) {
                    engine.stopTimer()
                    dismiss()
                }
            }
        }
        .overlay {
            if let alert = engine.pendingAlert {
                ItemAcquiredPopup(alert: alert) {
                    engine.dismissCurrentAlert()
                }
            }
        }
        .task {
            let loc = appState.locationService
            loc.requestPermission()
            loc.startUpdating()
            // 가상 모드: setup 전에 위치를 확보하여 setup에 직접 전달.
            // awaitFirstLocation은 Task 취소 시 즉시 nil 반환하므로 다음 플레이에 간섭 없음.
            let playerLoc: CLLocation? = isVirtualMode ? await loc.awaitFirstLocation() : nil
            try? await engine.setup(
                missionID: missionID,
                isNewStart: isNewStart,
                virtualMode: isVirtualMode,
                playerLocation: playerLoc)
            fitCameraToItems()
        }
        // 위치 갱신 시: virtual offset 재적용 + mine 자동 폭발 감지 (Map 화면에서도 동작).
        // 레거시 MissionPlay.m:1463-1473 의 locationManager:didUpdateToLocation: 포팅.
        .onChange(of: appState.locationService.currentLocation) { _, newLoc in
            guard let newLoc else { return }
            if isVirtualMode, !engine.virtualOffsetApplied,
               engine.reapplyVirtualOffsetIfNeeded() {
                fitCameraToItems()
            }
            engine.detectMineProximity(playerLocation: newLoc)
        }
    }

    private var timeString: String {
        let seconds: Int
        if engine.isTimeOutActive {
            // Run Start↔End 타임어택 구간 — 남은 시간
            seconds = max(0, Int(engine.remainingRunTime))
        } else if engine.missionLimitSeconds > 0 {
            // 미션 전체 제한 시간 — 남은 시간 카운트다운
            seconds = max(0, Int(engine.remainingMissionTime))
        } else {
            // 제한 없음 — 경과 시간
            seconds = Int(engine.elapsedTime)
        }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d%02d%02d", h, m, s)
    }

    /// 시간 표시를 빨강 경고로 — Run 구간 또는 미션 제한 시간이 10초 미만일 때.
    private var isTimeWarning: Bool {
        (engine.isTimeOutActive && engine.remainingRunTime < 10)
            || (engine.missionLimitSeconds > 0 && !engine.isTimeOutActive && engine.remainingMissionTime < 10)
    }

    private var missionInfoText: String {
        let total = engine.items.count
        let done = engine.items.filter { engine.dicItemEnd[$0.itemID] == "Y" }.count
        return "Items: \(done) / \(total)\nMode: \(isVirtualMode ? "Virtual" : "Real")"
    }

    private func handleItemTap(_ item: MissionItem) {
        guard engine.dicItemEnd[item.itemID] != "Y" else { return }
        guard let location = appState.locationService.currentLocation,
              ItemInteraction.isInRange(playerLocation: location, item: item) else { return }

        let interaction = ItemInteraction.interactionType(for: item)
        switch interaction {
        case .quiz:
            showQuiz = item
        case .miniGame:
            showMiniGame = item
        case .mineExplode:
            try? engine.handleMineBlast(item: item)
        default:
            try? engine.acquireItem(item)
        }
    }

    /// 아이템 + 사용자 위치를 감싸는 영역으로 카메라를 맞춘다.
    private func fitCameraToItems() {
        let items = engine.items
        guard !items.isEmpty else { return }

        var lats = items.map(\.latitude)
        var lons = items.map(\.longitude)
        if let user = appState.locationService.currentLocation?.coordinate {
            lats.append(user.latitude)
            lons.append(user.longitude)
        }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.002) * 1.6,
            longitudeDelta: max(maxLon - minLon, 0.002) * 1.6)
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }

    /// 현위치 버튼 — 사용자 위치 기준으로 카메라 재설정.
    private func recenterCamera() {
        guard let user = appState.locationService.currentLocation?.coordinate else {
            fitCameraToItems()
            return
        }
        cameraPosition = .region(MKCoordinateRegion(
            center: user,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)))
    }

    /// 지도에 영역 원(MapCircle)을 그릴지 판정.
    /// - 레거시 MissionPlay.m:906 은 미획득 mine 의 rangeAR 을 빨간 원으로 그리되, Mine Radar 보유 시에만 표시.
    /// - mineNoBomb(Defense)는 일반 핀 아이콘으로 표시되며 원 없음.
    /// - black(Dark)은 미획득 시 검은 원 영구 표시.
    private func shouldShowCircle(_ item: MissionItem) -> Bool {
        guard engine.dicItemEnd[item.itemID] != "Y" else { return false }
        if item.itemType == .mine {
            return engine.dicRnPTaken[ItemType.radarMine.rawValue] != nil
        }
        return item.itemType == .black
    }

    /// 레거시 MissionPlay.m:2015-2018 — black 의 circleView.fillColor 는 [UIColor blackColor] alpha 0.3.
    /// mine 은 RGBA(255,0,0) alpha 0.4 (radar 보유 시).
    private func circleColor(for item: MissionItem) -> Color {
        item.itemType == .black ? .black : .red
    }
}

// MARK: - 레거시 상단 크롬 (Exit | flip-timer | recenter | info)

private struct LegacyTopChrome: View {
    let timeString: String         // "HHMMSS" 6자리
    /// Run Start 활성 중 — flipCounter 배경을 빨간색으로 (레거시 RGBA(255,0,51,1))
    let isRunActive: Bool
    /// 10초 미만 — 텍스트 깜박임 같은 추가 경고용 (현재는 사운드만)
    let isTimeOutWarning: Bool
    let onExit: () -> Void
    let onRecenter: () -> Void
    let onInfo: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onExit) {
                Text("Exit")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.9), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.25)))
                    )
            }

            Spacer(minLength: 4)

            flipCounter

            Spacer(minLength: 4)

            Button(action: onRecenter) {
                Image("UI/button_now")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 34)
            }

            Button(action: onInfo) {
                Image("UI/button_info")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 34)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [Color(red: 0.18, green: 0.45, blue: 0.50),
                         Color(red: 0.10, green: 0.30, blue: 0.34)],
                startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea(edges: .top)
        )
    }

    /// 레거시 MissionPlay.m:622-627 — Run Start 획득 시 SBTickerView 의 backColor 가
    /// 즉시 RGBA(255,0,51,1) 빨간색으로 전환되고 일반 playTimeView 는 숨김.
    /// Swift 포트는 단일 flipCounter 의 배경만 분기 (Run 활성 시 빨강, 평상시 검정).
    private var flipCounter: some View {
        HStack(spacing: 2) {
            ForEach(Array(timeString.enumerated()), id: \.offset) { _, ch in
                Text(String(ch))
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isRunActive
                                  ? Color(red: 1.0, green: 0.0, blue: 0.2)  // RGBA(255,0,51,1)
                                  : Color.black)
                            .overlay(
                                Rectangle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(height: 1)
                            )
                    )
            }
        }
    }
}

// MARK: - 레거시 하단 상태바 (Mine | 남은필수 | (camera 갭) | Hide Map | Stealth)

private struct LegacyBottomBar: View {
    let mineCount: Int
    let mandatoryRemaining: Int
    let hiddenCount: Int
    let stealthCount: Int
    let onCamera: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            // 보라색/짙은 색 배경 바
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    counter(label: "지뢰", value: mineCount, valueColor: .red)
                    counter(label: "남은필수", value: mandatoryRemaining, valueColor: Color(red: 1.0, green: 0.50, blue: 0.30))
                    Spacer().frame(width: 72) // 카메라 버튼 자리
                    counter(label: "Hide Map", value: hiddenCount, valueColor: .white)
                    counter(label: "Stealth", value: stealthCount, valueColor: .white)
                }
                .padding(.horizontal, 4)
                .frame(height: 60)
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.20, green: 0.20, blue: 0.28),
                             Color(red: 0.08, green: 0.08, blue: 0.12)],
                    startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
            )

            // 카메라 버튼 — 바 위로 절반 정도 띄움
            Button(action: onCamera) {
                Image("UI/playAR_button")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 68, height: 68)
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
            }
            .offset(y: -22)
        }
    }

    private func counter(label: String, value: Int, valueColor: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            Text(String(format: "%03d", value))
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 아이템 획득 팝업 (모든 타입 공통)

struct ItemAcquiredPopup: View {
    let alert: ItemAcquiredAlert
    let onOK: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 0) {
                // 로고
                Image("Game/logo_noshadow")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                Divider().background(Color.gray.opacity(0.3))

                // 아이콘 + 제목
                HStack(spacing: 12) {
                    Image(alert.itemIconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)

                    Text(alert.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // 메시지
                Text(alert.message)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                Divider().background(Color.gray.opacity(0.3))

                // OK 버튼
                Button(action: onOK) {
                    Text("OK")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 40)
            .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
        }
    }
}

#if DEBUG
// MissionPlayView는 Map/Location 의존이라 Canvas에서 지도는 비어 보일 수 있음.
// 시뮬레이터(⌘R)에서 검증 권장. 여기는 컴파일 확인 + 크롬 레이아웃 미리보기 용도.
#Preview("MissionPlay") {
    MissionPlayView(missionID: "tutorial001", isNewStart: true, isVirtualMode: true)
        .environment(AppState.shared)
}
#endif

// MARK: - Map 핀 (Run End 맥동 애니메이션 지원)

/// 레거시 [`MissionPlay.m:2197-2218`](Classes/MissionPlay.m#L2197-L2218) — Run End 핀이 활성 타임어택 중에는
/// `CABasicAnimation` scale 1.5x ↔ 1.0x, 0.35초 autoreverses, 무한 반복으로 맥동.
/// 활성 타임어택 종료 시 (Run End 획득 / mine 폭발 / 시간 초과) 즉시 1.0x 로 복귀.
private struct PulseMapPin: View {
    let item: MissionItem
    let engine: GameEngine
    @State private var scale: CGFloat = 1.0

    private var shouldPulse: Bool {
        item.itemType == .timeoutEnd && engine.isTimeOutActive
    }

    var body: some View {
        Image(item.mapIconName)
            .resizable()
            .frame(width: 36, height: 36)
            .grayscale(engine.dicItemEnd[item.itemID] == "Y" ? 1.0 : 0.0)
            .scaleEffect(scale)
            .onAppear { applyAnimation() }
            .onChange(of: shouldPulse) { _, _ in applyAnimation() }
    }

    private func applyAnimation() {
        if shouldPulse {
            // 1.0 으로 set 후 즉시 1.5 로 변경하면서 repeatForever autoreverses 트리거.
            scale = 1.0
            withAnimation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true)) {
                scale = 1.5
            }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                scale = 1.0
            }
        }
    }
}
