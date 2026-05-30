// features/design/design_providers.dart — 내 디자인 목록 provider.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mission.dart';
import '../../network/app_config.dart';

/// 내가 디자인한 미션 (비공개 + 공개).
/// `ref.watch(authSessionProvider)` 로 AuthSession 의 ChangeNotifier 알림 구독 →
/// 로그인/로그아웃으로 userId 가 바뀌면 자동 재실행.
final myDesignedProvider = FutureProvider<List<Mission>>((ref) async {
  await ref.read(authBootstrapProvider).ensureAuthenticated();
  final uid = ref.watch(authSessionProvider).userId ?? '';
  if (uid.isEmpty) return [];
  return ref.read(dataSourceProvider).fetchMyDesigned(uid);
});
