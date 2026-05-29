// features/missions/mission_list_page.dart — Phase 1 스모크(인증+목록). Phase 2 에서 UI 구현.
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/duo_tokens.dart';
import '../../network/app_config.dart';

class MissionListPage extends ConsumerStatefulWidget {
  const MissionListPage({super.key});

  @override
  ConsumerState<MissionListPage> createState() => _MissionListPageState();
}

class _MissionListPageState extends ConsumerState<MissionListPage> {
  String _status = '인증·로딩 중…';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _smoke());
  }

  Future<void> _smoke() async {
    try {
      await ref.read(authBootstrapProvider).ensureAuthenticated();
      final userId = ref.read(authSessionProvider).userId;
      final list = await ref.read(dataSourceProvider).fetchMissionList();
      dev.log('smoke: userId=$userId, missions=${list.length}', name: 'P1-smoke');
      if (!mounted) return;
      setState(() => _status = list.isEmpty
          ? '인증 OK (userId=$userId)\n미션 0건 (서버 응답 확인 필요)'
          : '인증 OK (userId=$userId)\n미션 ${list.length}건 로드\n첫 미션: ${list.first.title}');
    } catch (e) {
      dev.log('smoke error: $e', name: 'P1-smoke');
      if (mounted) setState(() => _status = '스모크 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Missions')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _status,
            textAlign: TextAlign.center,
            style: const TextStyle(color: DuoColors.eel2, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
