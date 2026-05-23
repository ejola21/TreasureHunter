// Game/MissionBuilderViewModel.swift — 미션 빌더 통합 상태 관리
// plan_designer.md §7.2 데이터 흐름 / §3.2 자동결정 로직 구현.
import Foundation
import SwiftUI
import CoreLocation
import os

@Observable
@MainActor
final class MissionBuilderViewModel {
    static let log = Logger(subsystem: "com.ejola.playspot", category: "BuilderVM")

    // MARK: - 상태

    /// 본 미션 — DB 저장과 호환하기 위해 기존 Mission 모델 그대로 사용. 저장 시점에 DTO 변환.
    var mission: Mission

    /// items 는 mission.items 와 분리해서 관리 (편의용 @State 바인딩 + 자동결정 로직 진입점).
    var items: [MissionItem]

    /// itemID → ItemQuiz 변형 목록 (Quiz/Quiz20 아이템 전용).
    var quizzesByItem: [Int: [ItemQuiz]]

    /// 뱃지 이미지 (업로드 전 메모리). 저장 시 dataSource.uploadBadgeImage 호출.
    var badgeImage: UIImage?
    var badgeFileName: String?     // 업로드 성공 후 받은 서버 파일명

    /// 디자인 변경 여부 (auto-save / confirm dialog 용).
    var isDirty: Bool = false

    /// Save 진행 중 ProgressView.
    var isSaving: Bool = false

    /// 마지막 save() 실패 사유 (UI alert 표시용). 성공 시 nil.
    var saveError: APIError?

    /// 가장 최근 검증 결과 — UI 인라인 에러 / 첫 항목 자동 스크롤.
    var validationErrors: [ValidationError] = []

    /// 신규 미션인지 (true=create / false=update).
    var isNewMission: Bool

    /// 데이터 소스 (DI). 기본값 AppConfig.dataSource.
    /// 빌더는 로컬 DB 를 쓰지 않고 모든 저장을 서버로 일원화한다 (로컬 draft 개념 폐기).
    let dataSource: MissionDataSource

    // MARK: - 초기화

    /// 신규 미션 생성용. 기본 status 는 비공개(unpublished) — MissionSetupView 의 공개 토글로 전환.
    init(userID: String, dataSource: MissionDataSource? = nil) {
        let tempID = "draft_\(Self.timestampID())"
        self.mission = Mission(id: tempID, designer: userID, status: .unpublished, isVirtual: .real, lang: Self.defaultLang())
        self.items = []
        self.quizzesByItem = [:]
        self.isNewMission = true
        self.dataSource = dataSource ?? AppConfig.dataSource
    }

    /// 기존 미션 편집용 (목록 → 행 탭).
    init(mission: Mission, items: [MissionItem], quizzes: [ItemQuiz],
         dataSource: MissionDataSource? = nil) {
        self.mission = mission
        self.items = items
        var byItem: [Int: [ItemQuiz]] = [:]
        for q in quizzes {
            byItem[q.itemID, default: []].append(q)
        }
        for (k, v) in byItem { byItem[k] = v.sorted { $0.seq < $1.seq } }
        self.quizzesByItem = byItem
        self.isNewMission = false
        self.dataSource = dataSource ?? AppConfig.dataSource
        // 기존 뱃지 fileName 을 보존 — 뱃지를 새로 안 바꾸고 다른 필드만 저장해도
        // PATCH 가 BadgeImageName=null 로 컬럼을 지우지 않게 함.
        self.badgeFileName = mission.badgeImageName
    }

    /// 편집 진입 시 서버 상세를 로드 중인지 (ProgressView 표시용).
    var isLoadingDetail = false

    // MARK: - 상세 로드 (편집 진입)

