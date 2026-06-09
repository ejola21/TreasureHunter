// network/app_config.dart — Riverpod DI (AppConfig.dataSource 대응).
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import 'auth_session.dart';
import 'auth_bootstrap.dart';
import 'mission_data_source.dart';
import 'rest_api_client.dart';
import 'rest_remote_data_source.dart';

/// SwiftUI APIBackend 이식. 현재 Flutter 는 REST 만 실 구현(Legacy 는 UI 토글만, 회귀 안전).
enum APIBackend { legacy, rest }

/// UI 토글 상태. 초기값 rest. Legacy 선택 시 Settings 가 안내 snackbar 표시.
final backendProvider = StateProvider<APIBackend>((ref) => APIBackend.rest);

// ChangeNotifierProvider — userId 변경 시 ref.watch 한 위젯이 자동 rebuild.
final authSessionProvider = ChangeNotifierProvider<AuthSession>((ref) => AuthSession());

final apiClientProvider = Provider<RestApiClient>(
    (ref) => RestApiClient(ref.read(authSessionProvider)));

final dataSourceProvider = Provider<MissionDataSource>(
    (ref) => RestRemoteDataSource(ref.read(apiClientProvider), ref.read(authSessionProvider)));

final authBootstrapProvider = Provider<AuthBootstrap>(
    (ref) => AuthBootstrap(ref.read(dataSourceProvider), ref.read(authSessionProvider)));

/// 플레이 상태 영속화 SQLite DB — `ItemRnPInPlay` 등 3 테이블 호스트.
/// 앱 생명주기 동안 단일 인스턴스 (Provider 캐시) — close 는 OS 에 위임.
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// ─── 언어 선택 (gen-l10n + 영구 저장) ─────────────────────────────────

/// `Locale?` — null 이면 시스템 언어 따름, 그 외엔 강제 적용.
/// MaterialApp.locale 에 바인딩.
class LocaleNotifier extends Notifier<Locale?> {
  static const _prefsKey = 'app_locale';

  @override
  Locale? build() {
    _load();
    return null; // 초기엔 시스템 — _load 후 비동기로 갱신
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && code.isNotEmpty) state = Locale(code);
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

/// 언어별 표시명 (네이티브 표기). 새 ARB 추가 시 이 맵에 한 줄 추가.
/// gen-l10n 이 supportedLocales 를 자동 추출하지만, 화면 표시명은 별도 관리.
const Map<String, String> kLocaleDisplayNames = {
  'en': 'English',
  'ko': '한국어',
  // 'es': 'Español',  // ← app_es.arb 추가 시 주석 해제
  // 'zh': '中文',
  // 'ja': '日本語',
};

String localeDisplayName(Locale? locale) =>
    locale == null ? 'System default' : (kLocaleDisplayNames[locale.languageCode] ?? locale.languageCode);
