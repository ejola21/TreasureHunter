// features/design/image_crop_page.dart — SwiftUI ImageCropView.swift 1:1.
// 1:1 정사각 크롭: 드래그 + 핀치 줌. 외부 plugin 없음 — RepaintBoundary.toImage() 스냅샷 후
// 정사각 hole 영역만 잘라 PNG bytes 반환.
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../design_system/duo_tokens.dart';

class ImageCropPage extends StatefulWidget {
  /// 원본 이미지 bytes (PNG/JPEG 어느 쪽이든 Flutter 가 디코딩).
  final Uint8List imageBytes;
  final double cropPadding;
  const ImageCropPage({super.key, required this.imageBytes, this.cropPadding = 24});

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  final GlobalKey _boundaryKey = GlobalKey();
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset _lastFocalPoint = Offset.zero;
  double _lastScale = 1.0;
  Offset _lastOffset = Offset.zero;
  bool _busy = false;

  Future<void> _apply() async {
    if (_busy) return;
    setState(() => _busy = true);
    // 비동기 진입 전에 context 값들을 모두 캡쳐.
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final size = MediaQuery.of(context).size;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image snap = await boundary.toImage(pixelRatio: dpr);

      final side = (size.shortestSide - widget.cropPadding * 2).clamp(50.0, double.infinity);
      // RepaintBoundary 가 차지하는 영역 (Stack/Crop UI 전체 화면) 기준.
      final boundarySize = boundary.size;
      // 정사각 hole 의 boundary 내부 위치 (중앙).
      final holeLeft = (boundarySize.width - side) / 2;
      final holeTop = (boundarySize.height - side) / 2;

      // dpr 적용해 ui.Image pixel 좌표로.
      final pxLeft = (holeLeft * dpr).round();
      final pxTop = (holeTop * dpr).round();
      final pxSide = (side * dpr).round();

      // ui.Image → 잘라낸 영역 PNG bytes.
      final cropped = await _cropImage(snap, pxLeft, pxTop, pxSide, pxSide);
      navigator.pop(cropped);
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text('크롭 실패: $e')));
    }
  }

  /// ui.Image 의 일부 영역만 PNG 로 다시 인코딩.
  Future<Uint8List> _cropImage(ui.Image src, int x, int y, int w, int h) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      src,
      Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()),
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint(),
    );
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(w, h);
    final bd = await cropped.toByteData(format: ui.ImageByteFormat.png);
    src.dispose();
    cropped.dispose();
    return bd!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final side = (size.shortestSide - widget.cropPadding * 2).clamp(50.0, double.infinity);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(children: [
          RepaintBoundary(
            key: _boundaryKey,
            child: Stack(children: [
              // 검정 배경 + 사용자 이동/스케일 이미지.
              Positioned.fill(child: Container(color: Colors.black)),
              Positioned.fill(
                child: GestureDetector(
                  onScaleStart: (d) {
                    _lastFocalPoint = d.focalPoint;
                    _lastScale = _scale;
                    _lastOffset = _offset;
                  },
                  onScaleUpdate: (d) {
                    setState(() {
                      _scale = (_lastScale * d.scale).clamp(0.5, 5.0);
                      final delta = d.focalPoint - _lastFocalPoint;
                      _offset = _lastOffset + delta;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Transform.translate(
                    offset: _offset,
                    child: Transform.scale(
                      scale: _scale,
                      child: Center(child: Image.memory(widget.imageBytes, fit: BoxFit.contain)),
                    ),
                  ),
                ),
              ),
              // 어두운 마스크 + 정사각 hole. ColorFiltered + ClipPath 로 구현.
              IgnorePointer(
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
                  child: Stack(children: [
                    Positioned.fill(
                      child: Container(decoration: const BoxDecoration(color: Colors.transparent, backgroundBlendMode: BlendMode.dstOut)),
                    ),
                    Center(child: Container(width: side, height: side, color: Colors.black)),
                  ]),
                ),
              ),
              // 크롭 가이드 흰 사각 테두리.
              IgnorePointer(
                child: Center(
                  child: Container(
                    width: side, height: side,
                    decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
                  ),
                ),
              ),
            ]),
          ),
          // 상단 안내.
          Positioned(
            top: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('드래그 + 핀치로 영역 조정',
                  style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ),
          // 하단 취소 / 적용.
          Positioned(
            left: 20, right: 20, bottom: 20,
            child: Row(children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _busy ? null : () => Navigator.of(context).pop(null),
                    child: const Text('취소',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _busy ? null : _apply,
                    child: _busy
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: DuoColors.macaw))
                        : const Text('적용',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