    /// 편집 모드 진입 시 서버에서 items / quizzes 를 가져온다.
    /// `GET /users/{id}/missions/designed` (목록) 응답은 items 가 비어 있는 slim 형태라,
    /// 편집하려면 `fetchMissionDetail` 로 상세를 따로 받아야 한다 (api_designer.md §6.3).
    /// 이게 없으면 디자인 탭 지도에 아이템이 0개로 보인다.
    func loadDetail() async {
        // 신규 미션이거나 이미 items 가 있으면(로컬 draft 등) 스킵.
        guard !isNewMission, items.isEmpty else { return }
        isLoadingDetail = true
        defer { isLoadingDetail = false }
        do {
            let (m, fetchedItems, fetchedQuizzes) = try await dataSource.fetchMissionDetail(missionID: mission.id)
            items = fetchedItems
            var byItem: [Int: [ItemQuiz]] = [:]
            for q in fetchedQuizzes { byItem[q.itemID, default: []].append(q) }
            for (k, v) in byItem { byItem[k] = v.sorted { $0.seq < $1.seq } }
            quizzesByItem = byItem
            // 메타 최신화 — designed 목록과 상세 응답의 값이 다를 수 있으므로 상세를 신뢰.
            // 단 id 는 유지 (서버 발급 ID).
            let keepID = mission.id
            mission = m
            mission.id = keepID
            // 상세에서 가져온 뱃지 파일명 — 사용자가 새로 뱃지를 안 고르더라도 유지.
            if badgeFileName == nil { badgeFileName = m.badgeImageName }
            mission.items = items
            validate()
            Self.log.info("loadDetail: \(self.mission.id, privacy: .public) items=\(self.items.count, privacy: .public)")
        } catch {
            Self.log.error("loadDetail failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - 검증

    @discardableResult
    func validate() -> [ValidationError] {
        let errs = MissionValidator.validate(
            title: mission.title,
            description: mission.description,
            items: items,
            quizzesByItem: quizzesByItem
        )
        self.validationErrors = errs
        return errs
    }

    var canSave: Bool {
        !MissionValidator.hasBlockingError(validationErrors)
    }

    // MARK: - 아이템 배치 (지도 longTap)

    /// 지도 longTap → ItemPickerView 확정 → 호출. itemID 자동 증가 + Run Start 자동 페어링.
    func placeItem(at coord: CLLocationCoordinate2D, type: ItemType,
                   showType: ShowType = .all, rangeAR: Int = 30) {
        let newID = nextItemID()
        var it = MissionItem(missionID: mission.id, itemID: newID)
        it.itemType = type
        it.latitude = coord.latitude
        it.longitude = coord.longitude
        it.showType = showType
        it.rangeAR = rangeAR
        it.mandatory = Self.defaultMandatory(for: type)
        it.info = Self.defaultInfo(for: type)
        items.append(it)

        // Run Start 배치 → Run End 자동 페어 (plan_designer.md §3.2-#4, 레거시 MissionBuilder.m:625-665)
        if type == .timeoutStart {
            let pairID = nextItemID()
            var end = MissionItem(missionID: mission.id, itemID: pairID)
            end.itemType = .timeoutEnd
            end.latitude = coord.latitude + 0.0003
            end.longitude = coord.longitude + 0.0003
            end.showType = showType
            end.rangeAR = rangeAR
            end.mandatory = .mandatory
            end.effectiveTime = 60
            end.effectiveRange = Self.distance(from: coord, to: end.coordinate)
            end.relationItemID = it.itemID
            // start.relationItemID = end.itemID
            if let idx = items.firstIndex(where: { $0.itemID == it.itemID }) {
                items[idx].relationItemID = end.itemID
            }
            items.append(end)
        }

        // Quiz 아이템 → seed 변형 1개 자동 추가
        if type == .quiz || type == .quiz20 {
            addQuizVariant(toItemID: newID)
        }

        // Start 아이템 배치 → 그 좌표로 장소(Place) 자동 채움.
        if type == .start {
            Task { await autoFillPlaceFromStart() }
        }

        isDirty = true
        validate()
    }

    /// Start 아이템 좌표를 reverseGeocode 하여 mission.place 를 자동 채운다.
    /// 사용자가 이미 장소를 직접 입력했으면 덮어쓰지 않는다.
    func autoFillPlaceFromStart() async {
        guard mission.place.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let start = items.first(where: { $0.itemType == .start }) else { return }
        let loc = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let locale = Locale(identifier: mission.lang.hasPrefix("en") ? "en_US" : "ko_KR")
        if let pm = try? await CLGeocoder().reverseGeocodeLocation(loc, preferredLocale: locale).first {
            let parts = [pm.administrativeArea, pm.locality, pm.subLocality, pm.thoroughfare].compactMap { $0 }
            let name = parts.joined(separator: " ")
            if !name.isEmpty {
                mission.place = name
                isDirty = true
            }
        }
    }

    /// 아이템 좌표 갱신 (drag).
    func moveItem(itemID: Int, to coord: CLLocationCoordinate2D) {
        guard let idx = items.firstIndex(where: { $0.itemID == itemID }) else { return }
        items[idx].latitude = coord.latitude
        items[idx].longitude = coord.longitude

        // Run Start drag → 페어 Run End 의 effectiveRange 재계산
        if items[idx].itemType == .timeoutStart,
           let endIdx = items.firstIndex(where: { $0.itemType == .timeoutEnd && $0.relationItemID == items[idx].itemID }) {
            items[endIdx].effectiveRange = Self.distance(from: items[idx].coordinate, to: items[endIdx].coordinate)
        }
        // Run End drag → 자신의 effectiveRange 재계산
        if items[idx].itemType == .timeoutEnd,
           let startItem = items.first(where: { $0.itemType == .timeoutStart && $0.itemID == items[idx].relationItemID }) {
            items[idx].effectiveRange = Self.distance(from: startItem.coordinate, to: items[idx].coordinate)
        }
        isDirty = true
        validate()
    }

    /// 아이템 삭제. Run Start 삭제 시 페어 Run End 도 함께 삭제.
    func removeItem(itemID: Int) {
        guard let target = items.first(where: { $0.itemID == itemID }) else { return }
        var toRemove: Set<Int> = [itemID]
        if target.itemType == .timeoutStart {
            if let endID = items.first(where: { $0.itemType == .timeoutEnd && $0.relationItemID == itemID })?.itemID {
                toRemove.insert(endID)
            }
        }
        if target.itemType == .timeoutEnd {
            if let startID = items.first(where: { $0.itemType == .timeoutStart && $0.itemID == target.relationItemID })?.itemID {
                toRemove.insert(startID)
            }
        }
        items.removeAll { toRemove.contains($0.itemID) }
        for id in toRemove { quizzesByItem.removeValue(forKey: id) }
        isDirty = true
        validate()
    }

    /// 아이템 필드 직접 갱신 (ItemDetailView 의 Binding 사용 후 호출).
    func updateItem(_ updated: MissionItem) {
        guard let idx = items.firstIndex(where: { $0.itemID == updated.itemID }) else { return }
        items[idx] = updated
        // Run End 의 effectiveRange 재계산 (좌표 변경 가능성)
        if updated.itemType == .timeoutEnd,
           let startItem = items.first(where: { $0.itemType == .timeoutStart && $0.itemID == updated.relationItemID }) {
            items[idx].effectiveRange = Self.distance(from: startItem.coordinate, to: updated.coordinate)
        }
        isDirty = true
        validate()
    }

    // MARK: - Quiz 변형

    /// + Add Variant — 신규 ItemQuiz 행 추가. seq 자동 부여.
    @discardableResult
    func addQuizVariant(toItemID itemID: Int) -> ItemQuiz {
        let existing = quizzesByItem[itemID] ?? []
        let nextSeq = (existing.map(\.seq).max() ?? 0) + 1
        let q = ItemQuiz(missionID: mission.id, itemID: itemID, seq: nextSeq,
                         quiz: "", answer: "", probability: 100)
        quizzesByItem[itemID, default: []].append(q)
        isDirty = true
        return q
    }

    /// 특정 ItemQuiz 갱신 (TextEditor onChange 등).
    func updateQuizVariant(itemID: Int, seq: Int, quiz: String? = nil, answer: String? = nil, probability: Int? = nil) {
        guard var list = quizzesByItem[itemID],
              let idx = list.firstIndex(where: { $0.seq == seq }) else { return }
        if let q = quiz { list[idx].quiz = q }
        if let a = answer { list[idx].answer = a }
        if let p = probability { list[idx].probability = p }
        quizzesByItem[itemID] = list
        isDirty = true
        validate()
    }

    /// Quiz 변형 삭제. seq 재정렬은 하지 않음 (gap 허용).
    func removeQuizVariant(itemID: Int, seq: Int) {
        quizzesByItem[itemID]?.removeAll { $0.seq == seq }
        isDirty = true
        validate()
    }

    // MARK: - Save (서버 저장)

    /// 검증 → (필요 시) 뱃지 업로드 → createMission or updateMission.
    /// 성공 시 서버 발급 missionID 로 mission.id 교체.
    /// 빌더의 모든 저장은 서버로 일원화 — 로컬 DB draft 는 사용하지 않는다.
    /// Status 는 사용자가 MissionSetupView 의 공개 토글로 정한 값 (`mission.status`) 을 그대로 전송한다.
    @discardableResult
    func save() async -> Bool {
        validate()
        saveError = nil
        guard canSave else {
            Self.log.warning("save() blocked by validation: \(self.validationErrors.count) errors")
            return false
        }
        isSaving = true
        defer { isSaving = false }

        // 1) 뱃지 업로드 — 사용자가 새 사진을 골랐을 때만.
        // `POST /api/v1/files/upload` 사용 — 응답의 fileUrl(전체 URL) 을 BadgeImageName 으로 저장.
        // 사진을 안 고른 경우엔 init/loadDetail() 에서 보존된 기존 badgeFileName 이 그대로 PATCH.
        if let img = badgeImage {
            // JPEG q=0.85 — PNG 대비 75-85% 크기 절감. 뱃지는 사진 기반이라 손실 압축 무손해.
            guard let jpeg = img.jpegData(compressionQuality: 0.85) else {
                Self.log.error("badge upload: jpegData() returned nil")
                saveError = .unexpected("이미지를 JPEG 로 변환하지 못했습니다.")
                return false
            }
            do {
                let uploaded = try await dataSource.uploadFile(pngData: jpeg, fileName: "badge-\(UUID().uuidString.prefix(8)).jpg")
                guard let res = uploaded, !res.fileUrl.isEmpty else {
                    Self.log.error("badge upload: server returned no fileUrl")
                    saveError = .unexpected("뱃지 업로드에 실패했어요 (서버 응답 비어 있음).")
                    return false
                }
                badgeFileName = res.fileUrl
                Self.log.info("badge uploaded: id=\(res.id ?? -1, privacy: .public) url=\(res.fileUrl, privacy: .public)")
            } catch let apiError as APIError {
                Self.log.error("badge upload APIError: \(apiError.localizedDescription, privacy: .public)")
                saveError = apiError
                return false
            } catch {
                Self.log.error("badge upload error: \(error.localizedDescription, privacy: .public)")
                saveError = .unexpected("뱃지 업로드 중 오류: \(error.localizedDescription)")
                return false
            }
        }

        // 2) DTO 변환
        let req = buildRequest()

        // 3) create / update 호출
        do {
            if isNewMission {
                let newID = try await dataSource.createMission(req)
                if !newID.isEmpty {
                    mission.id = newID
                    // items 의 missionID 도 동기화
                    for i in items.indices { items[i].missionID = newID }
                    for (k, list) in quizzesByItem {
                        quizzesByItem[k] = list.map { var q = $0; q.missionID = newID; return q }
                    }
                }
            } else {
                let ok = try await dataSource.updateMission(missionID: mission.id, req)
                if !ok { return false }
            }
            // status 는 사용자가 정한 값(mission.status) 유지 — 강제하지 않는다.
            mission.items = items
            mission.writeDate = Date()
            isDirty = false
            isNewMission = false
            return true
        } catch let apiError as APIError {
            // 신규 v1 의미적 에러 — UI 가 분기해서 안내 가능 (saveError 보존).
            saveError = apiError
            Self.log.error("save() failed: \(apiError.localizedDescription, privacy: .public)")
            return false
        } catch {
            saveError = .unexpected(error.localizedDescription)
            Self.log.error("save() failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// 외부 호출용 DTO 변환 (테스트/legacy 페이로드 양쪽 활용).
    func buildRequest() -> BuilderMissionReq {
        let fields = BuilderMissionFields(
            Title: mission.title,
            Description: mission.description,
            Place: mission.place,
            LimitTime: TimerFormatter.hms(mission.limitTime),
            Status: mission.status.rawValue,
            Virtual: mission.isVirtual == .virtual ? 1 : 0,
            Lang: mission.lang.isEmpty ? Self.defaultLang() : mission.lang,
            BadgeImageName: badgeFileName
        )
        let itemFields = items.map { it in
            BuilderItemFields(
                ItemID: it.itemID,
                Mandatory: it.isMandatory ? 1 : 0,
                ItemType: it.itemType.rawValue,
                Latitude: it.latitude,
                Longitude: it.longitude,
                BlackCnt: it.blackCnt,
                BlackTime: it.blackTime,
                RangeAR: it.rangeAR,
                ShowType: it.showType.rawValue,
                EffectiveRange: it.effectiveRange,
                EffectiveTime: it.effectiveTime,
                ItemGame: it.itemGame,
                Info: it.info,
                RelationItemID: it.relationItemID
            )
        }
        let quizFields = quizzesByItem.values.flatMap { $0 }.map {
            BuilderQuizFields(ItemID: $0.itemID, Seq: $0.seq, Quiz: $0.quiz, Answer: $0.answer, Probability: $0.probability)
        }
        return BuilderMissionReq(mission: fields, items: itemFields, quizzes: quizFields)
    }

    // MARK: - 유틸 (정적)

    /// mandatory 자동값 (plan_designer §3.2-#1/#2/#3, MissionBuilderDetail.m:442-451).
    static func defaultMandatory(for type: ItemType) -> MandatoryFlag {
        switch type {
        case .start, .end, .quiz, .quiz20, .timeoutStart, .timeoutEnd:
            return .mandatory
        case .mine, .black, .solution, .store:
            return .optional
        default:
            return .optional   // Hint/Defense/Gambling/Radar/Coupon — 사용자 선택, 기본 N
        }
    }

    /// mandatory 사용자 수정 가능 여부.
    static func canEditMandatory(for type: ItemType) -> Bool {
        switch type {
        case .start, .end, .quiz, .quiz20, .timeoutStart, .timeoutEnd,
             .mine, .black, .solution, .store:
            return false
        default:
            return true
        }
    }

    /// info / itemGame / effectiveTime 등 폼 노출 여부 분기.
    static func showsField(_ field: BuilderField, for type: ItemType) -> Bool {
        switch field {
        case .showType:       return ![.end, .mine, .black, .solution, .store].contains(type)
        case .rangeAR:        return true
        case .info:           return ![.quiz, .quiz20, .mine, .black, .solution, .store].contains(type)
        case .itemGame:       return [.simple, .mineNoBomb, .random, .solution, .coupon].contains(type)
        case .effectiveTime:  return type == .timeoutEnd
        case .effectiveRange: return type == .timeoutEnd
        case .relationItemID: return type == .timeoutStart || type == .timeoutEnd
        case .quizzes:        return type == .quiz || type == .quiz20
        }
    }

    /// 신규 미션 기본 언어 — 한국어 고정 (사용자 요청).
    /// 편집 화면 Picker 에서 다른 언어로 변경 가능.
    static func defaultLang() -> String { "ko" }

    /// itemType 별 안내 문구 기본값. 디자이너가 자주 사용하는 문장을 미리 채워둠 (item_design.md).
    static func defaultInfo(for type: ItemType) -> String {
        switch type {
        case .mineNoBomb: return "지뢰 피해를 1번 막아 드려요"
        case .random:     return "미획득 아이템 1개를 획득 할수 있어요"
        default:          return ""
        }
    }

    static func distance(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Int {
        let la = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let lb = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return Int(la.distance(from: lb).rounded())
    }

    /// "MissionID 임시 발급" 용 — userID 미사용 (Local DB save 후 서버 ID 로 교체 예정).
    static func timestampID() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMddHHmmss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date())
    }

    /// 자정 기준 Date (시:분:초만 의미) → 총 초. DatePicker(.hourMinuteAndSecond) 값 변환용.
    static func seconds(fromTimeOfDay date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        return (comps.hour ?? 0) * 3600 + (comps.minute ?? 0) * 60 + (comps.second ?? 0)
    }

    /// 총 초 → 자정 기준 Date. DatePicker 바인딩 초기값용.
    static func timeOfDay(fromSeconds s: Int) -> Date {
        Calendar.current.date(byAdding: .second, value: s, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    }

    private func nextItemID() -> Int {
        (items.map(\.itemID).max() ?? 0) + 1
    }
}

/// ItemDetailView 의 폼 분기 키.
enum BuilderField {
    case showType, rangeAR, info, itemGame, effectiveTime, effectiveRange, relationItemID, quizzes
}
