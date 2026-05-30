// network/app_config.dart — Riverpod DI (AppConfig.dataSource 대응).
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
