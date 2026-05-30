// test/unit/items_test.dart — 아이템 타입별 기능 + 사운드 + 팝업 1:1 회귀.
// Ground truth: PlaySpot/Game/GameEngine.swift `acquireItem` + `_setAcquiredAlert`
// + `handleMineBlast`. 모든 문자열 / enum / 효과는 SwiftUI 와 정확히 일치해야 한다.
import 'package:flutter_ar_spike/models/item_type.dart';
import 'package:flutter_ar_spike/services/haptic_service.dart';
import 'package:flutter_ar_spike/services/sound_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'items/_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─── §4-1 start (49) ─────────────────────────────────────────────────────
  group('start (49) — 미션 시작', () {
    test('acquire → missionStarted=true + .gogogo 사운드 + Start 팝업', () async {
      final start = item(id: 1, type: ItemType.start, info: '');
      final t = await buildEngine([start, item(id: 2, type: ItemType.simple)]);
      t.engine.acquireItem(start);

      expect(t.engine.missionStarted, isTrue);
      expect(t.engine.missionStartTime, isNotNull);
      expect(t.engine.dicItemEnd[1], 'Y');
      expect(t.sound.played, contains(SoundEffect.gogogo));
      expect(t.engine.pendingAlert?.title, 'Start Item acquired!');
      expect(t.engine.pendingAlert?.message, 'If you touch OK, the item will be released Mission.');
      t.dispose();
    });

    test('info 채워지면 그 값을 message 로', () async {
      final start = item(id: 1, type: ItemType.start, info: '커스텀 안내');
      final t = await buildEngine([start]);
      t.engine.acquireItem(start);
      expect(t.engine.pendingAlert?.message, '커스텀 안내');
      t.dispose();
    });
  });

  // ─── §4-2 end (48) ───────────────────────────────────────────────────────
  group('end (48) — 미션 종료', () {
    test('모든 필수 + end → completed + .gameFinish', () async {
      final start = item(id: 1, type: ItemType.start);
      final m1 = item(id: 2, type: ItemType.simple, mandatory: true);
      final end = item(id: 3, type: ItemType.end);
      final t = await buildEngine([start, m1, end]);

      t.engine.acquireItem(start);
      t.engine.acquireItem(m1);
      t.sound.clear();
      t.engine.acquireItem(end);

      expect(t.engine.missionCompleted, isTrue);
      expect(t.engine.isMissionEnd, isTrue);
      expect(t.sound.played, contains(SoundEffect.gameFinish));
      t.dispose();
    });

    test('필수 미완료 + end → completed=false, .gameFinish 안 울림', () async {
      final start = item(id: 1, type: ItemType.start);
      final m1 = item(id: 2, type: ItemType.simple, mandatory: true);
      final end = item(id: 3, type: ItemType.end);
      final t = await buildEngine([start, m1, end]);

      t.engine.acquireItem(start);
      t.sound.clear();
      t.engine.acquireItem(end);

      expect(t.engine.missionCompleted, isFalse);
      expect(t.sound.played.contains(SoundEffect.gameFinish), isFalse);
      t.dispose();
    });
  });

  // ─── §4-3 simple (51) ────────────────────────────────────────────────────
  group('simple (51) — Hint', () {
    test('itemGame=0 + info 비어있음 → "Hint Item acquired!" + "Lose the draw!! No hint."', () async {
      final start = item(id: 1, type: ItemType.start);
      final hint = item(id: 2, type: ItemType.simple, info: '');
      final t = await buildEngine([start, hint]);
      t.engine.acquireItem(start);
      _drain(t);
      t.sound.clear();
      t.engine.acquireItem(hint);

      expect(t.sound.played, contains(SoundEffect.itemGet));
      expect(t.engine.pendingAlert?.title, 'Hint Item acquired!');
      expect(t.engine.pendingAlert?.message, 'Lose the draw!! No hint.');
      t.dispose();
    });

    test('itemGame=0 + info 채워짐 → message = info', () async {
      final start = item(id: 1, type: ItemType.start);
      final hint = item(id: 2, type: ItemType.simple, info: '깊은 곳을 보세요');
      final t = await buildEngine([start, hint]);
      t.engine.acquireItem(start);
      _drain(t);
      t.engine.acquireItem(hint);
      expect(t.engine.pendingAlert?.message, '깊은 곳을 보세요');
      t.dispose();
    });

    test('itemGame>0 → simple 분기 팝업 enqueue 안 함 (default 분기)', () async {
      // SwiftUI: `.simple where item.itemGame == 0` — itemGame>0 은 default → 팝업 없음.
      final start = item(id: 1, type: ItemType.start);
      final mg = item(id: 2, type: ItemType.simple, itemGame: 1);
      final t = await buildEngine([start, mg]);
      t.engine.acquireItem(start);
      _drain(t);
      t.engine.acquireItem(mg);
      expect(t.engine.pendingAlert, isNull);
      t.dispose();
    });
  });

  // ─── §4-4 quiz / quiz20 — _setAcquiredAlert default 분기 (팝업 없음) ──────
  group('quiz (40) / quiz20 (41)', () {
    test('quiz acquire → .itemGet, _setAcquiredAlert default (팝업 enqueue 없음)', () async {
      final start = item(id: 1, type: ItemType.start);
      final q = item(id: 2, type: ItemType.quiz);
      final t = await buildEngine([start, q]);
      t.engine.acquireItem(start);
      _drain(t);
      t.sound.clear();
      t.engine.acquireItem(q);
      expect(t.sound.played, contains(SoundEffect.itemGet));
      expect(t.engine.pendingAlert, isNull); // default 분기 — alert 없음
      expect(t.engine.dicItemEnd[2], 'Y');
      t.dispose();
    });

    test('quiz20 동일 — 팝업 없음, dicItemEnd=Y', () async {
      final start = item(id: 1, type: ItemType.start);
      final q = item(id: 2, type: ItemType.quiz20);
      final t = await buildEngine([start, q]);
      t.engine.acquireItem(start);
      _drain(t);
      t.engine.acquireItem(q);
      expect(t.engine.pendingAlert, isNull);
      expect(t.engine.dicItemEnd[2], 'Y');
      t.dispose();
    });
  });

  // ─── §4-5 timeoutStart (42) ──────────────────────────────────────────────
  group('timeoutStart (42) — Run Start', () {
    test('acquire → isTimeOutActive=true, activeTimeoutStartID, timeOutLimitTime = 페어 effectiveTime', () async {
      final start = item(id: 1, type: ItemType.start);
      final rs = item(id: 2, type: ItemType.timeoutStart);
      final re = item(id: 3, type: ItemType.timeoutEnd, relation: 2, effectiveTime: 60);
      final t = await buildEngine([start, rs, re]);
      t.engine.acquireItem(start);
      _drain(t);
      t.sound.clear();
      t.engine.acquireItem(rs);

      expect(t.engine.isTimeOutActive, isTrue);
      expect(t.engine.activeTimeoutStartID, 2);
      expect(t.engine.timeOutLimitTime, 60);
      expect(t.sound.played, contains(SoundEffect.itemGet));
      // 팝업: SwiftUI 는 MM:SS 포맷 사용. 60초 → "01:00"
      expect(t.engine.pendingAlert?.title, 'Run Start Item acquired!');
      expect(t.engine.pendingAlert?.message, '제한 시간 01:00 안에 Run End 아이템을 획득하세요.');
      t.dispose();
    });
  });

  // ─── §4-6 timeoutEnd (43) ────────────────────────────────────────────────
  group('timeoutEnd (43) — Run End', () {
    test('활성 + 짝 → isTimeOutActive=false, "Run End Item acquired!" 팝업', () async {
      final start = item(id: 1, type: ItemType.start);
      final rs = item(id: 2, type: ItemType.timeoutStart);
      final re = item(id: 3, type: ItemType.timeoutEnd, relation: 2, effectiveTime: 60);
      final t = await buildEngine([start, rs, re]);
      t.engine.acquireItem(start);
      t.engine.acquireItem(rs);
      _drain(t);
      t.sound.clear();
      t.engine.acquireItem(re);

      expect(t.engine.isTimeOutActive, isFalse);
      expect(t.engine.dicItemEnd[3], 'Y');
      expect(t.sound.played, contains(SoundEffect.itemGet));
      expect(t.engine.pendingAlert?.title, 'Run End Item acquired!');
      expect(t.engine.pendingAlert?.message, 'Run time ended successfully.');
      t.dispose();
    });

    test('비활성에서 acquire 시도 → SwiftUI 동등(거부 안 함, 그냥 Y 처리)', () async {
      // SwiftUI acquireItem 은 timeoutEnd 에 대한 pre-check 없음 — 그냥 dicItemEnd='Y' 처리.
      final start = item(id: 1, type: ItemType.start);
      final re = item(id: 2, type: ItemType.timeoutEnd, effectiveTime: 60);
      final t = await buildEngine([start, re]);
      t.engine.acquireItem(re);
      expect(t.engine.dicItemEnd[2], 'Y');
      expect(t.engine.isTimeOutActive, isFalse); // 이미 false, no-op
      t.dispose();
    });
  });

  // ─── §4-7 mine (55) ──────────────────────────────────────────────────────
  group('mine (55) — 지뢰', () {
    test('Defense 없음 → 최근 획득 1개 손실 + .explosion + heavy 햅틱', () async {
      final start = item(id: 1, type: ItemType.start);
      final s2 = item(id: 2, type: ItemType.simple);
      final mine = item(id: 3, type: ItemType.mine);
      final t = await buildEngine([start, s2, mine]);
      t.engine.acquireItem(start);
      t.engine.acquireItem(s2);
      t.sound.clear();
      t.haptic.clear();
      t.engine.handleMineBlast(mine);

      expect(t.engine.dicItemEnd[3], 'Y'); // mine 소모
      expect(t.engine.dicItemEnd[2], 'N'); // 최근 simple 손실
      expect(t.sound.played, contains(SoundEffect.explosion));
      expect(t.haptic.calls, contains(HapticKind.vibrate));
      t.dispose();
    });

    test('Defense 있음 → 흡수, Defense 카운트 -1, 손실 없음', () async {
      final start = item(id: 1, type: ItemType.start);
      final defense = item(id: 2, type: ItemType.mineNoBomb);
      final s3 = item(id: 3, type: ItemType.simple);
      final mine = item(id: 4, type: ItemType.mine);
      final t = await buildEngine([start, defense, s3, mine]);
      t.engine.acquireItem(start);
      t.engine.acquireItem(defense);
      t.engine.acquireItem(s3);
      t.sound.clear();
      t.engine.handleMineBlast(mine);

      expect(t.engine.dicItemEnd[3], 'Y'); // simple 살아있음
      expect(t.engine.dicRnPTaken[ItemType.mineNoBomb.code], 0);
      expect(t.sound.played, contains(SoundEffect.explosion)); // Defense 유무 무관
      t.dispose();
    });
  });

  // ─── §4-8 mineNoBomb (61) ────────────────────────────────────────────────
  group('mineNoBomb (61) — Defense', () {
    test('acquire → dicRnPTaken[mineNoBomb]++, "Defence Item acquired!" 팝업', () async {
      final start = item(id: 1, type: ItemType.start);
      final d = item(id: 2, type: ItemType.mineNoBomb, info: '');
      final t = await buildEngine([start, d]);
      t.engine.acquireItem(start);
      _drain(t);
      t.sound.clear();
      t.engine.acquireItem(d);

      expect(t.engine.dicRnPTaken[ItemType.mineNoBomb.code], 1);
      expect(t.sound.played, contains(SoundEffect.itemGet));
      expect(t.engine.pendingAlert?.title, 'Defence Item acquired!');
      expect(t.engine.pendingAlert?.message, 'Mine damage can be avoided using this Defence item.');
      t.dispose();
    });
  });

  // ─── §4-9 random (50) — Gambling ─────────────────────────────────────────
  group('random (50) — Gambling', () {
    test('후보 있음 → 보너스 자동 획득, Gambling 알림이 큐 맨 앞', () async {
      final start = item(id: 1, type: ItemType.start);
      final r = item(id: 2, type: ItemType.random);
      final bonus = item(id: 3, type: ItemType.simple, info: '히든');
      final t = await buildEngine([start, r, bonus]);
      t.engine.acquireItem(start);
      _drain(t);
      t.engine.acquireItem(r);

      // 보너스도 acquired.
      expect(t.engine.dicItemEnd[3], 'Y');
      // pendingAlert 는 prepend=true 로 Gambling 이 먼저.
      expect(t.engine.pendingAlert?.title, 'Gambling acquired!');
      expect(t.engine.pendingAlert?.message, 'You won: Hint!');
      // dismiss → 다음 알림 = 보너스(Hint)
      t.engine.dismissCurrentAlert();
      expect(t.engine.pendingAlert?.title, 'Hint Item acquired!');
      t.dispose();
    });

    test('후보 없음 → "Gambling failed — no items left to win."', () async {
      final start = item(id: 1, type: ItemType.start);
      final r = item(id: 2, type: ItemType.random);
      final t = await buildEngine([start, r]);
      t.engine.acquireItem(start);
      _drain(t);
      t.engine.acquireItem(r);

      expect(t.engine.pendingAlert?.title, 'Gambling acquired!');
      expect(t.engine.pendingAlert?.message, 'Gambling failed — no items left to win.');
      t.dispose();
    });
  });

  // ─── §4-11 solution (52) ─────────────────────────────────────────────────
  group('solution (52)', () {
    test('acquire → dicRnPTaken[solution]++, "Solution Item acquired!"', () async {
      final start = item(id: 1, type: ItemType.start);
      final s = item(id: 2, type: ItemType.solution, info: '');
      final t = await buildEngine([start, s]);
      t.engine.acquireItem(start);
      _drain(t);
      t.sound.clear();
      t.engine.acquireItem(s);

      expect(t.engine.dicRnPTaken[ItemType.solution.code], 1);
      expect(t.sound.played, contains(SoundEffect.itemGet));
      expect(t.engine.pendingAlert?.title, 'Solution Item acquired!');
      expect(t.engine.pendingAlert?.message, 'You can get an answer if you win mission quiz or quiz item.');
      t.dispose();
    });
  });

  // ─── §4-12 ~ §4-15 radar 5종 ────────────────────────────────────────────
  group('radarAR (65) — Stealth Radar', () {
    test('acquire → .radar (not .itemGet) + "Stealth Radar Item acquired!"', () async {
      final start = item(id: 1, type: ItemType.start);
      final r = item(id: 2, type: ItemType.radarAR, info: '');
      final t = await buildEngine([start, r]);
      t.engine.acquireItem(start);
      _drain(t);
      t.sound.clear();
      t.engine.acquireItem(r);

      expect(t.engine.dicRnPTaken[ItemType.radarAR.code], 1);
      expect(t.sound.played, contains(SoundEffect.radar));
      expect(t.engine.pendingAlert?.title, 'Stealth Radar Item acquired!');
      expect(t.engine.pendingAlert?.message, 'Stealth items are now visible in AR.');
      t.dispose();
    });
  });

  group('radarMap (66)', () {
    test('acquire → .radar + "Map Radar Item acquired!"', () async {
      final start = item(id: 1, type: ItemType.start);
      final r = item(id: 2, type: ItemType.radarMap, info: '');
      final t = await buildEngine([start, r]);
      t.engine.acquireItem(start);
      _drain(t);
      t.sound.clear();
      t.engine.acquireItem(r);
      expect(t.sound.played, contains(SoundEffect.radar));
      expect(t.engine.pendingAlert?.title, 'Map Radar Item acquired!');
      expect(t.engine.pendingAlert?.message, 'Hidden items are now visible on the map.');
      t.dispose();
    });
  });

  group('radarMine (68)', () {
    test('acquire → .radar + "Mine Radar Item acquired!"', () async {
      final start = item(id: 1, type: ItemType.start);
      final r = item(id: 2, type: ItemType.radarMine, info: '');
      final t = await buildEngine([start, r]);
      t.engine.acquireItem(start);
      _drain(t);
      t.sound.clear();
      t.engine.acquireItem(r);
      expect(t.sound.played, contains(SoundEffect.radar));
      expect(t.engine.pendingAlert?.title, 'Mine Radar Item acquired!');
      expect(t.engine.pendingAlert?.message, 'Mine explosion radius is now shown on the map.');
      t.dispose();
    });
  });

  group('radarAll (67)', () {
    test('acquire → .radar + "All Radar Item acquired!"', () async {
      final start = item(id: 1, type: ItemType.start);
      final r = item(id: 2, type: ItemType.radarAll, info: '');
      final t = await buildEngine([start, r]);
      t.engine.acquireItem(start);
      _drain(t);
      t.sound.clear();
      t.engine.acquireItem(r);
      expect(t.sound.played, contains(SoundEffect.radar));
      expect(t.engine.pendingAlert?.title, 'All Radar Item acquired!');
      expect(t.engine.pendingAlert?.message, 'All hidden items are now revealed.');
      t.dispose();
    });
  });

  // ─── §4-17 coupon (59) ───────────────────────────────────────────────────
  group('coupon (59)', () {
    test('acquire → .itemGet + "Coupon acquired!"', () async {
      final start = item(id: 1, type: ItemType.start);
      final c = item(id: 2, type: ItemType.coupon, info: '');
      final t = await buildEngine([start, c]);
      t.engine.acquireItem(start);
      _drain(t);
      t.sound.clear();
      t.engine.acquireItem(c);
      expect(t.sound.played, contains(SoundEffect.itemGet));
      expect(t.engine.pendingAlert?.title, 'Coupon acquired!');
      expect(t.engine.pendingAlert?.message, 'Coupon acquired. Check details with the designer.');
      t.dispose();
    });
  });

  // ─── §4-10 black (56) — dark zone ────────────────────────────────────────
  group('black (56) — Dark zone', () {
    test('black 자체는 지도 핀 안 그림 (shouldShowOnMap=false 영구)', () async {
      final start = item(id: 1, type: ItemType.start);
      final b = item(id: 2, type: ItemType.black, range: 50);
      final t = await buildEngine([start, b]);
      t.engine.acquireItem(start);
      expect(t.engine.shouldShowOnMap(b), isFalse);
      t.dispose();
    });
  });
}

/// 현재 알림 큐를 비워 다음 acquire 의 pendingAlert 를 깨끗하게 검증할 수 있도록.
void _drain(TestEngine t) {
  while (t.engine.pendingAlert != null) {
    t.engine.dismissCurrentAlert();
  }
}
