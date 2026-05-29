// features/myinfo/my_info_page.dart — 내 정보 (프로필 + ITEMS + DESIGNED + PLAYED).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/duo_tokens.dart';
import '../../design_system/form_group.dart';
import '../../models/mission.dart';
import '../../network/app_config.dart';
import '../design/design_providers.dart';
import 'info_providers.dart';

class MyInfoPage extends ConsumerWidget {
  const MyInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authSessionProvider).userId ?? '-';
    final isGuest = userId.startsWith('Guest@');
    final counts = ref.watch(userCountsProvider);
    final designed = ref.watch(myDesignedProvider);
    final played = ref.watch(myPlayedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Info', style: TextStyle(fontFamily: DuoFonts.display, color: DuoColors.eel2)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _profile(userId, isGuest),
          const SizedBox(height: 16),
          FormGroup(title: 'ITEMS', children: [
            FormRow(label: 'Solutions', value: '${counts.solution}'),
            FormRow(label: 'Time Add', value: '${counts.timeAdd}', isLast: true),
          ]),
          const SizedBox(height: 16),
          _missionGroup('DESIGNED', designed),
          const SizedBox(height: 16),
          _missionGroup('PLAYED', played),
        ],
      ),
    );
  }

  Widget _profile(String userId, bool isGuest) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DuoRadius.xl),
          border: Border.all(color: DuoColors.swan2, width: 2),
        ),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(color: DuoColors.macaw, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(userId, style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 16, color: DuoColors.eel2)),
            Text(isGuest ? 'Guest' : 'Member', style: const TextStyle(fontSize: 12, color: DuoColors.hare)),
          ]),
        ]),
      );

  Widget _missionGroup(String title, AsyncValue<List<Mission>> async) {
    return async.when(
      loading: () => FormGroup(title: title, children: const [
        Padding(padding: EdgeInsets.all(14), child: Text('불러오는 중…', style: TextStyle(color: DuoColors.hare))),
      ]),
      error: (_, _) => FormGroup(title: title, children: const [
        Padding(padding: EdgeInsets.all(14), child: Text('불러오기 실패', style: TextStyle(color: DuoColors.hare))),
      ]),
      data: (list) => FormGroup(
        title: '$title (${list.length})',
        children: list.isEmpty
            ? const [Padding(padding: EdgeInsets.all(14), child: Text('없음', style: TextStyle(color: DuoColors.hare)))]
            : [
                for (var i = 0; i < list.length; i++)
                  FormRow(label: list[i].title.isEmpty ? 'Untitled' : list[i].title, isLast: i == list.length - 1),
              ],
      ),
    );
  }
}
