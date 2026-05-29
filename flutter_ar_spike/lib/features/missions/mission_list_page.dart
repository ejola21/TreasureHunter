// features/missions/mission_list_page.dart — 미션 탭 (Phase 2 에서 구현).
import 'package:flutter/material.dart';
import '../../design_system/duo_tokens.dart';

class MissionListPage extends StatelessWidget {
  const MissionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Missions')),
      body: const Center(
        child: Text(
          '미션 탭 (Phase 2)',
          style: TextStyle(color: DuoColors.hare, fontSize: 16),
        ),
      ),
    );
  }
}
