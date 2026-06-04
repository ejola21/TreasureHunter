// features/design/design_list_page.dart — SwiftUI MissionBuilderView 1:1.
// "내 디자인" 헤더(28pt + 녹색 candy +) + FormGroup 그룹("비공개"/"공개") + 행: 제목+chip+부제.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/duo_chip.dart';
import '../../design_system/duo_tokens.dart';
import '../../design_system/form_group.dart';
import '../../models/game_state.dart';
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
      backgroundColor: DuoColors.snow,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myDesignedProvider);
            await ref.read(myDesignedProvider.future);
          },
          child: designed.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _msg('불러오기 실패\n$e'),
            data: (list) {
              // 3-state 분리: 비공개(0) / 테스트 완료(1) / 공개(2)
              final drafts = list.where((m) => m.status == MissionStatus.unpublished).toList();
              final testing = list.where((m) => m.status == MissionStatus.testing).toList();
              final pub = list.where((m) => m.status == MissionStatus.published).toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _header(context),
                  const SizedBox(height: 20),
                  if (list.isEmpty) ...[
                    const SizedBox(height: 40),
                    const Center(
                      child: Column(children: [
                        Text('🤔', style: TextStyle(fontSize: 56)),
                        SizedBox(height: 12),
                        Text('작성한 미션이 없어요',
                            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 16, color: DuoColors.eel2)),
                        SizedBox(height: 6),
                        Text('우측 상단 + 버튼으로 새 미션을 만들어보세요.',
                            style: TextStyle(fontSize: 13, color: DuoColors.hare)),
                      ]),
                    ),
                  ] else ...[
                    if (drafts.isNotEmpty) ...[
                      FormGroup(
                        title: '비공개',
                        subtitle: '편집 중인 미션. 액션 시트에서 ‘Test Pass’ 로 다음 단계로.',
                        children: [
                          for (var i = 0; i < drafts.length; i++)
                            _DesignRow(
                              mission: drafts[i],
                              statusLabel: '비공개',
                              isLast: i == drafts.length - 1,
                              onTap: () => _openActionSheet(context, ref, drafts[i]),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (testing.isNotEmpty) ...[
                      FormGroup(
                        title: '테스트 완료',
                        subtitle: '공개 직전. ‘Publish’ 로 Missions 탭에 노출.',
                        children: [
                          for (var i = 0; i < testing.length; i++)
                            _DesignRow(
                              mission: testing[i],
                              statusLabel: '테스트',
                              isLast: i == testing.length - 1,
                              onTap: () => _openActionSheet(context, ref, testing[i]),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (pub.isNotEmpty)
                      FormGroup(
                        title: '공개',
                        subtitle: 'Missions 탭에 노출 중. 액션 시트의 ‘테스트로 되돌리기’ 로 비공개 단계로 다시 내릴 수 있어요.',
                        children: [
                          for (var i = 0; i < pub.length; i++)
                            _DesignRow(
                              mission: pub[i],
                              statusLabel: '공개',
                              isLast: i == pub.length - 1,
                              onTap: () => _openActionSheet(context, ref, pub[i]),
                            ),
                        ],
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 상단 헤더 — "내 디자인" 28pt + 녹색 candy "+" 버튼 (deep offset 4).
  Widget _header(BuildContext context) {
    return Row(children: [
      const Text('내 디자인',
          style: TextStyle(fontFamily: DuoFonts.display, fontSize: 28, color: DuoColors.eel2)),
      const Spacer(),
      _CandyPlusButton(
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MissionSetupPage())),
      ),
    ]);
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
        // 전진 (0→1, 1→2) — R3.1 신규 엔드포인트 사용.
        final next = m.status.next;
        if (next == null) {
          messenger.showSnackBar(const SnackBar(content: Text('이미 공개된 미션입니다')));
          return;
        }
        try {
          await ds.updateMissionStatus(m.id, next.value);
          ref.invalidate(myDesignedProvider);
          final msg = next == MissionStatus.testing
              ? '테스트 완료로 표시됐어요. 다시 한번 ‘Publish’ 를 눌러 공개하세요.'
              : '공개되었습니다. Missions 탭에서 볼 수 있어요.';
          messenger.showSnackBar(SnackBar(content: Text(msg)));
        } catch (e) {
          final err = e.toString();
          if (err.contains('INVALID_STATE_TRANSITION')) {
            messenger.showSnackBar(const SnackBar(content: Text('이 단계로는 변경할 수 없어요')));
          } else {
            messenger.showSnackBar(SnackBar(content: Text('상태 변경 실패: $e')));
          }
        }
      case DesignAction.demote:
        // 후퇴 (2→1) — 서버 R3.1 가 역방향 거부하므로 전체 PATCH 우회.
        // 메타·아이템·퀴즈 전체 GET → Status=1 변환 → PATCH (전체 교체).
        try {
          final (mission, items, quizzes) = await ds.fetchMissionDetail(m.id);
          for (final it in items) {
            it.quizzes = quizzes.where((q) => q.itemID == it.itemID).toList();
          }
          mission.items = items;
          mission.status = MissionStatus.testing;
          await ds.updateMission(m.id, BuilderMissionReq.fromMission(mission));
          ref.invalidate(myDesignedProvider);
          messenger.showSnackBar(const SnackBar(
              content: Text('테스트 단계로 되돌렸어요. Missions 탭에서 더 이상 안 보입니다.')));
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('되돌리기 실패: $e')));
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

/// SwiftUI DesignRowV2 1:1 — title + status chip + "장소 · 아이템 N개" 부제. 행 사이 1px divider.
/// statusLabel: '비공개' | '테스트' | '공개' — 칩 색상 분기.
class _DesignRow extends StatelessWidget {
  final Mission mission;
  final String statusLabel;
  final bool isLast;
  final VoidCallback onTap;
  const _DesignRow({
    required this.mission,
    required this.statusLabel,
    required this.isLast,
    required this.onTap,
  });

  Widget _chip() {
    switch (statusLabel) {
      case '공개':    return DuoChip.green('공개');
      case '테스트':  return DuoChip.orange('테스트');
      default:       return DuoChip.orange('비공개');
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = mission;
    return Column(children: [
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(m.title.isEmpty ? 'Untitled' : m.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 14, color: DuoColors.eel2)),
              ),
              const SizedBox(width: 6),
              _chip(),
            ]),
            const SizedBox(height: 4),
            Text(
              m.place.isEmpty
                  ? '장소 미설정 · 아이템 ${m.items.length}개'
                  : '${m.place} · 아이템 ${m.items.length}개',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: DuoColors.hare),
            ),
          ]),
        ),
      ),
      if (!isLast)
        Container(height: 1, margin: const EdgeInsets.only(left: 14), color: DuoColors.swan),
    ]);
  }
}

/// SwiftUI candy 버튼 — 36×36 녹색 + green700 그림자 offset 4 + 흰 plus 아이콘.
class _CandyPlusButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CandyPlusButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36, height: 40,
        child: Stack(children: [
          Positioned(
            left: 0, right: 0, top: 4, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: DuoColors.green700,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            left: 0, right: 0, top: 0, bottom: 4,
            child: Container(
              decoration: BoxDecoration(
                color: DuoColors.green500,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add, color: Colors.white, size: 18, weight: 900),
            ),
          ),
        ]),
      ),
    );
  }
}
