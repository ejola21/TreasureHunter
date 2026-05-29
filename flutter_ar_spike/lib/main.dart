// main.dart — PlaySpot Flutter 진입점 (plan_playspot_flutter.md Phase 0).
// AR 파일럿 자산은 lib/ar/ 에 보존 (후속 Play 단계에서 연결).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/main_tab.dart';
import 'app/theme.dart';

void main() {
  runApp(const ProviderScope(child: PlaySpotApp()));
}

class PlaySpotApp extends StatelessWidget {
  const PlaySpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlaySpot',
      debugShowCheckedModeBanner: false,
      theme: buildPlaySpotTheme(),
      home: const MainTab(),
    );
  }
}
