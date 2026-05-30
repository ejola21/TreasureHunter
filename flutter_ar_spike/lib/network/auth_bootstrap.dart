// network/auth_bootstrap.dart — AuthBootstrap.swift 이식.
// 토큰 없으면: ① 저장 자격증명 재로그인 ② 실패 시 게스트 자동 register+login.
// 동시 호출은 단일 inflight Future 공유 (게스트 중복 가입 방지).
import 'dart:developer' as dev;
import 'dart:math';
import 'auth_session.dart';
import 'mission_data_source.dart';

class AuthBootstrap {
  final MissionDataSource _ds;
  final AuthSession _auth;
  Future<void>? _inflight;

  AuthBootstrap(this._ds, this._auth);

  Future<void> ensureAuthenticated() {
    final existing = _inflight;
    if (existing != null) return existing;
    final f = _run();
    _inflight = f;
    f.whenComplete(() {
      if (identical(_inflight, f)) _inflight = null;
    });
    return f;
  }

  Future<void> _run() async {
    // (1) 저장된 자격증명 — userId 즉시 복원 → UI 갱신 (token 유무 무관 선행).
    final creds = await _auth.storedCredentials();
    if (creds != null) {
      _auth.userId = creds.userID;
      if (await _auth.token() != null) {
        dev.log('ensureAuth: token+userId restored from storage', name: 'AuthBootstrap');
        return;
      }
      // 토큰 만료/없음 → 자격증명으로 재로그인.
      if (await _ds.login(creds.userID, creds.password)) {
        dev.log('ensureAuth: stored-cred re-login success', name: 'AuthBootstrap');
        return;
      }
      // 재로그인 실패 → 게스트 흐름으로 폴백.
      dev.log('ensureAuth: stored-cred login failed — falling back to guest', name: 'AuthBootstrap');
    }
    // (2) 토큰만 있고 자격증명 없는 경우 — 익명 세션 유지 (이 흐름은 매우 드묾).
    if (creds == null && await _auth.token() != null) {
      dev.log('ensureAuth: token only — anonymous session', name: 'AuthBootstrap');
      return;
    }
    // (3) 신규 게스트.
    final guestId = 'Guest@${DateTime.now().millisecondsSinceEpoch}';
    final guestPw = _random32();
    dev.log('ensureAuth: registering guest $guestId', name: 'AuthBootstrap');
    await _ds.register(guestId, guestPw);
    if (await _ds.login(guestId, guestPw)) {
      // login 내부에서 saveCredentials + userId 설정 함.
      dev.log('ensureAuth: guest login success', name: 'AuthBootstrap');
    } else {
      dev.log('ensureAuth: guest login FAILED', name: 'AuthBootstrap');
    }
  }

  static String _random32() {
    const hex = '0123456789ABCDEF';
    final r = Random.secure();
    return List.generate(32, (_) => hex[r.nextInt(16)]).join();
  }
}
