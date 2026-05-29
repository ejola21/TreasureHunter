// ar_overlay_view.dart
// 스파이크 핵심 화면 — 카메라 피드 위에 GPS+heading 으로 가짜 아이템 1개를 투영.
// 투영 수학은 PlaySpot/AR/ARGameView.swift (screenPosition / nearestVisibleItem / scaleFactor) 포팅.
import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'ar_coordinate.dart';
import 'compass_service.dart';
import 'location_service.dart';

class ArOverlayView extends StatefulWidget {
  const ArOverlayView({super.key});

  @override
  State<ArOverlayView> createState() => _ArOverlayViewState();
}

class _ArOverlayViewState extends State<ArOverlayView> {
  // ARGameView.swift 의 뷰포트 상수.
  static const double viewportWidthRadians = 0.5;
  static const double maxScaleDistance = 500.0;

  // 가짜 아이템 표시 반경 (m). 이 안에 들어와야 화면에 그림.
  static const double itemRangeMeters = 300.0;
  static const double iconSize = 80.0;

  CameraController? _camera;
  final _location = LocationService();
  final _compass = CompassService();

  Position? _pos;
  HeadingSample? _heading;
  LatLng? _itemLatLng; // 위치 확보 후 북쪽 ~100m 로 설정

  String _status = '시작을 눌러 카메라·위치·나침반 권한을 허용하세요';
  bool _started = false;
  bool _useMock = false; // 데스크톱 등 heading 미지원
  double _mockHeading = 0;

  StreamSubscription<Position>? _posSub;
  StreamSubscription<HeadingSample>? _headSub;

  @override
  void dispose() {
    _posSub?.cancel();
    _headSub?.cancel();
    _compass.dispose();
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    // 1) heading 권한 먼저 (W3/W5) — iOS Safari 의 DeviceOrientationEvent.requestPermission() 은
    //    사용자 제스처 활성화가 살아있을 때 호출해야 한다. 카메라/위치 await 보다 *앞*에 둬야 함.
    final okHead = await _compass.start();
    if (okHead) {
      _headSub = _compass.stream.listen((h) => setState(() {
            _heading = h;
            _useMock = false; // 실제 heading 수신 → mock 해제 (폴백 후 늦게 와도 복구)
          }));
      // 데스크톱은 이벤트가 안 오므로 2초 무수신 시 mock 슬라이더로 폴백.
      Timer(const Duration(milliseconds: 2000), () {
        if (mounted && _heading == null) setState(() => _useMock = true);
      });
    } else {
      _useMock = true; // 권한 거부/미지원 → 슬라이더 mock
    }

    setState(() => _status = '권한 요청 중...');

    // 2) 카메라 (W1)
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() => _status = '카메라를 찾을 수 없습니다');
        return;
      }
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final ctrl =
          CameraController(back, ResolutionPreset.high, enableAudio: false);
      await ctrl.initialize();
      _camera = ctrl;
    } catch (e) {
      setState(() => _status = '카메라 실패: $e');
      return;
    }

    // 3) 위치 (W2)
    final okLoc = await _location.ensurePermission();
    if (!okLoc) {
      setState(() => _status = '위치 권한이 거부되었습니다');
      return;
    }
    _posSub = _location.positionStream().listen((p) {
      _itemLatLng ??= LatLng(p.latitude + 0.0009, p.longitude); // 북쪽 ~100m
      setState(() => _pos = p);
    });

    setState(() {
      _started = true;
      _status = '추적 중';
    });
  }

  double get _currentHeadingDeg =>
      _useMock ? _mockHeading : (_heading?.heading ?? 0);

  /// 현재 아이템의 극좌표 (없으면 null).
  ArCoordinate? get _coord {
    final pos = _pos;
    final item = _itemLatLng;
    if (pos == null || item == null) return null;
    return ArCoordinate.from(
      item: item,
      origin: LatLng(pos.latitude, pos.longitude),
    );
  }

  /// 화면 투영 — viewport 안이면 (x, scale), 밖이면 null.
  ({double x, double scale})? _project(Size size) {
    final coord = _coord;
    if (coord == null) return null;
    final headingRad = _currentHeadingDeg * pi / 180.0;
    final relAz = normalizeAngle(coord.azimuth - headingRad);
    if (relAz.abs() > viewportWidthRadians / 2) return null;
    if (coord.radialDistance > itemRangeMeters) return null;
    final x = size.width / 2 + (relAz / viewportWidthRadians) * (size.width / 2);
    final scale =
        1.0 - (min(coord.radialDistance, maxScaleDistance) / maxScaleDistance) * 0.7;
    return (x: x, scale: max(scale, 0.3));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final proj = _started ? _project(size) : null;
          return Stack(
            children: [
              Positioned.fill(child: _cameraLayer()),
              if (proj != null)
                Positioned(
                  left: proj.x - iconSize / 2,
                  top: size.height / 2 - iconSize / 2,
                  child: Transform.scale(scale: proj.scale, child: _itemMarker()),
                ),
              _debugHud(),
              if (!_started) _startOverlay(),
              if (_started && _useMock) _mockSlider(),
            ],
          );
        },
      ),
    );
  }

  Widget _cameraLayer() {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) {
      return Container(color: Colors.black);
    }
    final preview = cam.value.previewSize;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: preview?.width ?? 1,
        height: preview?.height ?? 1,
        child: CameraPreview(cam),
      ),
    );
  }

  Widget _itemMarker() {
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: const Color(0xFF58CC02),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(color: Color(0x8858CC02), blurRadius: 18, spreadRadius: 2),
        ],
      ),
      child: const Icon(Icons.flag, color: Colors.white, size: 38),
    );
  }

  Widget _debugHud() {
    final pos = _pos;
    final coord = _coord;
    final lines = <String>[
      _status,
      if (pos != null)
        'lat ${pos.latitude.toStringAsFixed(5)}  lon ${pos.longitude.toStringAsFixed(5)}  ±${pos.accuracy.toStringAsFixed(0)}m'
      else
        'lat -  lon -',
      'heading ${_currentHeadingDeg.toStringAsFixed(0)}°  src ${_useMock ? "mock" : (_heading?.source ?? "-")}',
      if (coord != null)
        'item ${coord.radialDistance.toStringAsFixed(0)}m  az ${(coord.azimuth * 180 / pi).toStringAsFixed(0)}°'
      else
        'item -',
    ];
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: lines
                .map((t) => Text(
                      t,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _startOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        alignment: Alignment.center,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF58CC02),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          onPressed: _start,
          child: const Text('시작 (START)'),
        ),
      ),
    );
  }

  Widget _mockSlider() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('heading (mock)',
                style: TextStyle(color: Colors.white, fontSize: 13)),
            Expanded(
              child: Slider(
                value: _mockHeading,
                min: 0,
                max: 360,
                onChanged: (v) => setState(() => _mockHeading = v),
              ),
            ),
            Text('${_mockHeading.toStringAsFixed(0)}°',
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
