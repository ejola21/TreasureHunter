// app/main_tab.dart — 하단 5탭 (미션 / 디자인 / 내정보 / 뱃지 / 설정).
// 앱 시작 시 AuthBootstrap.ensureAuthenticated() 호출 → 저장된 자격증명으로 자동 로그인.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/duo_tokens.dart';
import '../features/badge/badge_list_page.dart';
import '../features/design/design_list_page.dart';
import '../features/missions/mission_list_page.dart';
import '../features/myinfo/my_info_page.dart';
import '../features/settings/settings_page.dart';
import '../network/app_config.dart';

class MainTab extends ConsumerStatefulWidget {
  const MainTab({super.key});

  @override
  ConsumerState<MainTab> createState() => _MainTabState();
}

class _MainTabState extends ConsumerState<MainTab> {
  int _index = 0;
  static const _pages = [
    MissionListPage(),
    DesignListPage(),
    MyInfoPage(),
    BadgeListPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 자동 로그인 — 저장된 자격증명 있으면 그걸로,
    // 없으면 새 게스트로 자동 가입. 비동기 fire-and-forget (UI 막지 않음).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authBootstrapProvider).ensureAuthenticated();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: DuoColors.macawNavBg,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore, color: DuoColors.green500), label: '미션'),
          NavigationDestination(icon: Icon(Icons.edit_outlined), selectedIcon: Icon(Icons.edit, color: DuoColors.green500), label: '디자인'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: DuoColors.green500), label: '내 정보'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events, color: DuoColors.green500), label: '뱃지'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: DuoColors.green500), label: '설정'),
        ],
      ),
    );
  }
}
