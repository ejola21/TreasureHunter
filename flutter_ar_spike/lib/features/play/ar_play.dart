// features/play/ar_play.dart — AR 플레이 (카메라 + 근접 아이템 획득).
// 멀티 아이템 화각 투영(heading 기반 위치)은 후속 정교화. 현재는 카메라 + 근접 리스트 획득.
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../design_system/duo_tokens.dart';
import '../../game/game_engine.dart';
import '../../models/item_type.dart';
import '../../models/mission_item.dart';

const _dist = Distance();

class ArPlay extends StatefulWidget {
  final GameEngine engine;
  final LatLng? player;
  const ArPlay({super.key, required this.engine, this.player});

  @override
  State<ArPlay> createState() => _ArPlayState();
}

class _ArPlayState extends State<ArPlay> {
  CameraController? _cam;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) return;
      final back = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);
      final ctrl = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await ctrl.initialize();
      if (mounted) setState(() => _cam = ctrl);
    } catch (_) {/* 카메라 없음 → 검은 배경 */}
  }

  @override
  void dispose() {
    _cam?.dispose();
    super.dispose();
  }

  List<MissionItem> get _nearest {
    final e = widget.engine;
    final list = e.items.where((it) =>
        e.dicItemEnd[it.itemID] != 'Y' &&
        it.itemType != ItemType.mine &&
        it.itemType != ItemType.black &&
        (e.missionStarted || it.itemType == ItemType.start)).toList();
    if (widget.player != null) {
      list.sort((a, b) => _dist(widget.player!, a.coordinate).compareTo(_dist(widget.player!, b.coordinate)));
    }
    return list.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: (_cam?.value.isInitialized ?? false)
            ? Center(child: CameraPreview(_cam!))
            : Container(color: Colors.black),
      ),
      Positioned(
        left: 12, right: 12, bottom: 100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [for (final it in _nearest) _itemRow(context, it)],
        ),
      ),
    ]);
  }

  Widget _itemRow(BuildContext context, MissionItem it) {
    final p = widget.player;
    final d = p != null ? _dist(p, it.coordinate) : null;
    final inRange = d != null && d <= it.rangeAR;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(DuoRadius.lg),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it.itemType.displayLabel,
                style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 14, color: DuoColors.eel2)),
            Text(d == null ? '거리 측정 중' : '${d.toStringAsFixed(0)}m',
                style: const TextStyle(fontSize: 12, color: DuoColors.hare)),
          ]),
        ),
        FilledButton(
          onPressed: inRange ? () => widget.engine.acquireItem(it) : null,
          child: Text(inRange ? '획득' : '접근'),
        ),
      ]),
    );
  }
}
