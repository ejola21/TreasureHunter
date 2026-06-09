# Tongin Market AR Cat Wave — Flutter Handoff

## 1. 목적

통인시장 간판을 마커 기반 AR로 인식했을 때 화면에 표시할 **고양이 가이드 캐릭터 손 흔들기 애니메이션**을 Flutter 프로젝트에 적용하기 위한 핸드오프 문서입니다.

- 장소: 서울 서촌 / 통인시장
- AR 트리거: 통인시장 간판 또는 전용 이미지 마커 인식
- 표현 방식: 8프레임 PNG 시퀀스 애니메이션
- 스타일: 세련되고 심플한 카툰, K-레트로, 딥그린/골드 포인트
- 사용 위치: AR 카메라 화면 위 오버레이 또는 마커 인식 후 안내 캐릭터

---

## 2. 제공 에셋

### 권장 폴더 구조

```text
assets/
  ar/
    tongin_market/
      cat_wave/
        tongin_cat_wave_01.png
        tongin_cat_wave_02.png
        tongin_cat_wave_03.png
        tongin_cat_wave_04.png
        tongin_cat_wave_05.png
        tongin_cat_wave_06.png
        tongin_cat_wave_07.png
        tongin_cat_wave_08.png
```

### 프레임 정보

| 항목 | 값 |
|---|---|
| 프레임 수 | 8장 |
| 권장 FPS | 8fps |
| 루프 | true |
| 캔버스 | 모든 프레임 동일 크기 유지 |
| 배경 | 투명 PNG 권장 |
| 용도 | AR 캐릭터 오버레이, 미션 시작 안내, 포토모드 장식 |

### 프레임 역할

| 파일명 | 역할 |
|---|---|
| `tongin_cat_wave_01.png` | 기본 포즈 / 손 낮음 |
| `tongin_cat_wave_02.png` | 손 올라가기 시작 |
| `tongin_cat_wave_03.png` | 손 중간 높이 |
| `tongin_cat_wave_04.png` | 손 가장 높음 |
| `tongin_cat_wave_05.png` | 손 내려오기 시작 |
| `tongin_cat_wave_06.png` | 손 중간 복귀 |
| `tongin_cat_wave_07.png` | 기본 포즈 근접 |
| `tongin_cat_wave_08.png` | 루프 연결용 포즈 |

---

## 3. `pubspec.yaml` 등록

Flutter 프로젝트의 `pubspec.yaml`에 아래 asset 경로를 추가합니다.

```yaml
flutter:
  assets:
    - assets/ar/tongin_market/cat_wave/
```

등록 후 실행:

```bash
flutter pub get
```

---

## 4. Flutter PNG 시퀀스 애니메이션 위젯

아래 위젯은 8프레임 PNG를 반복 재생합니다.

```dart
import 'dart:async';
import 'package:flutter/material.dart';

class PngSequenceAnimator extends StatefulWidget {
  const PngSequenceAnimator({
    super.key,
    required this.frames,
    this.fps = 8,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final List<String> frames;
  final int fps;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<PngSequenceAnimator> createState() => _PngSequenceAnimatorState();
}

class _PngSequenceAnimatorState extends State<PngSequenceAnimator> {
  Timer? _timer;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final frame in widget.frames) {
      precacheImage(AssetImage(frame), context);
    }
  }

  @override
  void initState() {
    super.initState();
    final intervalMs = (1000 / widget.fps).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (!mounted || widget.frames.isEmpty) return;
      setState(() {
        _index = (_index + 1) % widget.frames.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Image.asset(
      widget.frames[_index],
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
    );
  }
}
```

---

## 5. 사용 예시

