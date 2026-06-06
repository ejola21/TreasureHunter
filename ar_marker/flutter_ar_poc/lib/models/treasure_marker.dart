/// PoC 보물찾기 마커 모델 + 자동 발견 레지스트리.
///
/// **자동 등록**: `assets/markers/<id>.png` 를 추가하면 자동으로 마커가 됨.
/// 코드 수정 불필요. 단 메타데이터 (라벨·단서·점수·실측 크기) 를 더 자세히 정의하려면
/// 아래 `_knownMarkers` 에 항목을 추가하면 됨 — 모르는 마커는 파일명으로 자동 생성.
///
/// 사용:
/// 1. `scripts/add_marker.sh ~/Desktop/내사진.jpg my_new_marker` 로 PNG 추가
/// 2. (선택) 아래 `_knownMarkers` 에 메타데이터 추가
/// 3. `flutter clean && flutter run` 으로 재실행
library;

import 'package:flutter/services.dart';

/// 단일 마커 정의 (런타임에 동적 생성됨).
class TreasureMarker {
  /// 마커 파일명 (확장자 없이) — `assets/markers/<id>.<ext>`
  final String id;

  /// 사용자에게 보이는 라벨
  final String label;

  /// 마커 발견 시 한 줄 단서/플레이버 텍스트
  final String clue;

  /// 보상 포인트
  final int rewardPts;

  /// 실측 크기 (cm) — Day 3 현장 답사 후 채움
  final double widthCm;

  /// 번들된 마커 파일 경로 (전체 경로 — 확장자 포함).
  /// JPEG·JPG·PNG 모두 지원 (ARKit/ARCore 의 UIImage / BitmapFactory 가 처리).
  /// MarkerRegistry 가 파일 발견 시점의 실제 확장자로 채움.
  final String assetPath;

  const TreasureMarker({
    required this.id,
    required this.label,
    required this.clue,
    required this.rewardPts,
    required this.widthCm,
    required this.assetPath,
  });

  static String _humanize(String id) => id
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// 라벨·단서·점수·실측 크기만 정의 (파일 경로는 registry 가 채움).
/// `_knownMarkers` 맵의 값 타입.
class _MarkerMetadata {
  final String label;
  final String clue;
  final int rewardPts;
  final double widthCm;
  const _MarkerMetadata({
    required this.label,
    required this.clue,
    required this.rewardPts,
    required this.widthCm,
  });
}

/// 알려진 마커의 메타데이터 오버라이드.
/// 키 = 파일명 (확장자 제외). 여기 없는 마커는 파일명으로 자동 생성.
const Map<String, _MarkerMetadata> _knownMarkers = {
  'daeo_bookstore': _MarkerMetadata(
    label: 'Daeo Bookstore',
    clue: '60년 된 책방 간판 — 손글씨를 찾아라',
    rewardPts: 200,
    widthCm: 80,
  ),
  'tongin_market': _MarkerMetadata(
    label: 'Tongin Market',
    clue: '시장 정문 안내판 — 빨간 떡볶이 옆',
    rewardPts: 150,
    widthCm: 120,
  ),
  'park_nosoo': _MarkerMetadata(
    label: 'Park No-soo Museum',
    clue: '미술관 정원 동판 — 화가의 흔적',
    rewardPts: 250,
    widthCm: 60,
  ),
  'cafe_sticker_1': _MarkerMetadata(
    label: 'Cafe Slow Sticker',
    clue: 'PVC 스티커 #1 — 카페 외벽',
    rewardPts: 100,
    widthCm: 20,
  ),
  'ghouse_sticker_2': _MarkerMetadata(
    label: 'Guesthouse Sticker',
    clue: 'PVC 스티커 #2 — 게하 입구',
    rewardPts: 100,
    widthCm: 20,
  ),
};

/// 마커로 인식할 이미지 확장자 (소문자, 점 포함).
/// PNG · JPG · JPEG 모두 ARKit/ARCore 가 처리 가능.
const _markerExtensions = {'.png', '.jpg', '.jpeg'};

/// 전역 마커 리스트.
/// **반드시 main() 에서 `MarkerRegistry.load()` 호출 후 사용**.
/// (Flutter PlatformChannel 이 setup 되기 전에는 AssetBundle 접근 불가)
List<TreasureMarker> kTreasureMarkers = const [];

/// 마커 자동 발견·등록 레지스트리.
class MarkerRegistry {
  /// AssetBundle 에서 `assets/markers/*.{png,jpg,jpeg}` 를 모두 스캔.
  ///
  /// - 알려진 마커 (`_knownMarkers`) 는 메타데이터 적용
  /// - 모르는 마커는 파일명으로 자동 생성
  /// - 같은 id 로 png·jpg 둘 다 있으면 png 우선
  ///
  /// 전역 `kTreasureMarkers` 에도 채워짐.
  static Future<List<TreasureMarker>> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    // id → assetPath 매핑 수집. 같은 id 의 다른 확장자는 png > jpg > jpeg 우선.
    final discovered = <String, String>{};
    for (final key in manifest.listAssets()) {
      if (!key.startsWith('assets/markers/')) continue;
      final ext = _extOf(key);
      if (!_markerExtensions.contains(ext)) continue;

      final filename = key.substring('assets/markers/'.length);
      final id = filename.substring(0, filename.length - ext.length);

      // 우선순위: png > jpg > jpeg
      final existing = discovered[id];
      if (existing == null || _extOf(existing) != '.png') {
        discovered[id] = key;
      }
    }

    final ids = discovered.keys.toList()..sort();
    final markers = ids.map((id) {
      final meta = _knownMarkers[id];
      return TreasureMarker(
        id: id,
        label: meta?.label ?? TreasureMarker._humanize(id),
        clue: meta?.clue ?? 'Found a hidden treasure!',
        rewardPts: meta?.rewardPts ?? 100,
        widthCm: meta?.widthCm ?? 20,
        assetPath: discovered[id]!,
      );
    }).toList();

    kTreasureMarkers = markers;
    return markers;
  }

  static String _extOf(String path) {
    final i = path.lastIndexOf('.');
    if (i < 0) return '';
    return path.substring(i).toLowerCase();
  }
}
