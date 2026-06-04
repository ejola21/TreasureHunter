// features/design/builder_page.dart — SwiftUI MissionBuilderMapView.swift 1:1.
// AppBar: "EDITING / 아이템 배치" + 현재 위치 아이콘 / 지도 longPress → ItemPicker / 핀 탭 → 콜아웃 → ItemDetail
// / 하단 다크 Fox 마스코트 toolbar + validation banner. 닫기는 좌측 back arrow.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../services/web_compass.dart';

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

  // 현재 사용자 위치 — 지도 위 파란 점으로 표시. geolocator 스트림 구독.
  LatLng? _currentLocation;
  StreamSubscription<Position>? _locationSub;
  // 폰 방향 (heading 0~360, 시계방향, 진북 기준). null = 미지원 또는 권한 거부.
  // 네이티브: flutter_compass / 웹: WebCompass (DeviceOrientationEvent).
  double? _heading;
  StreamSubscription<CompassEvent>? _compassSub;
  WebCompass? _webCompass;
  StreamSubscription<double>? _webCompassSub;

  @override
  void initState() {
    super.initState();
    _m = widget.initial ?? Mission(id: widget.missionID);
    _load();
    _initLocationStream();
    _initCompass();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _compassSub?.cancel();
    _webCompassSub?.cancel();
    _webCompass?.stop();
    super.dispose();
  }

  /// flutter_compass(네이티브) / WebCompass(웹) 분기. 권한 없거나 미지원 시 _heading = null 유지.
  /// ar_play._initCompass 와 동일 패턴.
  void _initCompass() {
    if (kIsWeb) {
      _webCompass = WebCompass();
      WebCompass.requestPermission().then((granted) {
        if (!granted || !mounted) return;
        _webCompass!.start();
        _webCompassSub = _webCompass!.headingStream.listen((h) {
          if (!mounted) return;
          setState(() => _heading = (h + 360.0) % 360.0);
        });
      });
      return;
    }
    _compassSub = FlutterCompass.events?.listen((e) {
      if (!mounted || e.heading == null) return;
      setState(() => _heading = (e.heading! + 360.0) % 360.0);
    });
  }

  Future<void> _initLocationStream() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.always && perm != LocationPermission.whileInUse) {
        return; // 권한 없음 — 현재 위치 표시 안 함.
      }
      // 초기 위치 1회 + 이후 5m 이동마다 갱신.
      final initial = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _currentLocation = LatLng(initial.latitude, initial.longitude));
      _locationSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((p) {
        if (!mounted) return;
        setState(() => _currentLocation = LatLng(p.latitude, p.longitude));
      });
    } catch (_) {/* 위치 미지원/거부 — 무시 */}
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
          // 현재 위치로 카메라 이동 — SwiftUI MKUserTrackingButton 동등.
          // 닫기는 좌측 기본 뒤로가기(back arrow) 사용. 서버 저장은 부모 MissionSetupPage 의 "저장" 한 곳.
          IconButton(
            tooltip: '현재 위치',
            icon: const Icon(Icons.my_location, color: DuoColors.macaw),
            onPressed: _moveToCurrentLocation,
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
        // 현재 위치 파란 점 + heading 방향 부채꼴 빔(있을 때만).
        if (_currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation!,
                width: 64,
                height: 64,
                alignment: Alignment.center,
                child: _currentLocationMarker(),
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

  // ───── 현재 위치 ─────
  // AppBar IconButton(my_location) 탭 → 권한 확인 → getCurrentPosition → 카메라 이동.
  // 동시에 _currentLocation 도 갱신해 지도의 파란 점 마커 동기화.
  Future<void> _moveToCurrentLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        messenger.showSnackBar(const SnackBar(
            content: Text('위치 권한이 거부됐어요. 설정에서 허용해주세요.')));
        return;
      }
      final p = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final here = LatLng(p.latitude, p.longitude);
      final zoom = _mapController.camera.zoom;
      _mapController.move(here, zoom);
      setState(() => _currentLocation = here);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('현재 위치를 가져오지 못했어요: $e')));
    }
  }

  /// 파란 점 + (heading 있을 때만) 점 바깥에서 시작하는 부채꼴 빔.
  /// 컨테이너 64×64 — 빔이 점 바깥 32pt 까지 뻗을 공간 확보.
  Widget _currentLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_heading != null)
          Transform.rotate(
            angle: _heading! * math.pi / 180.0,
            child: CustomPaint(
              size: const Size(64, 64),
              painter: _HeadingConePainter(color: DuoColors.macaw),
            ),
          ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: DuoColors.macaw,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// heading 방향(위쪽=북) 으로 펼쳐지는 부채꼴 빔.
/// 점 바깥(반경 10pt 부터) 부터 시작 — 흰 보더에 가려지지 않음.
/// 시작 70% 불투명도 → 끝 0% 페이드.
class _HeadingConePainter extends CustomPainter {
  final Color color;
  _HeadingConePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const double halfAngle = math.pi / 5; // 36° → 총 72° (넓게)
    const double innerR = 10;   // 점 바깥에서 시작
    const double outerR = 30;   // 빔 끝

    // 안쪽 호(점에 가까움) → 직선 → 바깥 호 → 직선 → 닫기.
    final path = ui.Path()
      ..moveTo(cx + innerR * math.sin(-halfAngle), cy - innerR * math.cos(halfAngle))
      ..arcToPoint(
        Offset(cx + innerR * math.sin(halfAngle), cy - innerR * math.cos(halfAngle)),
        radius: const Radius.circular(innerR),
        clockwise: false,
      )
      ..lineTo(cx + outerR * math.sin(halfAngle), cy - outerR * math.cos(halfAngle))
      ..arcToPoint(
        Offset(cx + outerR * math.sin(-halfAngle), cy - outerR * math.cos(halfAngle)),
        radius: const Radius.circular(outerR),
        clockwise: false,
      )
      ..close();

    // 시작은 진하게, 끝으로 갈수록 페이드. 위쪽(-Y) 방향 그라디언트.
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx, cy - innerR),
        Offset(cx, cy - outerR),
        [color.withValues(alpha: 0.70), color.withValues(alpha: 0.0)],
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeadingConePainter oldDelegate) =>
      oldDelegate.color != color;
}
