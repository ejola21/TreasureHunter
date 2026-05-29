// features/myinfo/info_providers.dart — 플레이 기록 + 아이템 카운트 provider.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  SharedPreferences? _prefs;

  @override
  UserCounts build() {
    _load();
    return const UserCounts();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = UserCounts(
      solution: _prefs!.getInt('solution') ?? 0,
      timeAdd: _prefs!.getInt('timeAdd') ?? 0,
    );
  }

  void _save() {
    _prefs?.setInt('solution', state.solution);
    _prefs?.setInt('timeAdd', state.timeAdd);
  }

  void addSolution(int n) {
    state = state.copyWith(solution: state.solution + n);
    _save();
  }

  void addTimeAdd(int n) {
    state = state.copyWith(timeAdd: state.timeAdd + n);
    _save();
  }

  /// Hint/Solution 사용 — solution 1 차감. 잔여 없으면 false.
  bool useSolution() {
    if (state.solution <= 0) return false;
    state = state.copyWith(solution: state.solution - 1);
    _save();
    return true;
  }
}

final userCountsProvider =
    NotifierProvider<UserCountsNotifier, UserCounts>(UserCountsNotifier.new);
