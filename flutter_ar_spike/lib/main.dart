// main.dart — PlaySpot Flutter 진입점 (plan_playspot_flutter.md Phase 0).
// AR 파일럿 자산은 lib/ar/ 에 보존 (후속 Play 단계에서 연결).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/main_tab.dart';
import 'app/theme.dart';
import 'l10n/app_localizations.dart';
import 'network/app_config.dart';

void main() {
  runApp(const ProviderScope(child: PlaySpotApp()));
}

class PlaySpotApp extends ConsumerWidget {
  const PlaySpotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Settings 에서 선택한 언어. null 이면 시스템 언어 따름.
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'PlaySpot',
      debugShowCheckedModeBanner: false,
      theme: buildPlaySpotTheme(),
      locale: locale,
      // gen-l10n 통합 — AppLocalizations.localizationsDelegates 는
      // AppLocalizations.delegate + 3 개 Material/Widgets/Cupertino delegate 묶음.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainTab(),
    );
  }
}
