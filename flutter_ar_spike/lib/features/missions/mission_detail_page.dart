// features/missions/mission_detail_page.dart — 미션 상세 (정보/랭킹/리뷰).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/candy_button.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/mission.dart';
import '../../models/parse_utils.dart';
import '../../network/app_config.dart';
import '../play/start_game_page.dart';
import 'mission_providers.dart';

class MissionDetailPage extends ConsumerWidget {
  final String missionID;
  final Mission? fallback; // 목록에서 넘어온 요약 (상세 로딩 전 표시)
  const MissionDetailPage({super.key, required this.missionID, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(missionDetailProvider(missionID));
    final mission = detail.asData?.value.$1 ?? fallback;
    return Scaffold(
      appBar: AppBar(title: Text(mission?.title ?? '미션')),
      body: detail.when(
        loading: () => fallback == null
            ? const Center(child: CircularProgressIndicator())
            : _body(context, ref, fallback!, itemCount: fallback!.items.length),
        error: (e, _) => Center(child: Text('불러오기 실패\n$e', textAlign: TextAlign.center)),
        data: (d) => _body(context, ref, d.$1, itemCount: d.$2.length),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, Mission m, {required int itemCount}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _hero(m),
        const SizedBox(height: 16),
        _infoCard(m, itemCount),
        const SizedBox(height: 16),
        _rankingCard(ref),
        const SizedBox(height: 16),
        _repliesCard(context, ref),
        const SizedBox(height: 16),
        CandyButton(
          label: '플레이 시작',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => StartGamePage(mission: m)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _hero(Mission m) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DuoRadius.xl),
          border: Border.all(color: DuoColors.swan2, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.title.isEmpty ? 'Untitled' : m.title,
                style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 22, color: DuoColors.eel2)),
            if (m.place.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.place, size: 15, color: DuoColors.hare),
                Text(' ${m.place}', style: const TextStyle(fontSize: 13, color: DuoColors.hare)),
              ]),
            ],
            if (m.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(m.description, style: const TextStyle(fontSize: 14, color: DuoColors.wolf2)),
            ],
          ],
        ),
      );

  Widget _infoCard(Mission m, int itemCount) {
    final rows = <(String, String)>[
      ('디자이너', m.designer.isEmpty ? '-' : m.designer),
      ('제한 시간', m.limitTime == 0 ? '무제한' : hmsString(m.limitTime)),
      ('아이템', '$itemCount개'),
      ('플레이', '${m.playCnt}회'),
      ('평점', '${m.recommendAvg.toStringAsFixed(1)} (${m.recommendCnt})'),
      ('모드', m.isVirtual.value == 1 ? '가상' : '실제'),
    ];
    return _card('정보', [
      for (var i = 0; i < rows.length; i++)
        _kv(rows[i].$1, rows[i].$2, last: i == rows.length - 1),
    ]);
  }

  Widget _rankingCard(WidgetRef ref) {
    final ranking = ref.watch(rankingProvider(missionID));
    return _card('랭킹 TOP 3', [
      ranking.when(
        loading: () => const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
        error: (_, _) => _empty('랭킹 없음'),
        data: (list) => list.isEmpty
            ? _empty('아직 기록이 없어요')
            : Column(
                children: [
                  for (var i = 0; i < list.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(children: [
                        Text('${i + 1}', style: const TextStyle(fontFamily: DuoFonts.display, color: DuoColors.bee, fontSize: 16)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(list[i].userName, style: const TextStyle(fontSize: 14, color: DuoColors.eel2))),
                        Text(list[i].record, style: const TextStyle(fontSize: 13, color: DuoColors.hare)),
                      ]),
                    ),
                ],
              ),
      ),
    ]);
  }

  Widget _repliesCard(BuildContext context, WidgetRef ref) {
    final replies = ref.watch(repliesProvider(missionID));
    return _card('리뷰', [
      replies.when(
        loading: () => const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
        error: (_, _) => _empty('리뷰 없음'),
        data: (list) => Column(
          children: [
            if (list.isEmpty) _empty('첫 리뷰를 남겨보세요'),
            for (final r in list)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.star_rounded, size: 16, color: DuoColors.bee),
                  Text(' ${r.score?.toStringAsFixed(1) ?? "-"}  ',
                      style: const TextStyle(fontSize: 13, color: DuoColors.wolf)),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.text, style: const TextStyle(fontSize: 14, color: DuoColors.eel2)),
                      if (r.nickname != null)
                        Text(r.nickname!, style: const TextStyle(fontSize: 11, color: DuoColors.hare)),
                    ]),
                  ),
                ]),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('리뷰 작성'),
                onPressed: () => _showReviewSheet(context, ref),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  void _showReviewSheet(BuildContext context, WidgetRef ref) {
    double score = 5;
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: StatefulBuilder(
          builder: (ctx, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('리뷰 작성',
                  style: TextStyle(fontFamily: DuoFonts.display, fontSize: 18, color: DuoColors.eel2)),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (i) {
                  final filled = i < score;
                  return IconButton(
                    onPressed: () => setS(() => score = i + 1),
                    icon: Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: DuoColors.bee, size: 30),
                  );
                }),
              ),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(hintText: '소감을 남겨주세요', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              CandyButton(
                label: '등록',
                onPressed: () async {
                  final userId = ref.read(authSessionProvider).userId ?? 'guest';
                  final ok = await ref.read(dataSourceProvider).submitReview(
                        missionID: missionID,
                        userID: userId,
                        score: score,
                        reply: controller.text.trim(),
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (ok) ref.invalidate(repliesProvider(missionID));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? '리뷰 등록됨' : '등록 실패')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 공통 카드/행
  Widget _card(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(title.toUpperCase(),
                style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 0.6, color: DuoColors.hare)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DuoRadius.lg),
              border: Border.all(color: DuoColors.swan2, width: 2),
            ),
            child: Column(children: children),
          ),
        ],
      );

  Widget _kv(String k, String v, {bool last = false}) => Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Expanded(child: Text(k, style: const TextStyle(fontSize: 14, color: DuoColors.eel2))),
            Text(v, style: const TextStyle(fontSize: 13, color: DuoColors.hare)),
          ]),
        ),
        if (!last) Container(height: 1, margin: const EdgeInsets.only(left: 14), color: DuoColors.swan),
      ]);

  Widget _empty(String t) => Padding(
        padding: const EdgeInsets.all(14),
        child: Text(t, style: const TextStyle(fontSize: 13, color: DuoColors.hare)),
      );
}
