// services/sound_service.dart — SoundService (SwiftUI SoundService.swift 이식).
// 추상 [SoundService] + 실 구현 [RealSoundService] (audioplayers) + 테스트용 [FakeSoundService].
//
// SwiftUI 매핑 (Resources/Sounds/*.mp3):
//   itemGet → s_yougotit / explosion → s_explosion / radar → s_radar / gogogo → s_gogogo
//   gameFinish → game_finish / timeOver → s_timeover / gameTouch → s_game_touch
//   quizCorrect → quiz_rightanswer / quizWrong → quiz_wronganswer / quizFail → s_quiz_fail
//   applause → s_applause / timer → s_timer
import 'dart:async';
import 'dart:developer' as dev;
import 'package:audioplayers/audioplayers.dart';

enum SoundEffect {
  itemGet('s_yougotit.mp3'),
  explosion('s_explosion.mp3'),
  radar('s_radar.mp3'),
  gogogo('s_gogogo.mp3'),
  gameFinish('game_finish.mp3'),
  timeOver('s_timeover.mp3'),
  gameTouch('s_game_touch.mp3'),
  quizCorrect('quiz_rightanswer.mp3'),
  quizWrong('quiz_wronganswer.mp3'),
  quizFail('s_quiz_fail.mp3'),
  applause('s_applause.mp3'),
  timer('s_timer.mp3');

  final String file;
  const SoundEffect(this.file);
}

/// 사운드 서비스 인터페이스. 프로덕션 = [RealSoundService], 테스트 = [FakeSoundService].
/// 기본 생성자(`SoundService()`)는 [RealSoundService] 로 위임 — 기존 호출부 호환.
abstract class SoundService {
  factory SoundService() = RealSoundService;
  void play(SoundEffect e);
  void dispose();
}

/// audioplayers 기반 실 재생. 효과별 player 캐시(연속 재생 시 stop 후 재생).
/// 플랫폼 채널 없는 환경(단위테스트) 에서는 첫 실패 후 영구 비활성.
class RealSoundService implements SoundService {
  final _players = <SoundEffect, AudioPlayer>{};
  bool _disabled = false;

  @override
  void play(SoundEffect e) {
    if (_disabled) return;
    runZonedGuarded(() async {
      try {
        final p = _players.putIfAbsent(e, () => AudioPlayer()..setReleaseMode(ReleaseMode.stop));
        await p.stop();
        await p.play(AssetSource('sounds/${e.file}'));
      } catch (err) {
        _disabled = true;
        dev.log('sfx 비활성(첫 실패): ${e.name} — $err', name: 'Sound');
      }
    }, (err, _) {
      _disabled = true;
      dev.log('sfx zone 에러: ${e.name} — $err', name: 'Sound');
    });
  }

  @override
  void dispose() {
    for (final p in _players.values) {
      try {
        p.dispose();
      } catch (_) {}
    }
    _players.clear();
  }
}

/// 테스트용 fake — `played` 리스트에 호출 순서 기록.
/// 검증: `expect(fake.played, [SoundEffect.gogogo, SoundEffect.itemGet]);`
class FakeSoundService implements SoundService {
  final played = <SoundEffect>[];

  @override
  void play(SoundEffect e) => played.add(e);

  @override
  void dispose() {}

  void clear() => played.clear();
}
