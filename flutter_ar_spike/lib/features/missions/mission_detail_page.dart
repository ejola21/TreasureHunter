// features/missions/mission_detail_page.dart — SwiftUI MissionDetailView.swift 1:1 (416줄).
// 히어로(macawBg + badge + designer + 별점 + chips) + InfoRows(컬러 배지) +
// Rankings(top3) + Reviews + sticky bottom Play 버튼 + Mode Sheet(Real/Virtual).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/game_state.dart';
import '../../models/mission.dart';
import '../play/mission_play_page.dart';
import 'mission_providers.dart';

class MissionDetailPage extends ConsumerWidget {
  final String missionID;
  final Mission? fallback;
  const MissionDetailPage({super.key, required this.missionID, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(missionDetailProvider(missionID));
    final mission = detail.asData?.value.$1 ?? fallback;
    final title = mission?.title ?? '미션';
    return Scaffold(
      backgroundColor: DuoColors.snow,
      appBar: AppBar(
        title: Text(title,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 16, color: DuoColors.eel2)),
        backgroundColor: DuoColors.snow,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: DuoColors.eel2),
      ),
      body: detail.when(
        loading: () => fallback == null
            ? const Center(child: CircularProgressIndicator())
            : _body(context, ref, fallback!, itemCount: fallback!.items.length, mandatoryCount: fallback!.items.where((it) => it.isMandatory).length),
        error: (e, _) => Center(child: Text('불러오기 실패\n$e', textAlign: TextAlign.center)),
        data: (d) {
          final m = d.$1;
          final items = d.$2;
          return _body(context, ref, m, itemCount: items.length, mandatoryCount: items.where((it) => it.isMandatory).length);
        },
      ),
      bottomNavigationBar: detail.maybeWhen(
        data: (d) => _playButtonBar(context, d.$1),
        orElse: () => fallback != null ? _playButtonBar(context, fallback!) : null,
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, Mission m, {required int itemCount, required int mandatoryCount}) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _heroCard(m),
        const SizedBox(height: 20),
        _infoRowsCard(m, itemCount: itemCount, mandatoryCount: mandatoryCount),
        const SizedBox(height: 20),
        _rankingsCard(m),
        const SizedBox(height: 20),
        _reviewsCard(context, ref),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── 히어로 카드 ──────────────────────────────────────────────────────
  Widget _heroCard(Mission m) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DuoColors.macawBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DuoColors.macawBorder, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 뱃지 (64×64). m.badgeImageName 없으면 rosette 플레이스홀더.
          _badge(m),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BY ${m.designer.toUpperCase().isEmpty ? "UNKNOWN" : m.designer.toUpperCase()}',
                style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 1.5, color: DuoColors.macawDeep)),
            const SizedBox(height: 4),
            Text(m.title.isEmpty ? 'Untitled' : m.title,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 18, color: DuoColors.eel2)),
            const SizedBox(height: 4),
            Row(children: [
              _StarRating(rating: m.recommendAvg, size: 12),
              const SizedBox(width: 6),
              Text('(${m.recommendCnt})', style: const TextStyle(fontSize: 11, color: DuoColors.hare)),
            ]),
          ])),
        ]),
        if (m.description.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(m.description, style: const TextStyle(fontSize: 13, color: DuoColors.wolf2)),
        ],
        const SizedBox(height: 10),
        Row(children: [
          _pillChip('${m.playCnt} PLAYS', DuoColors.green100, DuoColors.green800),
          if (m.failCnt > 0) ...[
            const SizedBox(width: 6),
            _pillChip('${m.failCnt} FAILS', DuoColors.cardinalBg, DuoColors.cardinalDeep),
          ],
        ]),
      ]),
    );
  }

  Widget _badge(Mission m) {
    final url = m.badgeImageName;
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        color: DuoColors.macawBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DuoColors.macawBorder, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: url != null && url.isNotEmpty
            ? Image.network(url, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.workspace_premium, color: DuoColors.macawDeep, size: 28))
            : const Center(child: Icon(Icons.workspace_premium, color: DuoColors.macawDeep, size: 28, weight: 900)),
      ),
    );
  }

  Widget _pillChip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 10, color: fg, letterSpacing: 0.6)),
      );

  // ─── InfoRows 카드 (Place / Items / Time Limit / Created) ────────────
  Widget _infoRowsCard(Mission m, {required int itemCount, required int mandatoryCount}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DuoColors.swan2, width: 2),
      ),
      child: Column(children: [
        _infoRow(Icons.place, DuoColors.macaw, 'PLACE', m.place.isEmpty ? '장소 미설정' : m.place),
        _divider(),
        _itemsRow(itemCount: itemCount, mandatoryCount: mandatoryCount),
        _divider(),
        _infoRow(Icons.access_time_filled, DuoColors.fox, 'TIME LIMIT',
            m.limitTime > 0 ? _formatHms(m.limitTime) : '무제한'),
        _divider(),
        _infoRow(Icons.calendar_today, DuoColors.beetle, 'CREATED', _formatDate(m.writeDate)),
      ]),
    );
  }

  Widget _infoRow(IconData icon, Color tint, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: tint.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: tint, size: 14, weight: 900),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 10, letterSpacing: 0.6, color: DuoColors.hare)),
          const SizedBox(height: 2),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: DuoColors.eel2, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }

  Widget _itemsRow({required int itemCount, required int mandatoryCount}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: DuoColors.green500.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.list_alt, color: DuoColors.green500, size: 14, weight: 900),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ITEMS', style: TextStyle(fontFamily: DuoFonts.display, fontSize: 10, letterSpacing: 0.6, color: DuoColors.hare)),
          const SizedBox(height: 2),
          Row(children: [
            _itemsCountChip('필수', mandatoryCount, DuoColors.cardinal),
            const SizedBox(width: 8),
            _itemsCountChip('전체', itemCount, DuoColors.eel2),
          ]),
        ]),
      ]),
    );
  }

  Widget _itemsCountChip(String label, int count, Color tint) => Row(children: [
        Text(label, style: const TextStyle(fontSize: 11, color: DuoColors.hare, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Text('$count', style: TextStyle(fontSize: 14, color: tint, fontWeight: FontWeight.bold)),
      ]);

  Widget _divider() =>
      Container(height: 1, margin: const EdgeInsets.only(left: 58), color: DuoColors.swan);

  // ─── 랭킹 카드 ────────────────────────────────────────────────────────
  Widget _rankingsCard(Mission m) {
    if (m.shortUser1.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DuoColors.swan2, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('RANKINGS',
            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 1.5, color: DuoColors.hare)),
        const SizedBox(height: 8),
        _rankRow(1, m.shortUser1, m.shortRecord1),
        if (m.shortUser2.isNotEmpty) ...[const SizedBox(height: 8), _rankRow(2, m.shortUser2, m.shortRecord2)],
        if (m.shortUser3.isNotEmpty) ...[const SizedBox(height: 8), _rankRow(3, m.shortUser3, m.shortRecord3)],
      ]),
    );
  }

  Widget _rankRow(int rank, String user, String record) {
    return Row(children: [
      SizedBox(
        width: 28,
        child: Text('#$rank',
            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 14, color: rank == 1 ? DuoColors.bee : DuoColors.hare)),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(user, style: const TextStyle(fontSize: 13, color: DuoColors.eel, fontWeight: FontWeight.w600))),
      Text(record, style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 12, color: DuoColors.wolf2)),
    ]);
  }

  // ─── 리뷰 카드 ────────────────────────────────────────────────────────
  Widget _reviewsCard(BuildContext context, WidgetRef ref) {
    final replies = ref.watch(repliesProvider(missionID));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DuoColors.swan2, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('REVIEWS',
            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 1.5, color: DuoColors.hare)),
        const SizedBox(height: 10),
        replies.when(
          loading: () => const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
          error: (_, _) => const Text('리뷰 불러오기 실패', style: TextStyle(fontSize: 13, color: DuoColors.hare)),
          data: (list) => list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('아직 작성된 댓글이 없습니다.', style: TextStyle(fontSize: 13, color: DuoColors.hare)),
                )
              : Column(children: [
                  for (final r in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: DuoColors.snow, borderRadius: BorderRadius.circular(10)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            _StarRating(rating: r.score ?? 0, size: 12),
                            const SizedBox(width: 8),
                            if (r.nickname?.isNotEmpty == true)
                              Text(r.nickname!,
                                  style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 11, color: DuoColors.eel2)),
                            const Spacer(),
                            if (r.writeDate != null)
                              Text(_formatDateShort(r.writeDate!),
                                  style: const TextStyle(fontSize: 10, color: DuoColors.hare)),
                          ]),
                          const SizedBox(height: 6),
                          Text(r.text, style: const TextStyle(fontSize: 13, color: DuoColors.wolf2)),
                        ]),
                      ),
                    ),
                ]),
        ),
      ]),
    );
  }

  // ─── Sticky Play 버튼 (bottomNavigationBar 로 고정) ────────────────────
  Widget _playButtonBar(BuildContext context, Mission m) {
    return SafeArea(
      child: Container(
        color: DuoColors.snow,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DuoColors.green500,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _onPlay(context, m),
            child: const Text('Play · 미션 시작',
                style: TextStyle(fontFamily: DuoFonts.display, fontSize: 16, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  void _onPlay(BuildContext context, Mission m) {
    // Virtual 모드 지원이면 Mode Sheet 띄움, 아니면 Real 바로 시작.
    if (m.isVirtual == PlayMode.virtual) {
      _showModeSheet(context, m);
    } else {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MissionPlayPage(mission: m, virtual: false)));
    }
  }

  void _showModeSheet(BuildContext context, Mission m) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: DuoColors.swan2, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('CHOOSE MODE · 모드 선택',
                  style: TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 1.5, color: DuoColors.hare)),
              const SizedBox(height: 6),
              const Text('어떻게 플레이할까요?',
                  style: TextStyle(fontFamily: DuoFonts.display, fontSize: 20, color: DuoColors.eel2)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _modeButton(ctx, m, 'REAL', '실제 GPS', DuoColors.green500, DuoColors.green800, false)),
                const SizedBox(width: 10),
                Expanded(child: _modeButton(ctx, m, 'VIRTUAL', '가상 위치', DuoColors.beetle, DuoColors.beetleDeep, true)),
              ]),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소', style: TextStyle(color: DuoColors.hare, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _modeButton(BuildContext ctx, Mission m, String title, String subtitle, Color tint, Color deep, bool virtual) {
    return Stack(children: [
      Positioned.fill(
        top: 4,
        child: Container(decoration: BoxDecoration(color: deep, borderRadius: BorderRadius.circular(12))),
      ),
      GestureDetector(
        onTap: () {
          Navigator.pop(ctx);
          Navigator.of(ctx).push(MaterialPageRoute(
              builder: (_) => MissionPlayPage(mission: m, virtual: virtual)));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 14, color: Colors.white)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
          ]),
        ),
      ),
    ]);
  }

  // ─── 포맷 ────────────────────────────────────────────────────────────
  String _formatHms(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  String _formatDateShort(DateTime d) =>
      '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// 별점 렌더 (filled/empty/half).
class _StarRating extends StatelessWidget {
  final double rating; // 0.0 ~ 5.0
  final double size;
  const _StarRating({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          rating >= i ? Icons.star_rounded : (rating >= i - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
          color: DuoColors.bee, size: size,
        ),
    ]);
  }
}