```dart
final tonginCatWaveFrames = List.generate(
  8,
  (index) =>
      'assets/ar/tongin_market/cat_wave/tongin_cat_wave_${(index + 1).toString().padLeft(2, '0')}.png',
);

class TonginMarketArOverlay extends StatelessWidget {
  const TonginMarketArOverlay({super.key, required this.markerFound});

  final bool markerFound;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: AnimatedOpacity(
        opacity: markerFound ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: PngSequenceAnimator(
              frames: tonginCatWaveFrames,
              fps: 8,
              width: 220,
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 6. AR 화면 적용 구조

### 빠른 MVP 방식

AR 화면 위에 Flutter `Stack`으로 PNG 시퀀스를 올립니다.

```dart
Stack(
  children: [
    // AR 카메라 / ARView 영역
    Positioned.fill(
      child: ArViewWidget(),
    ),

    // 마커 인식 후 고양이 등장
    Positioned.fill(
      child: TonginMarketArOverlay(markerFound: markerFound),
    ),

    // 미션 카드 / 버튼 UI
    Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: MissionStartPanel(),
    ),
  ],
)
```

이 방식은 구현이 빠르고 Flutter 프로젝트에 바로 붙이기 좋습니다.

### 고급 방식

고양이를 실제 마커 위치에 붙이고 싶다면 Flutter 오버레이가 아니라 AR 엔진 쪽에서 처리해야 합니다.

- Unity AR Foundation: Sprite Renderer 또는 Texture Swap 방식
- ARCore/ARKit Native: 이미지 plane에 texture frame 교체
- Flutter AR 플러그인: 지원 범위 확인 후 3D node 또는 texture plane 방식 검토

MVP에서는 **Flutter Stack 오버레이 방식**을 먼저 추천합니다.

---

## 7. 마커 인식 후 UX 흐름

```text
1. 사용자가 통인시장 간판을 비춤
2. 마커 인식 성공
3. 고양이 손 흔들기 애니메이션 등장
4. 0.5초 후 정보 카드 등장
5. 오디오 도슨트 자동 재생 또는 재생 버튼 노출
6. Food Mission 카드 노출
7. 사진 촬영 / 미션 완료
8. 스탬프 지급
```

추천 문구:

```text
Welcome to Tongin Market!
Try the Yeopjeon Lunchbox Mission.
```

---

## 8. 성능 가이드

| 항목 | 권장값 |
|---|---:|
| 표시 크기 | 180~260 logical px |
| 재생 속도 | 8fps |
| 프레임 수 | 8장 |
| 캐릭터 표시 시간 | 2~4초 또는 미션 시작 전까지 |
| 이미지 해상도 | 앱 내 표시용 512~1024px 권장 |
| 프레임 사전 로딩 | 필수 |

주의사항:

- AR 카메라가 켜진 상태에서는 이미지가 너무 크면 저가폰에서 프레임 드랍이 생길 수 있습니다.
- 화면 표시 크기가 200px 정도라면 512px PNG로도 충분합니다.
- 사진 촬영용으로 크게 합성할 경우 1024px 버전을 별도로 유지하는 것이 좋습니다.
- 모든 프레임은 같은 캔버스 크기와 같은 캐릭터 중심점을 유지해야 흔들림이 적습니다.

---

## 9. 추천 이벤트 상태값

```dart
enum TonginArState {
  idle,
  scanningMarker,
  markerFound,
  catGreeting,
  infoCardVisible,
  missionReady,
  missionInProgress,
  missionClear,
}
```

상태 전환 예시:

```text
scanningMarker
→ markerFound
→ catGreeting
→ infoCardVisible
→ missionReady
→ missionInProgress
→ missionClear
```

---

## 10. QA 체크리스트

- [ ] 8개 PNG 파일명이 연속 번호로 되어 있는가?
- [ ] 모든 프레임의 캔버스 크기가 같은가?
- [ ] 캐릭터 위치가 프레임마다 크게 흔들리지 않는가?
- [ ] 배경이 실제 투명 PNG인가?
- [ ] Flutter에서 `gaplessPlayback: true`를 적용했는가?
- [ ] `precacheImage`로 프레임을 미리 로딩했는가?
- [ ] AR 카메라 위에서 30fps 이상 유지되는가?
- [ ] iOS/Android 실기기에서 메모리 사용량을 확인했는가?
- [ ] 사진 촬영 시 캐릭터가 같이 저장되는가?
- [ ] 마커 인식 실패 시 QR 또는 수동 미션 시작 버튼이 있는가?

---

## 11. 개발자 전달 메모

현재 에셋은 통인시장 AR 진입 시 **친근한 첫 인사 캐릭터** 역할입니다. 3D 모델이 아니라 2D PNG 시퀀스이므로, AR 공간 고정형 오브젝트라기보다 **AR 카메라 위 안내 오버레이**로 먼저 적용하는 것이 안정적입니다.

추후 Unity AR Foundation 또는 3D GLB 캐릭터로 확장할 경우, 같은 캐릭터 디자인을 기반으로 3D 모델링/리깅을 진행하면 됩니다.
