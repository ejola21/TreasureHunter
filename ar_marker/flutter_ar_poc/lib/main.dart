// PlaySpot AR Marker PoC — Entry point
// plan_ar_marker.md §4 (Track A — Flutter 단독 1순위) 구현
//
// 중요: ar_flutter_plugin_plus 1.1.3 의 iOS native `initializeARView` 가
// FlutterResult 를 호출하지 않는 버그가 있다. → await 사용 시 영원히 멈춤.
// 해결: await 없이 호출 + onImageTrackingConfigured 콜백으로 완료 감지.
// 이 패턴이 플러그인 예제와 동일.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:ar_flutter_plugin_plus/widgets/ar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import 'models/treasure_marker.dart';
import 'services/detection_logger.dart';
import 'widgets/png_sequence_animator.dart';

/// 마커 인식 시 특수 오버레이가 트리거될 마커 id 들.
const _kCatMarkerId = 'jung11';

Future<void> main() async {
  // AssetBundle 접근 (마커 자동 발견) 전에 Flutter 엔진 초기화 필요.
  WidgetsFlutterBinding.ensureInitialized();

  // assets/markers/*.png 를 스캔, 전역 kTreasureMarkers 채움.
  // 새 마커 PNG 를 폴더에 추가하면 코드 수정 없이 자동 등록됨.
  await MarkerRegistry.load();
  debugPrint('[main] Loaded ${kTreasureMarkers.length} markers: '
      '${kTreasureMarkers.map((m) => m.id).join(", ")}');

  runApp(const ARPocApp());
}

