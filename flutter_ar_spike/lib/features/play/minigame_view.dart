// features/play/minigame_view.dart — 미니게임 (탭하여 게이지 채우기). 완료 시 pop(true).
// (흔들기 감지는 sensors 추가 시 연결 — 현재는 탭/연타로 진행, 전 플랫폼 동작.)
import 'dart:async';
import 'package:flutter/material.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/mission_item.dart';

class MiniGameView extends StatefulWidget {
  final MissionItem item;
  const MiniGameView({super.key, required this.item});

  @override
  State<MiniGameView> createState() => _MiniGameViewState();
}

class _MiniGameViewState extends State<MiniGameView> {
  double _progress = 0;
  Timer? _decay;

  @override
  void initState() {
    super.initState();
    // 가만히 두면 천천히 감소 (연타 유도).
    _decay = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_progress > 0) setState(() => _progress = (_progress - 0.4).clamp(0, 100));
    });
  }

  void _tap() {
    setState(() => _progress = (_progress + 8).clamp(0, 100));
    if (_progress >= 100) {
      _decay?.cancel();
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _decay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _tap,
        behavior: HitTestBehavior.opaque,
        child: Stack(children: [
          // 글로우 (진행도 비례)
          Center(
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  DuoColors.bee.withValues(alpha: 0.2 + (_progress / 100) * 0.6),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${_progress.toInt()}',
                  style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 64, color: Colors.white)),
              const Text('빠르게 탭하세요!',
                  style: TextStyle(fontFamily: DuoFonts.display, fontSize: 20, color: DuoColors.bee)),
            ]),
          ),
          Positioned(
            left: 24, right: 24, bottom: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress / 100,
                minHeight: 16,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(DuoColors.green500),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
