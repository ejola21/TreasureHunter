// features/design/design_providers.dart — 내 디자인 목록 provider.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mission.dart';
import '../../network/app_config.dart';

/// 내가 디자인한 미션 (비공개 + 공개).
final myDesignedProvider = FutureProvider<List<Mission>>((ref) async {
  await ref.read(authBootstrapProvider).ensureAuthenticated();
  final uid = ref.read(authSessionProvider).userId ?? '';
  if (uid.isEmpty) return [];
  return ref.read(dataSourceProvider).fetchMyDesigned(uid);
});
