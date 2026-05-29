// features/design/builder_page.dart — 디자인 빌더 (flutter_map: 아이템 배치/편집/저장).
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/game_state.dart';
import '../../models/item_type.dart';
import '../../models/mission.dart';
import '../../models/mission_item.dart';
import '../../models/show_type.dart';
import '../../network/app_config.dart';
import '../../network/builder_mission_req.dart';
import 'design_providers.dart';

class BuilderPage extends ConsumerStatefulWidget {
  final String missionID;
  final Mission? initial;
  const BuilderPage({super.key, required this.missionID, this.initial});

  @override
  ConsumerState<BuilderPage> createState() => _BuilderPageState();
}

class _BuilderPageState extends ConsumerState<BuilderPage> {
  late Mission _m;
  bool _loading = true;
  bool _saving = false;

  // 디자이너 picker 에 노출할 대표 아이템 타입.
  static const _placeable = [
    ItemType.start, ItemType.end, ItemType.quiz, ItemType.simple,
    ItemType.mine, ItemType.black, ItemType.solution, ItemType.random,
    ItemType.radarMap, ItemType.radarAR,
  ];

  @override
  void initState() {
    super.initState();
    _m = widget.initial ?? Mission(id: widget.missionID);
    _load();
  }

  Future<void> _load() async {
    try {
      final (mission, items, _) = await ref.read(dataSourceProvider).fetchMissionDetail(widget.missionID);
      mission.items = items;
      if (mounted) setState(() { _m = mission; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false); // 신규(아이템 0) 등은 initial 유지
    }
  }

  LatLng get _center => _m.items.isNotEmpty ? _m.items.first.coordinate : const LatLng(37.5665, 126.9780);

  int get _nextItemID {
    final maxId = _m.items.fold<int>(0, (a, it) => it.itemID > a ? it.itemID : a);
    return maxId + 1;
  }

  void _addItem(LatLng at, ItemType type) {
    setState(() {
      _m.items.add(MissionItem(
        missionID: _m.id,
        itemID: _nextItemID,
        itemType: type,
        latitude: at.latitude,
        longitude: at.longitude,
        mandatory: (type == ItemType.start || type == ItemType.end) ? MandatoryFlag.mandatory : MandatoryFlag.optional,
      ));
    });
  }

  void _removeItem(MissionItem it) => setState(() => _m.items.remove(it));

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(dataSourceProvider).updateMission(_m.id, BuilderMissionReq.fromMission(_m));
      ref.invalidate(myDesignedProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장됨')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_m.title.isEmpty ? '빌더' : _m.title),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '저장 중…' : '저장', style: const TextStyle(fontFamily: DuoFonts.display)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Container(
                width: double.infinity,
                color: DuoColors.macawBg,
                padding: const EdgeInsets.all(8),
                child: Text('지도를 길게 눌러 아이템을 배치 · 핀을 탭하면 편집 (아이템 ${_m.items.length}개)',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: DuoColors.macawDeep)),
              ),
              Expanded(child: _map()),
            ]),
    );
  }

  Widget _map() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 16,
        onLongPress: (_, latlng) => _showTypePicker(latlng),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ejola.playspot',
        ),
        CircleLayer(
          circles: [
            for (final it in _m.items)
              CircleMarker(
                point: it.coordinate,
                radius: it.rangeAR.toDouble(),
                useRadiusInMeter: true,
                color: DuoColors.green500.withValues(alpha: 0.12),
                borderColor: DuoColors.green500.withValues(alpha: 0.5),
                borderStrokeWidth: 1.5,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final it in _m.items)
              Marker(
                point: it.coordinate,
                width: 54,
                height: 54,
                child: GestureDetector(
                  onTap: () => _showItemEditor(it),
                  child: _pin(it),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _pin(MissionItem it) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: it.isMandatory ? DuoColors.fox : DuoColors.green500,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          it.itemType.displayLabel.characters.first,
          style: const TextStyle(color: Colors.white, fontFamily: DuoFonts.display, fontSize: 14),
        ),
      ),
      Text(it.itemType.displayLabel,
          style: const TextStyle(fontSize: 8, color: DuoColors.eel2), maxLines: 1),
    ]);
  }

  void _showTypePicker(LatLng at) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('아이템 추가', style: TextStyle(fontFamily: DuoFonts.display, fontSize: 16)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _placeable)
                ActionChip(
                  label: Text(t.displayLabel),
                  onPressed: () { Navigator.pop(ctx); _addItem(at, t); },
                ),
            ],
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _showItemEditor(MissionItem it) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${it.itemType.displayLabel} #${it.itemID}',
                style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 18, color: DuoColors.eel2)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('필수'),
              value: it.isMandatory,
              onChanged: (v) => setS(() => it.mandatory = v ? MandatoryFlag.mandatory : MandatoryFlag.optional),
            ),
            Row(children: [
              const Text('표시'),
              const SizedBox(width: 12),
              for (final s in ShowType.selectableCases)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s.displayName, style: const TextStyle(fontSize: 11)),
                    selected: it.showType == s,
                    onSelected: (_) => setS(() => it.showType = s),
                  ),
                ),
            ]),
            Row(children: [
              const Text('반경'),
              Expanded(
                child: Slider(
                  value: it.rangeAR.toDouble().clamp(10, 200),
                  min: 10, max: 200, divisions: 19,
                  label: '${it.rangeAR}m',
                  onChanged: (v) => setS(() => it.rangeAR = v.round()),
                ),
              ),
              Text('${it.rangeAR}m'),
            ]),
            TextField(
              controller: TextEditingController(text: it.info),
              decoration: const InputDecoration(labelText: '안내 문구', border: OutlineInputBorder()),
              onChanged: (v) => it.info = v,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, color: DuoColors.cardinal),
                  label: const Text('삭제', style: TextStyle(color: DuoColors.cardinal)),
                  onPressed: () { Navigator.pop(ctx); _removeItem(it); },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () { Navigator.pop(ctx); setState(() {}); },
                  child: const Text('완료'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
