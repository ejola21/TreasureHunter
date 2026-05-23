# 목업 미션 데이터

모든 미션은 `Virtual=1` (가상 모드). [VirtualModeManager](PlaySpot/Game/VirtualModeManager.swift)가 start 아이템을 플레이어 현재 위치로 평행이동시키므로 좌표의 절대값보다 **아이템 간 상대 배치**가 중요.

---

# 1. 튜토리얼 미션 (tutorial001)

## 요구사항
- 미션 아이템: **start**, **end**, **게임**, **퀴즈** 4종
- **가상 모드(Virtual=1)** 일 때:
  - 플레이어가 움직이지 않아도 모든 아이템에 접근 가능
  - AR 화면에서 모든 아이템이 보임
- 우선 **목업 데이터**로 구현

## 설계 결정

### 좌표 / 배치
- Start: 기준점 (37.4850, 126.8078)
- 게임(흔들기): start 기준 **북(N, 0°) 12m**
- 퀴즈: start 기준 **동남동(ESE, 120°) 12m**
- End: start 기준 **서남서(WSW, 240°) 12m**

### "안움직이고 모든 아이템 접근 가능"
- 모든 아이템의 `RangeAR=50`. 아이템 간 최대 거리(~25m)보다 크므로 start 위치에서 어떤 아이템도 [ItemInteraction.isInRange](PlaySpot/Game/ItemInteraction.swift#L7) 통과.

### 아이템 타입 매핑
| 역할 | ItemType 코드 | ItemID |
|---|---|---|
| Start | `49` | 1 |
| 게임(흔들기) | `51` + `ItemGame=1` | 2 |
| 퀴즈 | `40` | 3 |
| End | `48` | 4 |

### 퀴즈 내용
- 문제: "대한민국의 수도는?"  답: "서울" (확률 100%)

## 파일 목록
| 파일 | 역할 |
|---|---|
| [mock_mission_tutorial001.json](PlaySpot/Resources/MockData/mock_mission_tutorial001.json) | 미션 메타데이터 |
| [mock_items_tutorial001.json](PlaySpot/Resources/MockData/mock_items_tutorial001.json) | 아이템 4개 (start/game/quiz/end) |
| [mock_quizzes_tutorial001.json](PlaySpot/Resources/MockData/mock_quizzes_tutorial001.json) | 퀴즈 데이터 (ItemID=3) |

---

# 2. 지뢰 & 레이더 미션 (mine002)

## 아이템 구성
| ItemID | 타입 코드 | 역할 | ShowType | 비고 |
|---|---|---|---|---|
| 1 | `49` Start | 미션 시작 | 4(Normal) | 기준점 (37.4860, 126.8078) |
| 2 | `55` Mine | 지뢰 | 4 | NNE(30°) 10m — 방어 아이템 없으면 최근 아이템 상실 |
| 3 | `61` mineNoBomb | 방어 | 4 | E(90°) 11m |
| 4 | `68` radarMine | 지뢰 레이더 | 4 | SSE(150°) 12m — 획득 시 지뢰 위치 지도 표시 |
| 5 | `66` radarMap | 맵 레이더 | 4 | SSW(210°) 10m — 숨겨진 아이템 지도 표시 |
| 6 | `51` simple | 힌트 (직접 획득) | 4 | W(270°) 11m |
| 7 | `48` End | 미션 종료 | 4 | NNW(330°) 12m |

## 파일 목록
| 파일 | 역할 |
|---|---|
| [mock_mission_mine002.json](PlaySpot/Resources/MockData/mock_mission_mine002.json) | 미션 메타데이터 |
| [mock_items_mine002.json](PlaySpot/Resources/MockData/mock_items_mine002.json) | 아이템 7개 |

---

# 3. 타임 런 미션 (run003)

## 아이템 구성
| ItemID | 타입 코드 | 역할 | ShowType | 비고 |
|---|---|---|---|---|
| 1 | `49` Start | 미션 시작 | 4 | 기준점 (37.4870, 126.8078) |
| 2 | `42` timeoutStart | Run Start | 4 | NE(45°) 10m — 획득 시 60초 카운트다운 시작 |
| 3 | `43` timeoutEnd | Run End | 4 | SW(225°) 13m — `RelationItemID=2`, `EffectiveTime=60` |
| 4 | `48` End | 미션 종료 | 4 | NW(315°) 12m |

## 파일 목록
| 파일 | 역할 |
|---|---|
| [mock_mission_run003.json](PlaySpot/Resources/MockData/mock_mission_run003.json) | 미션 메타데이터 |
| [mock_items_run003.json](PlaySpot/Resources/MockData/mock_items_run003.json) | 아이템 4개 |

---

# 4. 다크 존 미션 (dark004)

## 아이템 구성
| ItemID | 타입 코드 | 역할 | ShowType | 비고 |
|---|---|---|---|---|
| 1 | `49` Start | 미션 시작 | 4 | 기준점 (37.4880, 126.8078) |
| 2 | `56` black | Dark | 4 | N(0°) 10m — `RangeAR=20`, `BlackCnt=3`, `BlackTime=300` |
| 3 | `65` radarAR | 스텔스 레이더 | 4 | SSE(150°) 15m — 다크존 밖(24m 거리), AR에서 숨겨진 아이템 표시 |
| 4 | `51` simple | 힌트 | 3(Stealth) | NW(315°) 8m — 다크존 안(7m 거리), AR에서 스텔스 레이더 없이 숨겨짐 |
| 5 | `48` End | 미션 종료 | 4 | NE(60°) 14m |

## ShowType "3" (Stealth) 동작
- 지도: 항상 보임
- AR: `radarAR` 또는 `radarAll` 없으면 숨겨짐 → 스텔스 레이더 획득 후 AR에 표시

## 파일 목록
| 파일 | 역할 |
|---|---|
| [mock_mission_dark004.json](PlaySpot/Resources/MockData/mock_mission_dark004.json) | 미션 메타데이터 |
| [mock_items_dark004.json](PlaySpot/Resources/MockData/mock_items_dark004.json) | 아이템 5개 |

---

# 5. 맵 레이더 & 갬블링 미션 (gambling005)

## 아이템 구성
| ItemID | 타입 코드 | 역할 | ShowType | 비고 |
|---|---|---|---|---|
| 1 | `49` Start | 미션 시작 | 4 | 기준점 (37.4890, 126.8078) |
| 2 | `66` radarMap | 맵 레이더 | 4 | NW(315°) 10m — 획득 시 숨겨진 아이템 지도 표시 |
| 3 | `50` random | 갬블링 박스 | 2(arOnly) | E(90°) 12m — AR에서 보임, 지도에는 맵 레이더 필요 |
| 4 | `51` simple | 힌트 | 1(transparent) | SSW(210°) 10m — 지도·AR 모두 레이더 없이 숨겨짐, 갬블링으로 획득 가능 |
| 5 | `48` End | 미션 종료 | 4 | NE(45°) 14m |

## ShowType 활용 흐름
1. Start 획득 → 맵 레이더(ShowType=4)만 보임
2. 맵 레이더 획득 → 갬블링(ShowType=2, arOnly)이 지도에 표시됨
3. 갬블링 획득 → 랜덤으로 힌트(ShowType=1)를 얻을 수 있음
4. 힌트 + End 획득 → 미션 완료

## 파일 목록
| 파일 | 역할 |
|---|---|
| [mock_mission_gambling005.json](PlaySpot/Resources/MockData/mock_mission_gambling005.json) | 미션 메타데이터 |
| [mock_items_gambling005.json](PlaySpot/Resources/MockData/mock_items_gambling005.json) | 아이템 5개 |

---

# 6. 스탠다드 복합 미션 (standard006)

## 아이템 구성
| ItemID | 타입 코드 | 역할 | ShowType | 비고 |
|---|---|---|---|---|
| 1 | `49` Start | 미션 시작 | 4 | 기준점 (37.4900, 126.8078) |
| 2 | `51` simple | 힌트 (직접 획득) | 4 | N(0°) 10m — Run Start 전 힌트 획득 권장 |
| 3 | `55` Mine | 지뢰 | 4 | SE(120°) 11m |
| 4 | `42` timeoutStart | Run Start | 4 | SW(240°) 11m — 획득 시 90초 카운트다운 시작 |
| 5 | `43` timeoutEnd | Run End | 4 | NW(315°) 15m — `RelationItemID=4`, `EffectiveTime=90` |
| 6 | `48` End | 미션 종료 | 4 | NE(60°) 14m |

## 파일 목록
| 파일 | 역할 |
|---|---|
| [mock_mission_standard006.json](PlaySpot/Resources/MockData/mock_mission_standard006.json) | 미션 메타데이터 |
| [mock_items_standard006.json](PlaySpot/Resources/MockData/mock_items_standard006.json) | 아이템 6개 |

---

# 공통 설계 원칙

## 좌표 배치 규칙
- 모든 미션: 기준점(start)에서 **360° 전방향**으로 아이템 배치
- 거리: 아이템마다 8~15m 범위에서 다양하게 배치
- 방향: 각도(°)로 표기 (N=0°, E=90°, S=180°, W=270°)
- 방정식: Δlat = d × cos(θ°) / 111000, Δlon = d × sin(θ°) / 88072 (lat≈37.49°기준)

## 가상 모드 접근성
- 모든 아이템 `RangeAR=50` → start 위치에서 전체 아이템 획득 가능
- `Virtual=1` → VirtualModeManager가 start를 플레이어 현재 위치로 이동, 나머지 아이템도 동일 오프셋 적용

## 아이템 타입 코드 참조
| 코드 | 타입 | 역할 |
|---|---|---|
| `49` | start | 미션 시작 트리거 |
| `48` | end | 미션 종료 트리거 |
| `51` | simple | 힌트 / 미니게임(ItemGame≥1) |
| `40` | quiz | 퀴즈 |
| `55` | mine | 지뢰 (최근 아이템 상실) |
| `61` | mineNoBomb | 방어 (지뢰 1회 방어) |
| `68` | radarMine | 지뢰 레이더 |
| `66` | radarMap | 맵 레이더 |
| `65` | radarAR | 스텔스 레이더 |
| `42` | timeoutStart | Run Start (카운트다운 시작) |
| `43` | timeoutEnd | Run End (RelationItemID, EffectiveTime 필수) |
| `50` | random | 갬블링 (랜덤 아이템 획득) |
| `56` | black | Dark (범위 내 아이템 숨김) |

## ShowType 코드 참조
| 코드 | 이름 | 지도 | AR |
|---|---|---|---|
| `"1"` | transparent | 레이더 필요 | 레이더 필요 |
| `"2"` | arOnly | 레이더 필요 | 항상 보임 |
| `"3"` | mapOnly (Stealth) | 항상 보임 | 레이더 필요 |
| `"4"` | all (Normal) | 항상 보임 | 항상 보임 |

## 데이터 흐름
```
MissionListView → LocalDataSource.fetchMissionList()
                → mock_mission_list.json (8개 미션)

플레이 시작 → LocalDataSource.fetchMissionDetail("<id>")
            → mock_mission_<id>.json (메타)
            + mock_items_<id>.json (아이템)
            + mock_quizzes_<id>.json (퀴즈, 없으면 빈 배열)



1. ios 
SwiftUI 보통 HStack에 Picker(...).pickerStyle(.wheel)을 여러 개 

2. web
Vue 2.7 + Vant Picker

3. android
Android-PickerView