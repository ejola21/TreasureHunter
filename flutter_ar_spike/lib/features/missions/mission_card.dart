// features/missions/mission_card.dart — SwiftUI MissionRowView 1:1.
// 좌측 64×64 뱃지 (hash 기반 tint bg+border) + 제목/장소/별점·Play메타 + 우측 PLAYS/FAILS/V 칩.
import 'package:flutter/material.dart';
import '../../design_system/duo_chip.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/game_state.dart';
import '../../models/mission.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;
  final VoidCallback onTap;
  const MissionCard({super.key, required this.mission, required this.onTap});

  /// SwiftUI MissionRowView.tint — id hash 로 4가지 컬러 분배.
  static const _palette = [
    (bg: DuoColors.green100,    border: DuoColors.green500,  deep: DuoColors.green800),
    (bg: DuoColors.macawBg,     border: DuoColors.macaw,     deep: DuoColors.macawDeep),
    (bg: DuoColors.foxBg,       border: DuoColors.fox,       deep: DuoColors.foxDeep),
    (bg: Color(0xFFF1DCFF),     border: DuoColors.beetle,    deep: DuoColors.beetleDeep),
  ];

  ({Color bg, Color border, Color deep}) get _tint =>
      _palette[mission.id.hashCode.abs() % _palette.length];

  String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final m = mission;
    final tint = _tint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DuoRadius.xl),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DuoRadius.xl),
          border: Border.all(color: DuoColors.swan2, width: 2),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _BadgeTile(url: m.badgeImageUrl, tint: tint),
          const SizedBox(width: 12),
          // 중간: 제목 + 장소 + 별점·Play메타
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(m.title.isEmpty ? 'Untitled' : m.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 15, color: DuoColors.eel2)),
              if (m.place.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(m.place,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: DuoColors.wolf2)),
              ],
              const SizedBox(height: 4),
              Row(children: [
                _StarRow(rating: m.recommendAvg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Play: ${m.playCnt}  ·  ${_fmtDate(m.writeDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: DuoColors.macaw),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          // 우측: PLAYS / (FAILS if > 0) / V (virtual)
          Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
            DuoChip.green('${m.playCnt} PLAYS'),
            if (m.failCnt > 0) ...[
              const SizedBox(height: 4),
              DuoChip.red('${m.failCnt} FAILS'),
            ],
            if (m.isVirtual == PlayMode.virtual) ...[
              const SizedBox(height: 4),
              DuoChip.blue('V'),
            ],
          ]),
        ]),
      ),
    );
  }
}

/// 64×64 뱃지 — tint bg + tint border + 가운데 이미지 또는 rosette placeholder.
class _BadgeTile extends StatelessWidget {
  final String? url;
  final ({Color bg, Color border, Color deep}) tint;
  const _BadgeTile({required this.url, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        color: tint.bg,
        borderRadius: BorderRadius.circular(DuoRadius.lg),
        border: Border.all(color: tint.border, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DuoRadius.lg - 2),
        child: (url == null || url!.isEmpty)
            ? Center(child: Icon(Icons.workspace_premium, color: tint.deep, size: 28, weight: 900))
            : Image.network(
                url!,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, _, _) => Center(
                    child: Icon(Icons.workspace_premium, color: tint.deep, size: 28, weight: 900)),
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : Center(child: Icon(Icons.image_outlined, color: tint.deep, size: 24)),
              ),
      ),
    );
  }
}

/// 5-star row (recommendAvg 0~5, 0.5 단위 round). SwiftUI StarRatingView 동등.
class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    final r = rating.clamp(0.0, 5.0);
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) {
      final filled = i + 1 <= r;
      final half = !filled && (i + 0.5) <= r;
      return Icon(
        half ? Icons.star_half_rounded : Icons.star_rounded,
        size: 11,
        color: (filled || half) ? DuoColors.bee : DuoColors.swan2,
      );
    }));
  }
}
