// features/design/mission_setup_page.dart — 새 미션 생성 (createMission).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/candy_button.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/game_state.dart';
import '../../models/mission.dart';
import '../../network/app_config.dart';
import '../../network/builder_mission_req.dart';
import 'builder_page.dart';
import 'design_providers.dart';

class MissionSetupPage extends ConsumerStatefulWidget {
  const MissionSetupPage({super.key});

  @override
  ConsumerState<MissionSetupPage> createState() => _MissionSetupPageState();
}

class _MissionSetupPageState extends ConsumerState<MissionSetupPage> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _place = TextEditingController();
  int _limitMin = 0; // 분. 0 = 무제한
  bool _virtual = false;
  bool _saving = false;

  Future<void> _create() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력하세요')));
      return;
    }
    setState(() => _saving = true);
    final draft = Mission(
      id: '',
      title: _title.text.trim(),
      description: _desc.text.trim(),
      place: _place.text.trim(),
      limitTime: _limitMin * 60,
      status: MissionStatus.unpublished,
      isVirtual: _virtual ? PlayMode.virtual : PlayMode.real,
      lang: 'ko',
    );
    try {
      final id = await ref.read(dataSourceProvider).createMission(BuilderMissionReq.fromMission(draft));
      draft.id = id;
      ref.invalidate(myDesignedProvider);
      if (!mounted) return;
      // 생성 후 바로 빌더로 진입 (아이템 배치).
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BuilderPage(missionID: id, initial: draft)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('생성 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 미션')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('제목', _title),
          _field('설명', _desc, maxLines: 3),
          _field('장소', _place),
          const SizedBox(height: 8),
          Row(children: [
            const Text('제한 시간', style: TextStyle(fontFamily: DuoFonts.display, color: DuoColors.eel2)),
            const Spacer(),
            Text(_limitMin == 0 ? '무제한' : '$_limitMin분', style: const TextStyle(color: DuoColors.hare)),
          ]),
          Slider(value: _limitMin.toDouble(), min: 0, max: 60, divisions: 12,
              onChanged: (v) => setState(() => _limitMin = v.round())),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('가상 모드', style: TextStyle(fontFamily: DuoFonts.display, color: DuoColors.eel2)),
            value: _virtual,
            onChanged: (v) => setState(() => _virtual = v),
          ),
          const SizedBox(height: 16),
          CandyButton(label: _saving ? '생성 중…' : '생성하고 아이템 배치', onPressed: _saving ? null : _create),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );
}
