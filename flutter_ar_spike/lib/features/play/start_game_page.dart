// features/play/start_game_page.dart — 실제/가상 모드 선택 (StartGameView 대응).
import 'package:flutter/material.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/mission.dart';
import 'mission_play_page.dart';

class StartGamePage extends StatelessWidget {
  final Mission mission;
  const StartGamePage({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(mission.title.isEmpty ? '미션 시작' : mission.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const Text('플레이 모드를 선택하세요',
                style: TextStyle(fontFamily: DuoFonts.display, fontSize: 18, color: DuoColors.eel2)),
            const SizedBox(height: 24),
            _modeCard(context, '실제 모드', 'GPS 로 실제 위치에서 플레이', Icons.explore, DuoColors.green500, false),
            const SizedBox(height: 14),
            _modeCard(context, '가상 모드', '현재 위치 기준으로 시뮬레이션', Icons.videogame_asset, DuoColors.macaw, true),
          ],
        ),
      ),
    );
  }

  Widget _modeCard(BuildContext context, String title, String desc, IconData icon, Color color, bool virtual) {
    return InkWell(
      onTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MissionPlayPage(mission: mission, virtual: virtual)),
      ),
      borderRadius: BorderRadius.circular(DuoRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DuoRadius.xl),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(DuoRadius.md)),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 16, color: DuoColors.eel2)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: DuoColors.hare)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: DuoColors.hare),
        ]),
      ),
    );
  }
}
