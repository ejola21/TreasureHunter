# PlaySpot v8 — 모바일 화면 캡쳐 설명

> 원본: https://kornect.kr/playspot-ver8/
> 해상도: 393 × 852 (iPhone 14 Pro)
> 캡쳐 도구: Playwright MCP (Chromium)
> 캡쳐 일자: 2026-06-05

---

## 캡쳐 목록

| # | 파일 | 화면 | 설명 |
|---|---|---|---|
| 01 | `01_onboarding.png` | 온보딩 — 언어 선택 | 첫 진입. "Welcome to Seoul" 타이틀, 6개 언어 칩 (EN/KO/JA/ZH/ES/FR), Skip / Next 버튼 |
| 02 | `02_onboarding_interest.png` | 온보딩 — 관심사 선택 | "What kind of adventure?" 4개 카드 (History & Culture / Food Tour / Kids Quest / Trending Spots), "Start exploring! 🚀" |
| 03 | `03_home.png` | 홈 | 상단 마퀴 토스트, "Discover Seoul Like Never Before" 히어로, 통계 (29 Spots · 5 Tours · 15k+ Explorers · 4.9★), For You / Nearby 가로 스크롤, Guided Tours 카드 그리드 |
| 04 | `04_map.png` | 지도 (Map 탭) | Leaflet 기반 인터랙티브 지도. 스팟 핀, 카테고리 필터, 현재 위치 표시 |
| 05 | `05_tours.png` | 투어 프로그램 목록 (Tours 탭) | 7개 큐레이션 코스 (Royal Seoul / K-Culture Night / Gyeongju / Street Food / Kids / Seochon Artists / Bukchon Hanok). 카드형 |
| 06 | `06_kids.png` | Kids 탭 | 가족·어린이용 퀘스트 모음. 스탬프북 형식, 친화적 일러스트 |
| 07 | `07_rewards.png` | Rewards 탭 | 적립 포인트 + 획득 뱃지 + 시티 패스 업셀 |
| 08 | `08_rank.png` | Leaderboard | 전 세계 익스플로러 랭킹. 주간/월간 토글 가능 |
| 09 | `09_gallery.png` | Gallery | 사용자 업로드 아트워크/사진 갤러리 |
| 10 | `10_side_menu.png` | 사이드 메뉴 | 6개 언어 토글, 도시 (Seoul · 29 Spots · AR), Guided Tour Programs, Leaderboard, City Pass (₩9,900~), Creator Studio (40% 커미션) |
| 11 | `11_city_selector.png` | 도시 선택 모달 | 한국(Seoul/Busan), 영국(London), 일본(Tokyo), 프랑스(Paris), 태국(Bangkok) — "Coming soon" 락 표시 |
| 12 | `12_paywall.png` | 시티 패스 결제 | ₩9,900부터, 도시별 락 해제. AR 기능 포함 안내 |
| 13 | `13_creator.png` | 크리에이터 스튜디오 | 가이드 제작 도구. 40% 수익 분배. 미니맵 + 스텝 빌더 |
| 14 | `14_route_detail_seochon.png` | 루트 상세 (Seochon Artists' Trail) | 스팟 순서, 거리·시간 정보, 단계별 가이드, "Start route" |
| 15 | `15_spot_detail.png` | 스팟 상세 (Gyeongbokgung) | 대표 이미지, 오디오 도슨트 플레이어, AR 진입 버튼, 메뉴 카드, 거리 표시 |
| 16 | `16_ar.png` | AR 카메라 모드 | 카메라 배경 + 스캔 브래킷, "Point camera at a landmark or sticker" 가이드, 하단 AR Animation 토글 |
| 17 | `17_quest.png` | 퀴즈 미션 ("Secrets of the Joseon Throne") | 5단계 진행 바, "What does 'Gyeongbokgung' mean in English?" 4지선다 |
| 18 | `18_kids_quest.png` | 키즈 퀘스트 | 색·모양 중심 단순 미션, 어린이 친화 UI |
| 19 | `19_travel_story.png` | 여행 V로그 카드 | 오늘 다녀온 스팟 자동 콜라주, 자막 템플릿, "Save / Share" |
| 20 | `20_share_card.png` | 공유 카드 | SNS 공유용 세로형 카드, 해시태그 자동 생성 |
| 21 | `21_pref_picker.png` | 관심사 변경 모달 | 온보딩 관심사를 사후 변경 (History / Food / Kids / Trend) |

---

## 화면 분류

### 메인 네비게이션 (5 탭)
- **HOME** ([03_home.png](03_home.png))
- **MAP** ([04_map.png](04_map.png))
- **TOURS** ([05_tours.png](05_tours.png))
- **KIDS** ([06_kids.png](06_kids.png))
- **REWARDS** ([07_rewards.png](07_rewards.png))

### 보조 탭 (사이드 메뉴 경유)
- **Rank/Leaderboard** ([08_rank.png](08_rank.png))
- **Gallery** ([09_gallery.png](09_gallery.png))

### 온보딩 (2 스텝)
- 언어 ([01_onboarding.png](01_onboarding.png)) → 관심사 ([02_onboarding_interest.png](02_onboarding_interest.png))
- `OB_STEPS = 2`, `obStep` 변수로 흐름 제어

### 사이드 메뉴에서 분기 (5개)
- 언어 토글, 도시 ([11_city_selector.png](11_city_selector.png)), Tours, Leaderboard, Paywall ([12_paywall.png](12_paywall.png)), Creator ([13_creator.png](13_creator.png))

### 콘텐츠 상세 (스팟/투어/퀘스트)
- 투어 루트 ([14_route_detail_seochon.png](14_route_detail_seochon.png))
- 스팟 상세 ([15_spot_detail.png](15_spot_detail.png))
- AR 모드 ([16_ar.png](16_ar.png))
- 퀘스트 ([17_quest.png](17_quest.png))
- 키즈 퀘스트 ([18_kids_quest.png](18_kids_quest.png))

### 종료·공유
- 여행 스토리 ([19_travel_story.png](19_travel_story.png))
- 공유 카드 ([20_share_card.png](20_share_card.png))

### 설정·재설정
- 관심사 변경 ([21_pref_picker.png](21_pref_picker.png))

---

## 기술 구조 (Reverse-Engineered)

- **단일 HTML SPA** (4130 줄). `index.html` 안에 모든 화면이 `<div id="view-*">` 로 존재, `switchTab(name)` 으로 `display: none/flex` 토글
- **SPOTS** 전역 배열 — 22개 스팟 데이터 (id, name, img, cat, quest, distance)
- **TOUR_PROGRAMS** — 7개 큐레이션 코스 (`tp1`~`tp7`), `openRoute(tpId)` 로 진입
- **CITIES** — 도시별 활성화 상태 + `setCity()` 로 전환
- **언어** — `setLang(EN/KO/JA/ZH/ES/FR)`, 콘텐츠는 `t(key)` 로 i18n 변환
- **모달 패턴** — `.show` 클래스 토글 (z-index 200). `openSM/closeSM`, `openCitySelector/closeCity`, `openPaywall/closePaywall` 등 페어 함수
- **AR** — 카메라 백그라운드 이미지 + 스캔 애니메이션 (`#ar-sweep`), 정적 시뮬레이션
- **지도** — Leaflet 1.9.4, 외부 CDN (unpkg)
- **외부 의존성** — Pretendard 폰트, Google Outfit 폰트

---

## PlaySpot (자사) 디자인 참고 시 유의사항

이 사이트는 콘셉트 / 디자인 시연용 데모이며 실서비스 아님:
- 데이터는 정적 (SPOTS 22개, TOUR_PROGRAMS 7개 하드코딩)
- AR/카메라는 실제 작동 아닌 이미지 오버레이
- 결제 (Paywall) / Creator 는 UI 만, 백엔드 없음

서비스 아이디어·UX 흐름·정보 구조 참조용으로 활용 가능.
