// test/unit/sound_haptic_test.dart — Fake/Real 서비스 자체 + GameEngine 호출 시퀀스 회귀.
// test_flutter_playspot.md §3 사운드·햅틱 매트릭스의 핵심 16 이벤트 중 단위 영역만.
import 'package:flutter_ar_spike/models/item_type.dart';
import 'package:flutter_ar_spike/services/haptic_service.dart';
import 'package:flutter_ar_spike/services/sound_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'items/_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fake 자체 검증', () {
    test('FakeSoundService.play 호출 → played 리스트 기록', () {
      final s = FakeSoundService();
      s.play(SoundEffect.gogogo);
      s.play(SoundEffect.itemGet);
      s.play(SoundEffect.explosion);
      expect(s.played, [SoundEffect.gogogo, SoundEffect.itemGet, SoundEffect.explosion]);
    });

    test('FakeHapticService 호출 종류 기록', () {
      final h = FakeHapticService();
      h.vibrate();
      h.success();
      h.light();
      expect(h.calls, [HapticKind.vibrate, HapticKind.success, HapticKind.light]);
    });

    test('SoundService() 기본 생성자 → RealSoundService 위임 (factory 정상)', () {
      final s = SoundService();
      expect(s, isA<RealSoundService>());
      s.dispose();
    });
  });

  group('GameEngine 사운드 호출 시퀀스', () {
    test('Start 획득 → gogogo + itemGet (acquire 끝에 itemGet)', () async {
      final start = item(id: 1, type: ItemType.start);
      final t = await buildEngine([start]);
      t.sound.clear();
      t.engine.acquireItem(start);
      // SwiftUI: line 470 .gogogo + line 508 .itemGet (mission 완료 아님 분기).
      expect(t.sound.played, contains(SoundEffect.gogogo));
      expect(t.sound.played, contains(SoundEffect.itemGet));
      t.dispose();
    });

    test('Radar 획득 → .radar + .itemGet', () async {
      final start = item(id: 1, type: ItemType.start);
      final r = item(id: 2, type: ItemType.radarAR);
      final t = await buildEngine([start, r]);
      t.engine.acquireItem(start);
      t.sound.clear();
      t.engine.acquireItem(r);
      expect(t.sound.played, containsAll([SoundEffect.radar, SoundEffect.itemGet]));
      t.dispose();
    });

    test('mine 폭발 → .explosion + heavy 햅틱 (Defense 유무 무관)', () async {
      final start = item(id: 1, type: ItemType.start);
      final mine = item(id: 2, type: ItemType.mine);
      final t = await buildEngine([start, mine]);
      t.engine.acquireItem(start);
      t.sound.clear();
      t.haptic.clear();
      t.engine.handleMineBlast(mine);
      expect(t.sound.played, contains(SoundEffect.explosion));
      expect(t.haptic.calls, contains(HapticKind.vibrate));
      t.dispose();
    });

    test('mission 완료 → .gameFinish (acquireItem 의 itemGet 분기는 호출 안 됨)', () async {
      // SwiftUI line 497-500: missionCompleted 분기에서 .gameFinish, line 508 의 itemGet 은
      // missionCompleted=false 일 때만 실행.
      final start = item(id: 1, type: ItemType.start);
      final m = item(id: 2, type: ItemType.simple, mandatory: true);
      final end = item(id: 3, type: ItemType.end);
      final t = await buildEngine([start, m, end]);
      t.engine.acquireItem(start);
      t.engine.acquireItem(m);
      t.sound.clear();
      t.engine.acquireItem(end);
      expect(t.sound.played, contains(SoundEffect.gameFinish));
      expect(t.sound.played.contains(SoundEffect.itemGet), isFalse);
      t.dispose();
    });

    test('알림 큐 pop → 다음 알림 시 .itemGet 다시 (queue advance sound)', () async {
      // SwiftUI GameEngine.swift:560 — dismissCurrentAlert 안에서 다음 알림 pop 시 .itemGet.
      final start = item(id: 1, type: ItemType.start);
      final s2 = item(id: 2, type: ItemType.simple);
      final t = await buildEngine([start, s2]);
      t.engine.acquireItem(start); // start 알림
      t.engine.acquireItem(s2);    // hint 알림이 큐에
      t.sound.clear();
      t.engine.dismissCurrentAlert(); // start 닫고 hint 로
      expect(t.sound.played, contains(SoundEffect.itemGet));
      t.dispose();
    });
  });
}
