// network/auth_session.dart — AuthSession.swift 이식. JWT 토큰 + 자격증명(보안 저장).
// ChangeNotifier — userId 변경 시 Settings/MyInfo 등 모든 watcher 가 자동 rebuild.
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef Credentials = ({String userID, String password});

class AuthSession extends ChangeNotifier {
  static const _kToken = 'jwt.token';
  static const _kUserId = 'credential.userID';
  static const _kPassword = 'credential.password';

  final FlutterSecureStorage _storage;
  String? _cachedToken;

  /// 현재 로그인 사용자 ID (메모리). AppState.userID 대응.
  String? _userId;
  String? get userId => _userId;
  set userId(String? v) {
    if (_userId == v) return;
    _userId = v;
    notifyListeners();
  }

  AuthSession([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> token() async {
    _cachedToken ??= await _storage.read(key: _kToken);
    return _cachedToken;
  }

  Future<void> setToken(String t) async {
    _cachedToken = t;
    await _storage.write(key: _kToken, value: t);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await _storage.delete(key: _kToken);
  }

  /// 다음 401 자동 재로그인을 위해 자격증명 저장.
  Future<void> saveCredentials(String userID, String password) async {
    await _storage.write(key: _kUserId, value: userID);
    await _storage.write(key: _kPassword, value: password);
  }

  Future<Credentials?> storedCredentials() async {
    final u = await _storage.read(key: _kUserId);
    final p = await _storage.read(key: _kPassword);
    if (u == null || p == null) return null;
    return (userID: u, password: p);
  }

  Future<void> reset() async {
    await clearToken();
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kPassword);
    userId = null; // setter 가 notifyListeners 호출 → UI 갱신
  }

  /// 토큰(=현재 세션) 은 유지하면서 자동 로그인 자격증명만 삭제.
  /// "자동 로그인 해제" 시 호출 — 다음 앱 실행 시 게스트로 시작.
  Future<void> clearStoredCredentials() async {
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kPassword);
  }
}
