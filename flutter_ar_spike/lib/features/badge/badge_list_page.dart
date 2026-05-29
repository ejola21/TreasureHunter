// features/badge/badge_list_page.dart — 뱃지 (미션 뱃지 그리드 + 플레이 마일스톤).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/duo_tokens.dart';
import '../myinfo/info_providers.dart';

class BadgeListPage extends ConsumerWidget {
  const BadgeListPage({super.key});

  static const _milestones = [1, 5, 10, 15, 20, 25, 30, 40, 50, 70, 100];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final played = ref.watch(myPlayedProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Badge', style: TextStyle(fontFamily: DuoFonts.display, color: DuoColors.eel2))),
      body: played.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오기 실패\n$e', textAlign: TextAlign.center)),
        data: (list) {
          final playCount = list.length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _kicker('MISSION BADGES (${list.length})'),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (var i = 0; i < (list.length < 6 ? 6 : list.length); i++)
                    _missionBadge(i < list.length ? (list[i].title.isEmpty ? '미션' : list[i].title) : null),
                ],
              ),
              const SizedBox(height: 20),
              _kicker('PLAY BADGES'),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [for (final m in _milestones) _playBadge(m, playCount >= m)],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kicker(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(t, style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 0.6, color: DuoColors.hare)),
      );

  Widget _missionBadge(String? title) {
    final locked = title == null;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: locked ? DuoColors.swan : DuoColors.bee,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Icon(locked ? Icons.lock : Icons.emoji_events, color: locked ? DuoColors.hare : Colors.white),
      ),
      const SizedBox(height: 4),
      Text(locked ? '잠김' : title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: DuoColors.hare)),
    ]);
  }

  Widget _playBadge(int m, bool earned) => Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: earned ? DuoColors.green500 : DuoColors.swan,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        alignment: Alignment.center,
        child: Text('$m', style: TextStyle(fontFamily: DuoFonts.display, fontSize: 16, color: earned ? Colors.white : DuoColors.hare)),
      );
}
