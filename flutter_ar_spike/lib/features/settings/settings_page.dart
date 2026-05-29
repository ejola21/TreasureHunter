// features/settings/settings_page.dart — 설정 (계정/백엔드/버전/도움말).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/duo_tokens.dart';
import '../../design_system/form_group.dart';
import '../../network/app_config.dart';
import '../../network/rest_api_client.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authSessionProvider).userId ?? '-';
    return Scaffold(
      appBar: AppBar(title: const Text('Settings', style: TextStyle(fontFamily: DuoFonts.display, color: DuoColors.eel2))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FormGroup(title: 'ACCOUNT', children: [
            FormRow(label: '사용자 ID', value: userId),
            FormRow(
              label: '로그아웃',
              isLast: true,
              trailing: const Icon(Icons.logout, size: 18, color: DuoColors.cardinal),
              onTap: () async {
                await ref.read(authSessionProvider).reset();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그아웃됨 — 다음 실행 시 새 게스트')));
                }
              },
            ),
          ]),
          const SizedBox(height: 16),
          FormGroup(title: 'API', children: [
            const FormRow(label: '백엔드', value: 'REST'),
            FormRow(label: '서버', value: RestApiClient.baseUrl.replaceFirst('http://', ''), isLast: true),
          ]),
          const SizedBox(height: 16),
          const FormGroup(title: 'ABOUT', children: [
            FormRow(label: '앱', value: 'PlaySpot (Flutter)'),
            FormRow(label: '버전', value: '0.1.0 (전환 진행 중)', isLast: true),
          ]),
        ],
      ),
    );
  }
}
