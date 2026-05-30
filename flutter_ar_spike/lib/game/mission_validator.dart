// game/mission_validator.dart — SwiftUI MissionValidator.swift 1:1 이식.
// 미션 디자인 저장 전 클라이언트 측 검증. blocking 에러가 있으면 Save 차단.
// 서버 (/api/v1/missions POST/PATCH) 도 동일 규칙으로 400 VALIDATION_FAILED 반환하므로
// 클라이언트가 미리 차단해 네트워크 왕복 + 사용자 혼란 방지.
import '../models/item_type.dart';
import '../models/mission_item.dart';

class ValidationError {
  final String message;
  /// true = 저장 차단 / false = 경고만 (저장 가능).
  final bool isBlocking;
  const ValidationError(this.message, {this.isBlocking = true});
}

class MissionValidator {
  /// SwiftUI MissionValidator.validate 1:1 + `place` 비어있음 검사 추가
  /// (서버 `/api/v1/missions` 가 place not blank 요구하므로).
  static List<ValidationError> validate({
    required String title,
    required String description,
    required String place,
    required List<MissionItem> items,
  }) {
    final errs = <ValidationError>[];

    // ── 미션 레벨
    if (title.trim().isEmpty) {
      errs.add(const ValidationError('미션 제목을 입력하세요.'));
    }
    if (description.trim().isEmpty) {
      errs.add(const ValidationError('미션 설명을 입력하세요.'));
    }
    if (place.trim().isEmpty) {
      // 서버 `/api/v1/missions` 가 place 를 not-blank 로 요구함.
      errs.add(const ValidationError('미션 장소를 입력하세요.'));
    }
    if (items.length < 3) {
      errs.add(const ValidationError('아이템은 3개 이상 배치하세요.'));
    }
    final starts = items.where((it) => it.itemType == ItemType.start).toList();
    final ends = items.where((it) => it.itemType == ItemType.end).toList();
    if (starts.length != 1) {
      errs.add(const ValidationError('Start 아이템은 정확히 1개여야 합니다.'));
    }
    if (ends.length != 1) {
      errs.add(const ValidationError('End 아이템은 정확히 1개여야 합니다.'));
    }
    final runStarts = items.where((it) => it.itemType == ItemType.timeoutStart).toList();
    final runEnds = items.where((it) => it.itemType == ItemType.timeoutEnd).toList();
    if (runStarts.length != runEnds.length) {
      errs.add(const ValidationError('Run Start 와 Run End 는 짝이 맞아야 합니다.'));
    } else {
      for (final s in runStarts) {
        final paired = runEnds.any((e) =>
            e.itemID == s.relationItemID || e.relationItemID == s.itemID);
        if (!paired) {
          errs.add(ValidationError('Run Start (#${s.itemID}) 의 페어가 없습니다.'));
          break;
        }
      }
    }
    if (items.where((it) => it.isMandatory).isEmpty) {
      errs.add(const ValidationError('필수 아이템이 최소 1개 필요합니다.'));
    }
    // Radar 종류별 중복 금지
    final radarTypes = {
      ItemType.radarAR,
      ItemType.radarMap,
      ItemType.radarAll,
      ItemType.radarMine,
      ItemType.radarBlack,
    };
    final radarCount = <ItemType, int>{};
    for (final it in items) {
      if (radarTypes.contains(it.itemType)) {
        radarCount[it.itemType] = (radarCount[it.itemType] ?? 0) + 1;
      }
    }
    if (radarCount.values.any((n) => n > 1)) {
      errs.add(const ValidationError('각 레이더 종류는 1개만 배치 가능합니다.'));
    }

    // ── 아이템 레벨
    for (final it in items) {
      // Quiz: 변형 ≥ 1, 각 변형의 질문/정답 필수.
      if (it.itemType == ItemType.quiz || it.itemType == ItemType.quiz20) {
        if (it.quizzes.isEmpty) {
          errs.add(ValidationError('Quiz (#${it.itemID}) 은 최소 1개의 변형이 필요합니다.'));
        }
        for (final q in it.quizzes) {
          if (q.quiz.trim().isEmpty || q.answer.trim().isEmpty) {
            errs.add(ValidationError('Quiz 변형 (#${it.itemID} seq ${q.seq}) 의 질문/정답을 입력하세요.'));
          }
        }
      }
      // 안내문(info) 권장 — Hint/Defense/Gambling/Coupon. 차단 X.
      if ({ItemType.simple, ItemType.mineNoBomb, ItemType.random, ItemType.coupon}.contains(it.itemType) &&
          it.info.trim().isEmpty) {
        errs.add(ValidationError('#${it.itemID} ${it.itemType.displayLabel} 의 안내문이 비어 있어요 (선택).',
            isBlocking: false));
      }
      // Run End — 제한 시간 > 0
      if (it.itemType == ItemType.timeoutEnd && it.effectiveTime <= 0) {
        errs.add(ValidationError('Run End (#${it.itemID}) 의 제한 시간을 1초 이상으로 설정하세요.'));
      }
      // Run End — 페어 (Run Start) 존재
      if (it.itemType == ItemType.timeoutEnd) {
        final paired = items.any((s) =>
            s.itemType == ItemType.timeoutStart && s.itemID == it.relationItemID);
        if (!paired) {
          errs.add(ValidationError('Run End (#${it.itemID}) 의 페어 (Run Start) 가 없습니다.'));
        }
      }
    }
    return errs;
  }

  static bool hasBlocking(List<ValidationError> errors) =>
      errors.any((e) => e.isBlocking);
}
