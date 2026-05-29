// network/rest_api_client.dart — RestAPIClient.swift 이식.
// dio + Authorization Bearer 자동 부착 + 401/403 1회 자동 재로그인 인터셉터.
import 'package:dio/dio.dart';
import 'auth_session.dart';

class RestApiClient {
  static const baseUrl = 'http://43.201.188.35:8080';

  final AuthSession _auth;
  late final Dio _dio;

  RestApiClient(this._auth) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Accept': 'application/json'},
      contentType: 'application/json',
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final t = await _auth.token();
        if (t != null) options.headers['Authorization'] = 'Bearer $t';
        handler.next(options);
      },
      onError: (e, handler) async {
        final status = e.response?.statusCode ?? 0;
        final path = e.requestOptions.path;
        final isAuth = path.contains('/api/v1/auth/');
        final retried = e.requestOptions.extra['retried'] == true;
        // Spring Security 는 만료 JWT 를 401/403 둘 다 응답 가능 → 둘 다 재로그인 대상.
        if ((status == 401 || status == 403) && !isAuth && !retried) {
          if (await _tryReLogin()) {
            try {
              final opts = e.requestOptions..extra['retried'] = true;
              final t = await _auth.token();
              if (t != null) opts.headers['Authorization'] = 'Bearer $t';
              return handler.resolve(await _dio.fetch(opts));
            } catch (err) {
              return handler.next(err is DioException ? err : e);
            }
          }
        }
        handler.next(e);
      },
    ));
  }

  /// GET — 디코딩된 JSON(dynamic) 반환.
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final r = await _dio.get(path, queryParameters: query);
    return r.data;
  }

  /// POST/PATCH/DELETE — 디코딩된 JSON(dynamic) 반환 (없으면 null).
  Future<dynamic> send(String method, String path, {Object? body}) async {
    final r = await _dio.request(path, data: body, options: Options(method: method));
    return r.data;
  }

  /// 저장된 자격증명으로 /auth/login 재호출 (직접). 성공 시 토큰 갱신.
  Future<bool> _tryReLogin() async {
    final creds = await _auth.storedCredentials();
    if (creds == null) return false;
    await _auth.clearToken();
    try {
      final r = await _dio.post('/api/v1/auth/login',
          data: {'userId': creds.userID, 'password': creds.password});
      final token = (r.data as Map?)?['token'] as String?;
      if (token == null) return false;
      await _auth.setToken(token);
      return true;
    } catch (_) {
      return false;
    }
  }
}
