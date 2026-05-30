// features/design/builder_page.dart — SwiftUI MissionBuilderMapView.swift 1:1.
// AppBar: "EDITING / 아이템 배치" + 완료 / 지도 longPress → ItemPicker / 핀 탭 → 콜아웃 → ItemDetail
// / 하단 다크 Fox 마스코트 toolbar + validation banner.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../design_system/duo_tokens.dart';
import '../../game/mission_validator.dart';
import '../../models/game_state.dart';
import '../../models/item_type.dart';
import '../../models/mission.dart';
import '../../models/mission_item.dart';
import '../../network/app_config.dart';
import 'item_detail_sheet.dart';
import 'item_picker_sheet.dart';

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
  int? _calloutItemID; // 콜아웃을 띄울 핀
  int? _draggingItemID; // 드래그 중인 핀 (longPress 충돌 차단용)
  // 화면 좌표 → LatLng 변환을 위한 MapController + 지도 위젯 RenderBox 참조.
  final MapController _mapController = MapController();
  final GlobalKey _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _m = widget.initial ?? Mission(id: widget.missionID);
    _load();
  }

  Future<void> _load() async {
    // 새 미션 (서버 ID 없음) — 부모 MissionSetupPage 가 메모리상 _mission 을 공유함.
    // fetchMissionDetail 호출 의미 없음, initial 그대로 사용.
    if (widget.missionID.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final (mission, items, quizzes) =
          await ref.read(dataSourceProvider).fetchMissionDetail(widget.missionID);
      // Quiz 아이템에 변형 attach — fetchMissionDetail 는 quizzes 를 flat 리스트로 반환.
      for (final it in items) {
        if (it.itemType == ItemType.quiz || it.itemType == ItemType.quiz20) {
          it.quizzes = quizzes.where((q) => q.itemID == it.itemID).toList();
        }
      }
      // 부모(MissionSetupPage)가 _mission 을 참조 공유 중이면 items 를 in-place 갱신.
      // 새 객체 (mission) 로 _m 을 갈아끼우면 참조가 끊겨 부모 검증 카드가 stale 됨.
      if (widget.initial != null) {
        widget.initial!.items = items;
        if (mounted) {
          setState(() => _loading = false);
        }
      } else {
        mission.items = items;
        if (mounted) setState(() { _m = mission; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  LatLng get _center =>
      _m.items.isNotEmpty ? _m.items.first.coordinate : const LatLng(37.486, 126.808);

  int get _nextItemID {
    final maxId = _m.items.fold<int>(0, (a, it) => it.itemID > a ? it.itemID : a);
    return maxId + 1;
  }

  int get _mandatoryCount => _m.items.where((it) => it.isMandatory).length;

  /// MissionValidator (SwiftUI 1:1) — 미션 레벨 + 아이템 레벨 모든 규칙 적용.
  /// 빌더 맵에서는 *아이템 관련* blocking 만 표시 (제목/설명/장소는 MissionSetupPage 책임).
  List<ValidationError> get _validationErrors {
    final all = MissionValidator.validate(
      title: _m.title,
      description: _m.description,
      place: _m.place,
      items: _m.items,
    );
    // 미션 메타(title/desc/place) 관련 메시지는 빌더 맵에서 제외 — 사용자가 여기서 고칠 수 없음.
    const meta = {
      '미션 제목을 입력하세요.',
      '미션 설명을 입력하세요.',
      '미션 장소를 입력하세요.',
    };
    return all.where((e) => !meta.contains(e.message)).toList();
  }

  void _addItem(LatLng at, ItemPickerResult r) {
    setState(() {
      _m.items.add(MissionItem(
        missionID: _m.id,
        itemID: _nextItemID,
        itemType: r.type,
        latitude: at.latitude,
        longitude: at.longitude,
        showType: r.showType,
        rangeAR: r.rangeAR,
        mandatory: (r.type == ItemType.start || r.type == ItemType.end)
            ? MandatoryFlag.mandatory
            : MandatoryFlag.optional,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.snow,
      appBar: AppBar(
        backgroundColor: DuoColors.snow,
        elevation: 0,
        foregroundColor: DuoColors.eel2,
        centerTitle: true,
        title: Column(mainAxisSize: MainAxisSize.min, children: const [
          Text('EDITING',
              style: TextStyle(
                  fontFamily: DuoFonts.display,
                  fontSize: 9,
                  letterSpacing: 0.6,
                  color: DuoColors.hare)),
          Text('아이템 배치',
              style: TextStyle(fontFamily: DuoFonts.display, fontSize: 14, color: DuoColors.eel2)),
        ]),
        actions: [
          // SwiftUI MissionBuilderMapView 와 동일 — 단순 dismiss.
          // 서버 저장은 부모(MissionSetupPage)의 "저장" 한 곳에서만 일어남.
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('완료',
                style: TextStyle(
                    color: DuoColors.macaw,
                    fontFamily: DuoFonts.display,
                    fontWeight: FontWeight.w900)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: DuoColors.macaw))
          : Stack(children: [
              _map(),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (_validationErrors.isNotEmpty) _validationBanner(),
                  if (_calloutItemID != null) _callout(),
                  const SizedBox(height: 6),
                  _bottomToolbar(),
                ]),
              ),
            ]),
    );
  }

  Widget _map() {
    return FlutterMap(
      key: _mapKey,
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 16,
        // 드래그 중에는 longPress 가 picker 를 띄우지 않도록 차단.
        onLongPress: (_, latlng) {
          if (_draggingItemID != null) return;
          _showTypePicker(latlng);
        },
        onTap: (_, _) => setState(() => _calloutItemID = null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ejola.playspot',
        ),
        // 영역 원 — Mine(빨강) / Dark(검정) 만. 일반 아이템 녹색 원은 표시하지 않음
        // (SwiftUI BuilderMapView 와 play map_play.dart 모두 동일 규칙).
        CircleLayer(
          circles: [
            for (final it in _m.items)
              if ((it.itemType == ItemType.mine || it.itemType == ItemType.black) && it.rangeAR > 0)
                CircleMarker(
                  point: it.coordinate,
                  radius: it.rangeAR.toDouble(),
                  useRadiusInMeter: true,
                  color: _rangeFill(it),
                  borderColor: _rangeBorder(it),
                  borderStrokeWidth: 1.5,
                ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final it in _m.items)
              Marker(
                point: it.coordinate,
                width: 44,
                height: 44,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _calloutItemID = it.itemID),
                  // SwiftUI BuilderMapView: MKAnnotationView.isDraggable=true 와 동등.
                  // 길게 눌러서 드래그 — 일반 탭(콜아웃)과 구분.
                  onLongPressStart: (d) {
                    setState(() {
                      _calloutItemID = null;
                      _draggingItemID = it.itemID;
                    });
                    _moveItemToGlobal(it.itemID, d.globalPosition);
                  },
                  onLongPressMoveUpdate: (d) =>
                      _moveItemToGlobal(it.itemID, d.globalPosition),
                  onLongPressEnd: (_) => setState(() => _draggingItemID = null),
                  onLongPressCancel: () => setState(() => _draggingItemID = null),
                  child: Opacity(
                    opacity: _draggingItemID == it.itemID ? 0.7 : 1.0,
                    child: Image.asset(it.itemType.mapIcon(mandatory: it.isMandatory),
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, _, _) => _fallbackPin(it)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Color _rangeFill(MissionItem it) {
    if (it.itemType == ItemType.mine) return DuoColors.cardinal.withValues(alpha: 0.18);
    if (it.itemType == ItemType.black) return Colors.black.withValues(alpha: 0.18);
    return DuoColors.green500.withValues(alpha: 0.12);
  }

  Color _rangeBorder(MissionItem it) {
    if (it.itemType == ItemType.mine) return DuoColors.cardinal.withValues(alpha: 0.55);
    if (it.itemType == ItemType.black) return Colors.black.withValues(alpha: 0.55);
    return DuoColors.green500.withValues(alpha: 0.5);
  }

  Widget _fallbackPin(MissionItem it) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: it.isMandatory ? DuoColors.fox : DuoColors.green500,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(it.itemType.displayLabel.characters.first,
          style: const TextStyle(
              color: Colors.white, fontFamily: DuoFonts.display, fontSize: 12)),
    );
  }

  /// SwiftUI 핀 콜아웃 — "Stealth Radar 40m" 텍스트 + 파란 원형 화살표 버튼 → ItemDetail
  Widget _callout() {
    final it = _m.items.firstWhere((x) => x.itemID == _calloutItemID,
        orElse: () => _m.items.first);
    final label = '${it.itemType.displayLabel} ${it.rangeAR}m';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontFamily: DuoFonts.display, fontSize: 14, color: DuoColors.eel2))),
        GestureDetector(
          onTap: () {
            setState(() => _calloutItemID = null);
            _showItemEditor(it);
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(color: DuoColors.macaw, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
          ),
        ),
      ]),
    );
  }

  Widget _validationBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DuoColors.cardinalBg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DuoColors.cardinal, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        for (final err in _validationErrors.take(3))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Icon(err.isBlocking ? Icons.warning_amber : Icons.info_outline,
                  size: 14,
                  color: err.isBlocking ? DuoColors.cardinalDeep : DuoColors.foxDeep),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(err.message,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: err.isBlocking ? DuoColors.cardinalDeep : DuoColors.foxDeep))),
            ]),
          ),
        if (_validationErrors.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('외 ${_validationErrors.length - 3}건',
                style: const TextStyle(fontSize: 11, color: DuoColors.hare)),
          ),
      ]),
    );
  }

  Widget _bottomToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DuoColors.eel2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Text('🦊', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('꾹 눌러서 아이템 배치 · 탭으로 설정',
                    style: TextStyle(
                        fontFamily: DuoFonts.display, fontSize: 12, color: Colors.white)),
                const SizedBox(height: 2),
                Text('아이템 ${_m.items.length} · 필수 $_mandatoryCount',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7))),
              ]),
        ),
      ]),
    );
  }

  /// 화면 전역 좌표 → 지도 내부 LatLng 변환 후 해당 itemID 의 핀 위치 in-place 갱신.
  /// SwiftUI BuilderMapView 의 onMoveItem(itemID, coord) 와 동등 — 부모(_mission)가 참조 공유하므로
  /// 검증/저장 시 새 위치가 그대로 반영됨.
  void _moveItemToGlobal(int itemID, Offset globalPos) {
    final rb = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final local = rb.globalToLocal(globalPos);
    final LatLng newLatLng = _mapController.camera.offsetToCrs(local);
    final idx = _m.items.indexWhere((x) => x.itemID == itemID);
    if (idx < 0) return;
    setState(() {
      _m.items[idx].latitude = newLatLng.latitude;
      _m.items[idx].longitude = newLatLng.longitude;
    });
  }

  Future<void> _showTypePicker(LatLng at) async {
    final r = await showItemPickerSheet(context);
    if (r == null) return;
    _addItem(at, r);
  }

  Future<void> _showItemEditor(MissionItem it) async {
    final result = await showItemDetailSheet(context, it);
    if (result == null) return;
    setState(() {
      final idx = _m.items.indexOf(it);
      if (idx < 0) return;
      if (result.itemID < 0) {
        _m.items.removeAt(idx);
      } else {
        _m.items[idx] = result;
      }
    });
  }
}
