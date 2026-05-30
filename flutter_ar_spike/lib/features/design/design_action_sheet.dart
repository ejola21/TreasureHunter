// features/design/design_action_sheet.dart — SwiftUI DesignActionSheet.swift 1:1 (149줄).
// 카드형 액션 시트: 미션 상세 · Modify · Test Play · Publish/Unpublish · Delete + Cancel.
// 디자인: 헤더 (kicker + 제목 + place) + 안내 + 4-5개 ActionRow + 취소 버튼.
import 'package:flutter/material.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/game_state.dart';
import '../../models/mission.dart';

// SwiftUI DesignActionSheet.swift 와 1:1 — 4 액션 (Modify / Test / Publish/Unpublish / Delete).
// "Test" 액션이 곧 **MissionDetailView 진입** 으로, 거기서 Play 버튼으로 실제 플레이 시작.
// (별도 View/Detail 액션 없음 — Test 가 그 역할 겸함)
enum DesignAction { modify, test, togglePublish, delete }

/// 결과: 선택된 액션 (취소 = null).
Future<DesignAction?> showDesignActionSheet(BuildContext context, Mission mission) {
  return showModalBottomSheet<DesignAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DuoColors.snow,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _DesignActionSheet(mission: mission),
  );
}

class _DesignActionSheet extends StatelessWidget {
  final Mission mission;
  const _DesignActionSheet({required this.mission});

  bool get _isPublished => mission.status == MissionStatus.published;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.85;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          // 헤더.
          const Text('DESIGN · 디자인 작업',
              style: TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 1.5, color: DuoColors.hare)),
          const SizedBox(height: 6),
          Text(mission.title.isEmpty ? 'Untitled' : mission.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 22, color: DuoColors.eel2)),
          if (mission.place.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(mission.place, style: const TextStyle(fontSize: 12, color: DuoColors.hare)),
          ],
          const SizedBox(height: 12),
          const Text('완성된 디자인을 테스트해본 뒤 서버에 업로드하세요.',
              style: TextStyle(fontSize: 13, color: DuoColors.wolf2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // 액션 4개 (SwiftUI DesignActionSheet 1:1).
          _ActionRow(
            icon: Icons.edit_outlined,
            tint: DuoColors.macaw,
            title: 'Modify · 수정',
            subtitle: '제목·아이템·맵 편집',
            onTap: () => Navigator.pop(context, DesignAction.modify),
          ),
          const SizedBox(height: 12),
          _ActionRow(
            icon: Icons.play_arrow,
            tint: DuoColors.fox,
            title: 'Test Play · 테스트',
            subtitle: '미션 상세 조회 + 시작',
            onTap: () => Navigator.pop(context, DesignAction.test),
          ),
          const SizedBox(height: 12),
          _ActionRow(
            icon: _isPublished ? Icons.lock_open : Icons.cloud_upload,
            tint: _isPublished ? DuoColors.beetle : DuoColors.green500,
            title: _isPublished ? 'Unpublish · 공개 해제' : 'Publish · 서버 업로드',
            subtitle: _isPublished ? '비공개 상태로 되돌립니다' : 'Missions 탭에 공개합니다',
            important: true,
            onTap: () => Navigator.pop(context, DesignAction.togglePublish),
          ),
          const SizedBox(height: 12),
          _ActionRow(
            icon: Icons.delete_outline,
            tint: _isPublished ? DuoColors.hare : DuoColors.cardinal,
            title: 'Delete · 삭제',
            subtitle: _isPublished ? '먼저 공개 해제 후 삭제 가능' : '되돌릴 수 없습니다',
            muted: _isPublished,
            onTap: _isPublished ? null : () => Navigator.pop(context, DesignAction.delete),
          ),
          const SizedBox(height: 16),

          // 취소 버튼.
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: DuoColors.swan2, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DuoRadius.lg)),
                backgroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('취소',
                  style: TextStyle(fontFamily: DuoFonts.display, fontSize: 14, color: DuoColors.wolf, letterSpacing: 0.84)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final bool important;
  final bool muted;
  final VoidCallback? onTap;
  const _ActionRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    this.important = false,
    this.muted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: muted ? 0.7 : 1.0,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: important ? tint : DuoColors.swan2, width: 2),
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 16, weight: 900),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(
                        fontFamily: DuoFonts.display,
                        fontSize: 14,
                        color: muted ? DuoColors.hare : DuoColors.eel2)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 2, style: const TextStyle(fontSize: 12, color: DuoColors.hare)),
              ])),
              const Icon(Icons.chevron_right, color: DuoColors.hare, size: 16, weight: 600),
            ]),
          ),
        ),
      ),
    );
  }
}
