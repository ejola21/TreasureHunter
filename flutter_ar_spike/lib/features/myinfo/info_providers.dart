// features/myinfo/info_providers.dart — 플레이 기록 + 아이템 카운트 provider.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mission.dart';
import '../../network/app_config.dart';

final myPlayedProvider = FutureProvider<List<Mission>>((ref) async {
  await ref.read(authBootstrapProvider).ensureAuthenticated();
  final uid = ref.read(authSessionProvider).userId ?? '';
  if (uid.isEmpty) return [];
  return ref.read(dataSourceProvider).fetchMyPlayed(uid);
});

/// 보유 아이템 카운트 (Solution/Time Add). Phase 10(IAP) 에서 shared_preferences 영속.
class UserCounts {
  final int solution;
  final int timeAdd;
  const UserCounts({this.solution = 0, this.timeAdd = 0});
  UserCounts copyWith({int? solution, int? timeAdd}) =>
      UserCounts(solution: solution ?? this.solution, timeAdd: timeAdd ?? this.timeAdd);
}

class UserCountsNotifier extends Notifier<UserCounts> {
  @override
  UserCounts build() => const UserCounts();

  void addSolution(int n) => state = state.copyWith(solution: state.solution + n);
  void addTimeAdd(int n) => state = state.copyWith(timeAdd: state.timeAdd + n);

  /// Hint 사용 — solution 1 차감. 잔여 없으면 false.
  bool useSolution() {
    if (state.solution <= 0) return false;
    state = state.copyWith(solution: state.solution - 1);
    return true;
  }
}

final userCountsProvider =
    NotifierProvider<UserCountsNotifier, UserCounts>(UserCountsNotifier.new);
