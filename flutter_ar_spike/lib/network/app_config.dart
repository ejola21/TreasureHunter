// network/app_config.dart — Riverpod DI (AppConfig.dataSource 대응).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_session.dart';
import 'auth_bootstrap.dart';
import 'mission_data_source.dart';
import 'rest_api_client.dart';
import 'rest_remote_data_source.dart';

final authSessionProvider = Provider<AuthSession>((ref) => AuthSession());

final apiClientProvider = Provider<RestApiClient>(
    (ref) => RestApiClient(ref.read(authSessionProvider)));

final dataSourceProvider = Provider<MissionDataSource>(
    (ref) => RestRemoteDataSource(ref.read(apiClientProvider), ref.read(authSessionProvider)));

final authBootstrapProvider = Provider<AuthBootstrap>(
    (ref) => AuthBootstrap(ref.read(dataSourceProvider), ref.read(authSessionProvider)));
