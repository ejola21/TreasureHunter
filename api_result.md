# 목으로 되돌리려면
AppConfig.swift:7 한 줄을 다음으로 변경:
static let dataSource: MissionDataSource = LocalDataSource()
원하시면 두 데이터 소스를 런타임(설정 화면)에서 토글할 수 있도록 만들어드릴 수 있습니다.

# 신규 서버 (43.201.188.35:8080) 전체 연동 완료
핵심 변경 사항
# Network 레이어:

APIEndpoint.swift:5 — serverHost = "43.201.188.35:8080" 상수로 6개 URL 일괄 갱신
APIClient.swift:18-31 — POST + URL 쿼리스트링 (curl 호환), Content-Type: application/x-www-form-urlencoded + Accept: */* 헤더, 빈 본문
MissionDTO.swift — 응답 ^M[mission_arr]^I[items_arr]^Q[quizzes_arr] 구분자 처리 + Mission 배열 wrapping 대응 (기존: 인덱스 0,1,2 버그 → 수정 1,2,3)

# 모델 디코더 보강:
Mission.swift:91-104 — ISO8601(밀리초+TZ) / yyyy-MM-dd'T'HH:mm:ss / yyyy-MM-dd 3가지 날짜 포맷 모두 수용
Mission.swift:130-137 — Virtual 필드 Bool/Int 둘 다 수용 (서버가 TR=200=Int, TR=500=Bool 혼용)

# 인프라:
Info.plist:9-12 — 43.201.188.35 ATS HTTP 예외 추가
AppConfig.swift — DEBUG 빌드에서도 RemoteDataSource 사용

# 프로토콜 확장 (MissionDataSource.swift) — 6개 메서드 추가:
fetchPublishedMissions(lat, lon) (TR=501)
submitReview (TR=400)
register (tr_user_reg)
uploadMission (TR=700)
recordPlayStart/Finish/Fail (TR=c_mission_play_*)

# 탭별 라우팅 (MissionListView.swift:55-77):

Playing(0) → fetchCurrentGames (TR=602)
Near Me(1) → fetchPublishedMissions (TR=501) + GPS 좌표
All(2) → fetchMissionList (TR=500) ← 기본 탭

# GameEngine 라이프사이클 훅 (GameEngine.swift:68-100):

Start 아이템 픽업 시 c_mission_play_start (line 386)
End 아이템 픽업 + 미션 완료 시 c_mission_play_finish (line 416)
Start 없는 미션은 setup 시점에 자동 start (line 119)
페이로드: 레거시 호환 MissionID,PlayerID,ISO8601Time,IsVirtual 콤마 형식
Task.detached로 best-effort (네트워크 실패가 게임 흐름 차단 안 함)


# 검증 결과
TR	엔드포인트	시각 검증	curl 검증
200	missionDetail	✅ (mine002 → 게임 진입, 필수 아이템 5개 카운트)	✅
500	playingMissions (All)	✅ (6개 미션 표시)	✅
501	publishedMissions (Near Me)	—	✅
502	myDesigns	—	✅ (배열 반환)
503	tutorials	—	✅ (빈 배열)
600	designedCount	—	✅ (배열 반환)
601	playedCount	—	✅ (빈 배열)
602	currentGames (Playing)	✅ (빈 화면)	✅
300	missionReviews	—	✅ (빈 배열)
400	submitReview	—	(UI 미구현)
800	login	— (UI 도달)	wired
tr_user_reg	register	— (UI 도달)	wired
700	uploadMission	—	wired
c_mission_play_start	playStart	—	✅ (SUCCESS)
c_mission_play_finish	playFinish	—	✅ (SUCCESS)
c_mission_play_fail	playFail	—	✅ (SUCCESS)
c_mission_play_ranking	ranking	—	✅ (object 응답 처리)

# 알려진 데이터 이슈
mock_items_dark004.json 의 gambling005/ItemID=2 중복 — DB seed 시 제외 처리 (이전 작업)
서버 응답의 Virtual 필드 타입 일관성 없음 (TR=200=Int, TR=500=Bool) — 디코더가 둘 다 흡수
RunLimitTime 서버는 Int 초, mock JSON 은 "HH:MM:SS" 문자열 — Swift 모델은 Date? 유지하여 Int 시 nil (게임 흐름 영향 없음)