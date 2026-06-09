/// PNG 시퀀스 애니메이션 위젯.
/// 출처: tongin_cat_flutter_handoff.md §4 (8 fps 권장).
library;

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

  /// 에셋 경로 리스트 (예: assets/ar/.../frame_01.png)
  final List<String> frames;

  /// 초당 프레임 수
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
    // 모든 프레임 사전 로딩 — 첫 회 깜빡임 방지.
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

/// 통인시장 고양이 손 흔들기 — 8프레임.
/// jung11 마커 인식 시 카메라 화면 위에 오버레이로 표시.
final tonginCatWaveFrames = List.generate(
  8,
  (index) =>
      'assets/ar/tongin_market/cat_wave/tongin_cat_wave_${(index + 1).toString().padLeft(2, '0')}.png',
);
