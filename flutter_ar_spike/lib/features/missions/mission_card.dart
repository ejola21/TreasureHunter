// features/missions/mission_card.dart — 미션 목록 카드 (MissionRowView 대응).
import 'package:flutter/material.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/mission.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;
  final VoidCallback onTap;
  const MissionCard({super.key, required this.mission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = mission;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DuoRadius.lg),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DuoRadius.lg),
          border: Border.all(color: DuoColors.swan2, width: 2),
        ),
        child: Row(
          children: [
            _Thumb(url: m.badgeImageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.title.isEmpty ? 'Untitled' : m.title,
                    style: const TextStyle(
                        fontFamily: DuoFonts.display, fontSize: 15, color: DuoColors.eel2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (m.place.isNotEmpty) m.place,
                      if (m.designer.isNotEmpty) '· ${m.designer}',
                    ].join(' '),
                    style: const TextStyle(fontSize: 12, color: DuoColors.hare),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(children: [
                  const Icon(Icons.play_arrow_rounded, size: 14, color: DuoColors.hare),
                  Text(' ${m.playCnt}', style: const TextStyle(fontSize: 12, color: DuoColors.wolf)),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 14, color: DuoColors.bee),
                  Text(' ${m.recommendAvg.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 12, color: DuoColors.wolf)),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 미션 뱃지 썸네일 — SwiftUI MissionRowView AsyncImage 1:1.
/// URL 없으면 깃발 placeholder, 로딩 중 회색 박스, 실패 시 깃발 fallback.
class _Thumb extends StatelessWidget {
  final String? url;
  const _Thumb({required this.url});

  Widget _placeholder({Color? bg, IconData icon = Icons.flag_rounded}) => Container(
        width: 44,
        height: 44,
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
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        // 웹: <img> 태그 사용 (CORS 없는 S3 도 표시 가능). 비-웹은 무시.
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, _, _) => _placeholder(),
        loadingBuilder: (_, child, p) =>
            p == null ? child : _placeholder(bg: DuoColors.swan2, icon: Icons.image_outlined),
      ),
    );
  }
}
