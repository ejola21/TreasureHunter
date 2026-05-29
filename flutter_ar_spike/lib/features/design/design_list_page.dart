// features/design/design_list_page.dart — 내 디자인 (비공개/공개 + 생성/공개/삭제).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/duo_chip.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/game_state.dart';
import '../../models/mission.dart';
import '../../network/app_config.dart';
import '../../network/builder_mission_req.dart';
import 'builder_page.dart';
import 'design_providers.dart';
import 'mission_setup_page.dart';

class DesignListPage extends ConsumerWidget {
  const DesignListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designed = ref.watch(myDesignedProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 디자인',
            style: TextStyle(fontFamily: DuoFonts.display, color: DuoColors.eel2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: DuoColors.green500),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MissionSetupPage())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myDesignedProvider);
          await ref.read(myDesignedProvider.future);
        },
        child: designed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _msg('불러오기 실패\n$e'),
          data: (list) {
            final drafts = list.where((m) => m.status != MissionStatus.published).toList();
            final pub = list.where((m) => m.status == MissionStatus.published).toList();
            if (list.isEmpty) return _msg('우측 상단 + 로 새 미션을 만들어보세요');
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (drafts.isNotEmpty) ...[
                  _groupTitle('비공개'),
                  for (final m in drafts) _row(context, ref, m),
                  const SizedBox(height: 16),
                ],
                if (pub.isNotEmpty) ...[
                  _groupTitle('공개'),
                  for (final m in pub) _row(context, ref, m),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _groupTitle(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6, top: 4),
        child: Text(t.toUpperCase(),
            style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 0.6, color: DuoColors.hare)),
      );

  Widget _row(BuildContext context, WidgetRef ref, Mission m) {
    final published = m.status == MissionStatus.published;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DuoRadius.lg),
        border: Border.all(color: DuoColors.swan2, width: 2),
      ),
      child: ListTile(
        title: Row(children: [
          Flexible(child: Text(m.title.isEmpty ? 'Untitled' : m.title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 14, color: DuoColors.eel2))),
          const SizedBox(width: 6),
          published ? DuoChip.green('공개') : DuoChip.orange('비공개'),
        ]),
        subtitle: Text(
          '${m.place.isEmpty ? "장소 미설정" : m.place} · 아이템 ${m.items.length}개',
          style: const TextStyle(fontSize: 12, color: DuoColors.hare),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => _onAction(context, ref, m, v),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('수정')),
            PopupMenuItem(value: 'toggle', child: Text(published ? '공개 해제' : '공개')),
            PopupMenuItem(
              value: 'delete',
              enabled: !published,
              child: Text('삭제', style: TextStyle(color: published ? DuoColors.hare : DuoColors.cardinal)),
            ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => BuilderPage(missionID: m.id, initial: m))),
      ),
    );
  }

  Future<void> _onAction(BuildContext context, WidgetRef ref, Mission m, String action) async {
    final ds = ref.read(dataSourceProvider);
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case 'edit':
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => BuilderPage(missionID: m.id, initial: m)));
      case 'toggle':
        // 공개/해제 — 최신 아이템 포함 위해 detail 로드 후 status 변경.
        try {
          final (mission, items, _) = await ds.fetchMissionDetail(m.id);
          mission.items = items;
          mission.status = m.status == MissionStatus.published
              ? MissionStatus.unpublished
              : MissionStatus.published;
          await ds.updateMission(m.id, BuilderMissionReq.fromMission(mission));
          ref.invalidate(myDesignedProvider);
          messenger.showSnackBar(SnackBar(content: Text(
              mission.status == MissionStatus.published ? '공개됨' : '공개 해제됨')));
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('실패: $e')));
        }
      case 'delete':
        if (m.status == MissionStatus.published) {
          messenger.showSnackBar(const SnackBar(content: Text('먼저 공개 해제 후 삭제하세요')));
          return;
        }
        try {
          await ds.deleteMission(m.id);
          ref.invalidate(myDesignedProvider);
          messenger.showSnackBar(const SnackBar(content: Text('삭제됨')));
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
        }
    }
  }

  Widget _msg(String t) => ListView(children: [
        Padding(
          padding: const EdgeInsets.only(top: 120),
          child: Center(child: Text(t, textAlign: TextAlign.center, style: const TextStyle(color: DuoColors.hare))),
        ),
      ]);
}
