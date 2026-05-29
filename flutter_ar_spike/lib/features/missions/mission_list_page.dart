// features/missions/mission_list_page.dart — 미션 탭 (인기/신규/내 주변/전체 4세그).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/mission.dart';
import 'mission_card.dart';
import 'mission_detail_page.dart';
import 'mission_providers.dart';

class MissionListPage extends ConsumerStatefulWidget {
  const MissionListPage({super.key});

  @override
  ConsumerState<MissionListPage> createState() => _MissionListPageState();
}

class _MissionListPageState extends ConsumerState<MissionListPage> {
  int _seg = 0; // 0 인기, 1 신규, 2 내 주변, 3 전체
  static const _labels = ['인기', '신규', '내 주변', '전체'];

  List<Mission> _sorted(List<Mission> all) {
    final list = [...all];
    switch (_seg) {
      case 0:
        list.sort((a, b) => b.playCnt.compareTo(a.playCnt));
      case 1:
        list.sort((a, b) => b.writeDate.compareTo(a.writeDate));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isNearby = _seg == 2;
    final asyncMissions =
        isNearby ? ref.watch(nearbyMissionsProvider) : ref.watch(allMissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions',
            style: TextStyle(fontFamily: DuoFonts.display, color: DuoColors.eel2)),
      ),
      body: Column(
        children: [
          _segmentBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(isNearby ? nearbyMissionsProvider : allMissionsProvider);
                await ref.read(isNearby ? nearbyMissionsProvider.future : allMissionsProvider.future);
              },
              child: asyncMissions.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _message('불러오기 실패\n$e'),
                data: (all) {
                  final list = _sorted(all);
                  if (list.isEmpty) return _message('미션이 없습니다');
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: list.length,
                    itemBuilder: (_, i) => MissionCard(
                      mission: list[i],
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MissionDetailPage(missionID: list[i].id, fallback: list[i]),
                      )),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final sel = i == _seg;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _seg = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? DuoColors.green500 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? DuoColors.green500 : DuoColors.swan2, width: 2),
                ),
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    fontFamily: DuoFonts.display,
                    fontSize: 13,
                    color: sel ? Colors.white : DuoColors.wolf,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _message(String t) => ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 120),
            child: Center(
              child: Text(t,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: DuoColors.hare, fontSize: 14)),
            ),
          ),
        ],
      );
}
