# Flutter 클라이언트 — R3.1 신규 status 엔드포인트 통합 가이드

> 서버 신규: `PATCH /api/v1/missions/{missionId}/status` body `{"status": N}`
> 서버 전이 룰: **`0 → 1 → 2` 단방향만 허용**. 역방향 / 점프 / idempotent 모두 거부.
> iOS 측 동일 변경 완료 (참고 — [PlaySpot/Models/GameState.swift](PlaySpot/Models/GameState.swift) 외).

---

## 1. MissionStatus enum 확장 (3단계)

**기존**:
```dart
enum MissionStatus { unpublished, published }   // 값 0, 2
```

**변경**:
```dart
enum MissionStatus {
  unpublished(0),   // 편집 중 — 디자이너 본인만 보임
  testing(1),       // 테스트 완료 — 공개 대기
  published(2);     // 공개 — Missions 탭 노출. 되돌리기 불가

  final int rawValue;
  const MissionStatus(this.rawValue);

  static MissionStatus fromInt(int? v) {
    switch (v) {
      case 0: return MissionStatus.unpublished;
      case 1: return MissionStatus.testing;
      case 2: return MissionStatus.published;
      default: return MissionStatus.unpublished;   // legacy 3 등 흡수
    }
  }

  MissionStatus? get next {
    switch (this) {
      case MissionStatus.unpublished: return MissionStatus.testing;
      case MissionStatus.testing:     return MissionStatus.published;
      case MissionStatus.published:   return null;   // 더 못 올림
    }
  }
}
```

---

## 2. 신규 엔드포인트 호출 메서드

**Dio 사용 시 예**:
```dart
class MissionApi {
  final Dio dio;
  MissionApi(this.dio);

  Future<bool> updateMissionStatus(String missionId, int status) async {
    final res = await dio.patch(
      '/api/v1/missions/$missionId/status',
      data: {'status': status},
      options: Options(
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (res.statusCode == 204) return true;

    // 400 INVALID_STATE_TRANSITION / 403 FORBIDDEN / 404 NOT_FOUND
    final code = (res.data is Map) ? res.data['code'] : null;
    final msg  = (res.data is Map) ? res.data['message'] : null;
    throw MissionStatusException(
      statusCode: res.statusCode ?? 0,
      code: code,
      message: msg ?? '상태 변경 실패',
    );
  }
}
```

---

## 3. UI 흐름 변경 — Unpublish 제거 + 단방향 진행

### 기존 (잘못된 가정)
```
[비공개]  ← 토글 →  [공개]
```

### 신규 (서버 룰 반영)
```
[편집 중 0]  →  [테스트 완료 1]  →  [공개 2]
        ↑                              ↑
   "Test Pass" 액션              "Publish" 액션
   
공개 상태에서:
   → 더 이상 변경 불가 (서버가 2→0, 2→1 모두 거부)
```

### DesignActionSheet 변경

| 현재 status | 액션 라벨 | 동작 |
|---|---|---|
| `unpublished` (0) | **"Test Pass · 테스트 통과로 표시"** | `updateMissionStatus(id, 1)` |
| `testing` (1) | **"Publish · 서버 업로드"** | `updateMissionStatus(id, 2)` |
| `published` (2) | "공개됨 (변경 불가)" — **회색 / 비활성** | 액션 없음 |

### Delete 행 — 공개 상태 비활성 (기존 유지)
```
status == published → muted: 공개된 미션은 삭제할 수 없음
```

---

## 4. 디자인 목록 (내 디자인) 분류

```dart
final drafts   = missions.where((m) => m.status != MissionStatus.published).toList();
final uploaded = missions.where((m) => m.status == MissionStatus.published).toList();
```

`testing`(1) 도 drafts 섹션에 포함 (아직 Missions 탭 노출 안 됨). UI 칩으로 구분:
- 0: "비공개" 회색
- 1: "테스트 완료" 노랑
- 2: "공개" 초록

---

## 5. 에러 처리 권장

