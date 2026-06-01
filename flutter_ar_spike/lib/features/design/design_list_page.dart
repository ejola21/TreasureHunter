// features/design/design_list_page.dart — 내 디자인 (비공개/공개 + 생성/공개/삭제).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/duo_chip.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/game_state.dart';
import '../../models/item_type.dart';
import '../../models/mission.dart';
import '../../network/app_config.dart';
import '../../network/builder_mission_req.dart';
import '../missions/mission_detail_page.dart';
import 'design_action_sheet.dart';
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
        leading: _DesignThumb(url: m.badgeImageUrl),
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
        trailing: const Icon(Icons.chevron_right, color: DuoColors.hare),
        onTap: () => _openActionSheet(context, ref, m),
      ),
    );
  }

  /// SwiftUI DesignActionSheet 1:1 — View / Modify / Test / Publish/Unpublish / Delete.
  Future<void> _openActionSheet(BuildContext context, WidgetRef ref, Mission m) async {
    final action = await showDesignActionSheet(context, m);
    if (action == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ds = ref.read(dataSourceProvider);
    switch (action) {
      case DesignAction.modify:
        // SwiftUI 1:1 — Modify 는 MissionSetupView(편집 폼). 거기서 "아이템 배치 (지도 진입)" 으로 빌더로.
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => MissionSetupPage(mission: m)));
      case DesignAction.test:
        // SwiftUI 1:1 — Test 액션이 MissionDetailView 풀스크린.
        // 거기서 "Play · 미션 시작" 버튼으로 실제 플레이 시작.
        Navigator.of(context).push(MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => MissionDetailPage(missionID: m.id, fallback: m)));
      case DesignAction.togglePublish:
        try {
          final (mission, items, quizzes) = await ds.fetchMissionDetail(m.id);
          // Quiz 아이템에 변형 attach — 서버 PATCH 시 quizzes 가 빠지면 안 됨.
          for (final it in items) {
            if (it.itemType == ItemType.quiz || it.itemType == ItemType.quiz20) {
              it.quizzes = quizzes.where((q) => q.itemID == it.itemID).toList();
            }
          }
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
      case DesignAction.delete:
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

/// 내 디자인 행 좌측 작은 뱃지 — 없으면 책갈피 placeholder.
class _DesignThumb extends StatelessWidget {
  final String? url;
  const _DesignThumb({required this.url});

  Widget _placeholder({Color? bg, IconData icon = Icons.bookmark_rounded}) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg ?? DuoColors.green100,
          borderRadius: BorderRadius.circular(DuoRadius.md),
        ),
        child: Icon(icon, color: DuoColors.green700),
      );

  @override
  Widget build(BuildContext context) {
    if (url == null) return _placeholder();
    return ClipRRect(
      borderRadius: BorderRadius.circular(DuoRadius.md),
      child: Image.network(
        url!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, _, _) => _placeholder(),
        loadingBuilder: (_, child, p) =>
            p == null ? child : _placeholder(bg: DuoColors.swan2, icon: Icons.image_outlined),
      ),
    );
  }
}
