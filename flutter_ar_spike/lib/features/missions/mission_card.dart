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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DuoColors.green100,
                borderRadius: BorderRadius.circular(DuoRadius.md),
              ),
              child: const Icon(Icons.flag_rounded, color: DuoColors.green700),
            ),
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