```dart
try {
  await api.updateMissionStatus(missionId, status);
  showSnack('완료되었습니다.');
} on MissionStatusException catch (e) {
  if (e.code == 'INVALID_STATE_TRANSITION') {
    showSnack('이 단계로는 변경할 수 없어요. 진행 순서를 확인하세요.');
  } else if (e.statusCode == 403) {
    showSnack('본인이 작성한 미션만 변경할 수 있어요.');
  } else if (e.statusCode == 404) {
    showSnack('미션을 찾을 수 없어요. 목록을 새로고침합니다.');
    await refreshList();
  } else {
    showSnack(e.message);
  }
}
```

---

## 6. 검증 시나리오

서버 측 (live 검증 완료, 2026-06-02):

| 시도 | 응답 |
|---|---|
| `PATCH /status {status:1}` (현재 0) | **204** ✅ |
| `PATCH /status {status:2}` (현재 1) | **204** ✅ |
| `PATCH /status {status:0}` (현재 2) | **400** `INVALID_STATE_TRANSITION` |
| `PATCH /status {status:2}` (현재 0, 점프) | **400** `INVALID_STATE_TRANSITION` |
| `PATCH /status {status:1}` (현재 1, idempotent) | **400** `INVALID_STATE_TRANSITION` |
| `PATCH /status {status:5}` (잘못된 값) | **400** `INVALID_STATUS_VALUE` |
| 다른 사용자 미션에 PATCH | **403** `FORBIDDEN` |
| 없는 missionId | **404** `NOT_FOUND` |

---

## 7. 기존 전체 PATCH 와의 관계

- `PATCH /api/v1/missions/{id}` (기존, 전체 교체) — **빌더 저장 시 그대로 사용**. 메타·아이템·퀴즈 통째 변경용.
- `PATCH /api/v1/missions/{id}/status` (신규) — **status 토글 전용**. 가벼움 + 단방향 룰 강제.

두 엔드포인트 모두 유지. 빌더에서 저장 + 진행은 분리:
1. 빌더 저장 = 전체 PATCH (Status=0 으로 저장)
2. 디자인 목록의 "Test Pass" / "Publish" 액션 = status PATCH

---

## 8. 마이그레이션 체크리스트

- [ ] `MissionStatus` enum 3단계 확장
- [ ] `fromInt` 디코더 (legacy 3 등 흡수)
- [ ] API 클라에 `updateMissionStatus(id, status)` 추가
- [ ] 빌더 메타 화면의 공개 토글 → 단순 상태 표시 (편집 가능한 토글 제거)
- [ ] DesignActionSheet 의 togglePublish 액션 → `advanceStatus` (단방향 진행)
- [ ] 디자인 목록 status 칩 3종 (비공개·테스트·공개) 색상 정의
- [ ] 에러 처리 (`INVALID_STATE_TRANSITION` / `FORBIDDEN` 분기)
- [ ] 공개 상태(2) 에서 모든 진행/되돌리기 액션 비활성

---

## 9. 참고 — iOS 동일 변경

iOS Swift 코드에서 같은 작업 완료. 비교 참고:

| 파일 | 변경 |
|---|---|
| [PlaySpot/Models/GameState.swift](PlaySpot/Models/GameState.swift) | `MissionStatus` 3-case + `next` 계산 프로퍼티 |
| [PlaySpot/Network/MissionDataSource.swift](PlaySpot/Network/MissionDataSource.swift) | `updateMissionStatus(missionID:status:)` 프로토콜 메서드 |
| [PlaySpot/Network/RestRemoteDataSource.swift](PlaySpot/Network/RestRemoteDataSource.swift) | 신규 엔드포인트 호출 구현 |
| [PlaySpot/Views/MissionBuilder/DesignActionSheet.swift](PlaySpot/Views/MissionBuilder/DesignActionSheet.swift) | `advanceTitle`/`advanceSubtitle`/`advanceIcon` 단방향 진행 |
| [PlaySpot/Views/MissionBuilder/MissionBuilderView.swift](PlaySpot/Views/MissionBuilder/MissionBuilderView.swift) | `advanceStatus(_:)` 가 신규 엔드포인트 호출 |
| [PlaySpot/Views/MissionBuilder/MissionSetupView.swift](PlaySpot/Views/MissionBuilder/MissionSetupView.swift) | 공개 토글 → 상태 표시 카드 (편집 불가) |

Flutter 측 동일 구조로 진행하면 됩니다.
