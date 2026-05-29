// services/sound_service.dart — SoundService 대응.
// Phase 11(에셋 마이그레이션) 에서 audioplayers 로 실제 재생 연결. 현재는 no-op 로깅 스텁.
import 'dart:developer' as dev;

enum SoundEffect {
  itemGet, explosion, radar, gogogo, gameFinish, timeOver, gameTouch,
}

class SoundService {
  void play(SoundEffect e) {
    // TODO(Phase 11): assets/sounds/<e>.mp3 를 audioplayers 로 재생.
    dev.log('sfx: ${e.name}', name: 'Sound');
  }
}