class ARPocApp extends StatelessWidget {
  const ARPocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR PoC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E6BFF)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AR Marker PoC')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_searching, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'PlaySpot AR 보물찾기 PoC',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${kTreasureMarkers.length} 마커 등록 · ${Platform.operatingSystem}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('스캔 시작'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ARScanPage()),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.data_object),
              label: const Text('인식 로그 보기'),
              onPressed: () => _showLog(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLog(BuildContext context) async {
    final logger = DetectionLogger();
    final csv = await logger.exportCsv();
    final count = await logger.countEvents();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Detection Log ($count events)'),
        content: SingleChildScrollView(
          child: SelectableText(
            csv,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await logger.clear();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class ARScanPage extends StatefulWidget {
  const ARScanPage({super.key});

  @override
  State<ARScanPage> createState() => _ARScanPageState();
}

class _ARScanPageState extends State<ARScanPage> {
  ARSessionManager? _sessionMgr;
  ARObjectManager? _objectMgr;

  bool _initializing = true;
  final Set<String> _foundMarkers = {};
  int _score = 0;
  TreasureMarker? _lastFound;

  DateTime? _sessionStart;

  /// 통인시장 고양이 오버레이 가시성 + 자동 숨김 타이머.
  /// jung11 인식 시 4초간 노출 (참조: tongin_cat_flutter_handoff.md §8 "캐릭터 표시 시간 2~4초").
  bool _showCatOverlay = false;
  Timer? _catHideTimer;

  /// 하단 마커 설명 카드 자동 숨김 타이머 (5초).
  /// 카드가 떠있는 동안 같은 마커 재인식 시 스킵 — 사용자 요청.
  Timer? _cardHideTimer;

  final _logger = DetectionLogger();
  final _placedNodes = <String, ARNode>{};

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
  }

  /// ⚠️ async 처럼 보이지만 await 없이 호출. iOS native init 이 result() 미호출 버그.
  /// onImageTrackingConfigured 콜백으로 완료 감지 → setState 로 로딩 해제.
  void _onARViewCreated(
    ARSessionManager sessionMgr,
    ARObjectManager objectMgr,
    ARAnchorManager anchorMgr,
    ARLocationManager locationMgr,
  ) {
    _sessionMgr = sessionMgr;
    _objectMgr = objectMgr;

    // 콜백: 이미지 트래킹 DB 설정 완료 시 (성공/실패)
    sessionMgr.onImageTrackingConfigured = (success) {
      debugPrint('[onImageTrackingConfigured] success=$success');
      if (mounted) {
        setState(() => _initializing = false);
      }
    };

    // 마커 인식 콜백
    sessionMgr.onImageDetected = _onImageDetected;

    final paths = kTreasureMarkers.map((m) => m.assetPath).toList();
    debugPrint('[ARScanPage] paths=$paths');

    // await 없이 (위 주석 참고).
    sessionMgr.onInitialize(
      showFeaturePoints: false,
      showPlanes: false,
      showWorldOrigin: false,
      handleTaps: false,
      handlePans: false,
      handleRotation: false,
      trackingImagePaths: paths,
      // ⚠️ continuousImageTracking: true 필수.
      // false 면 ARKit 는 마커당 didAdd 1회만 호출 → 재인식 UI 반응 불가.
      // true 로 didUpdate 도 받아 사용자가 보고 있는 마커 실시간 표시.
      continuousImageTracking: true,
      imageTrackingUpdateIntervalMs: 300,
    );
    objectMgr.onInitialize();
  }

  Future<void> _onImageDetected(String imageName, Matrix4 transformation) async {
    // imageName 은 확장자 없는 ID (.png/.jpg/.jpeg 제거).
    final id = imageName
        .replaceAll(RegExp(r'\.(png|jpg|jpeg)$', caseSensitive: false), '');
    final marker = kTreasureMarkers.where((m) => m.id == id).firstOrNull;
    if (marker == null) return;

    // 통인시장 고양이 — jung11 인식 시 손 흔들기 오버레이.
    // 카드와 같은 규칙: 이미 떠있으면 스킵, 안 떠있으면 표시.
    if (id == _kCatMarkerId && !_showCatOverlay) {
      _showCatOverlayFor4s();
    }

    final isFirstTime = !_foundMarkers.contains(id);

    // 점수·햅틱·로깅 — 첫 발견 시에만 (가시성과 무관).
    if (isFirstTime) {
      setState(() {
        _foundMarkers.add(id);
        _score += marker.rewardPts;
      });
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);

      final latency = DateTime.now().difference(_sessionStart!).inMilliseconds;
      await _logger.log(DetectionEvent(
        timestamp: DateTime.now(),
        markerId: id,
        latencyMs: latency,
        device: Platform.operatingSystem,
      ));
    }

    // 마커 설명 카드 — 떠있으면 스킵, 안 떠있을 때만 표시 (사용자 요청).
    // _lastFound == null 이면 카드 숨김 상태 → 새로 띄움.
    if (_lastFound == null) {
      _showMarkerCard(marker);
      if (!isFirstTime) {
        // 첫 발견 외의 재등장 시 가벼운 selection 햅틱
        HapticFeedback.selectionClick();
      }
    }
    // else: 카드 이미 떠있음 → 스킵 (어떤 마커든)

    await _placeTreasure(id, transformation);
  }

  /// 하단 카드 표시 + 5초 후 자동 숨김.
  /// 카드 숨김 = _lastFound = null → build 의 `if (_lastFound != null)` false → 안 그려짐.
  void _showMarkerCard(TreasureMarker marker) {
    _cardHideTimer?.cancel();
    setState(() => _lastFound = marker);
    _cardHideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _lastFound = null);
    });
  }

  Future<void> _placeTreasure(String id, Matrix4 transformation) async {
    if (_objectMgr == null) return;

    final transform = Matrix4.fromFloat64List(transformation.storage);
    const scale = 0.15;
    transform.scaleByVector3(vm.Vector3(scale, scale, scale));

    if (_placedNodes.containsKey(id)) {
      _placedNodes[id]!.transform = transform;
      return;
    }

    // Khronos 공식 샘플 모델 (Duck) — Day 1 placeholder.
    // Day 4 에 assets/models/treasure_chest.glb 로 교체 예정.
    final node = ARNode(
      type: NodeType.webGLB,
      uri:
          'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Binary/Duck.glb',
      transformation: transform,
    );

    final ok = await _objectMgr!.addNode(node);
    if (ok == true) {
      _placedNodes[id] = node;
    }
  }

  /// jung11 인식 시 오버레이 4초간 노출 (참조: tongin_cat_flutter_handoff.md §8).
  /// 4초 안에 다시 인식되면 타이머 리셋 — 마커 보고 있는 동안 계속 표시.
  void _showCatOverlayFor4s() {
    _catHideTimer?.cancel();
    if (!_showCatOverlay) {
      setState(() => _showCatOverlay = true);
    }
    _catHideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showCatOverlay = false);
    });
  }

  @override
  void dispose() {
    _catHideTimer?.cancel();
    _cardHideTimer?.cancel();
    _sessionMgr?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.none,
          ),
          if (_initializing)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Loading marker database…',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 통인시장 고양이 손 흔들기 오버레이 — jung11 마커 인식 시 4초간 노출.
          // tongin_cat_flutter_handoff.md §5 의 Stack 오버레이 패턴.
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                opacity: _showCatOverlay ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 180),
                    child: PngSequenceAnimator(
                      frames: tonginCatWaveFrames,
                      fps: 8,
                      width: 220,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 상단 스코어 바
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Found: ${_foundMarkers.length} / ${kTreasureMarkers.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '$_score pts',
                      style: const TextStyle(
                          color: Color(0xFFFFC107),
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 하단 마지막 발견 카드
          if (_lastFound != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(blurRadius: 8, color: Colors.black26),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emoji_events,
                              color: Color(0xFFFFC107)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lastFound!.label,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '+${_lastFound!.rewardPts}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E6BFF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lastFound!.clue,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
