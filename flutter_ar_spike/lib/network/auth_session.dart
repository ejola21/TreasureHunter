// network/auth_session.dart — AuthSession.swift 이식. JWT 토큰 + 자격증명(보안 저장).
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef Credentials = ({String userID, String password});

class AuthSession {
  static const _kToken = 'jwt.token';
  static const _kUserId = 'credential.userID';
  static const _kPassword = 'credential.password';

  final FlutterSecureStorage _storage;
  String? _cachedToken;

  /// 현재 로그인 사용자 ID (메모리). AppState.userID 대응.
  String? userId;

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
  }
}
