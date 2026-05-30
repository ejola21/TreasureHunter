// features/play/map_play.dart — 맵 플레이 (flutter_map: 아이템 핀 + mine/dark 원).
// SwiftUI MissionPlayView (지도 영역) 이식. 핀 탭은 callout 정보 표시 전용 —
// 획득은 절대 일어나지 않는다 (모든 획득은 AR 화면에서만, 레거시 MissionPlay.m:1979-1981).
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../design_system/duo_tokens.dart';
import '../../game/game_engine.dart';
import '../../models/item_type.dart';
import '../../models/mission_item.dart';

class MapPlay extends StatelessWidget {
  final GameEngine engine;
  final LatLng? player;
  final void Function(MissionItem) onPinTap;
  final MapController? controller;
  const MapPlay({super.key, required this.engine, this.player, required this.onPinTap, this.controller});

  @override
  Widget build(BuildContext context) {
    final center = player ??
        (engine.items.isNotEmpty ? engine.items.first.coordinate : const LatLng(37.5665, 126.9780));
    final visible = engine.items.where(engine.shouldShowOnMap).toList();
    return FlutterMap(
      mapController: controller,
      options: MapOptions(initialCenter: center, initialZoom: 17),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ejola.playspot',
        ),
        // mine(빨강)/dark(검정) 영역 원 — 미획득만.
        CircleLayer(circles: [
          for (final it in engine.items)
            if ((it.itemType == ItemType.mine || it.itemType == ItemType.black) && engine.dicItemEnd[it.itemID] != 'Y')
              CircleMarker(
                point: it.coordinate,
                radius: it.rangeAR.toDouble(),
                useRadiusInMeter: true,
                color: (it.itemType == ItemType.mine ? DuoColors.cardinal : Colors.black).withValues(alpha: 0.25),
                borderColor: (it.itemType == ItemType.mine ? DuoColors.cardinal : Colors.black).withValues(alpha: 0.5),
                borderStrokeWidth: 1.5,
              ),
        ]),
        MarkerLayer(markers: [
          if (player != null)
            Marker(point: player!, width: 22, height: 22, child: const _Dot(DuoColors.macaw)),
          for (final it in visible)
            Marker(
              point: it.coordinate,
              width: 54, height: 54,
              child: GestureDetector(
                onTap: () => onPinTap(it), // 정보 표시만 — 획득은 AR 에서.
                child: _pin(it, engine.dicItemEnd[it.itemID] == 'Y'),
              ),
            ),
        ]),
      ],
    );
  }

  // SwiftUI PulseMapPin.swift L406: `.grayscale(1.0)` — 획득 시 풀 desaturation,
  // opacity 는 그대로(=1.0). luminance matrix 로 컬러채널을 그레이 평균값으로 대체.
  static const _grayscaleFilter = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ]);

  Widget _pin(MissionItem it, bool acquired) {
    Widget img = Image.asset(
      it.mapIconName,
      width: 54,
      height: 54,
      errorBuilder: (_, _, _) => Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: it.isMandatory ? DuoColors.fox : DuoColors.green500,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(it.itemType.displayLabel.characters.first,
            style: const TextStyle(color: Colors.white, fontFamily: DuoFonts.display, fontSize: 13)),
      ),
    );
    if (acquired) img = ColorFiltered(colorFilter: _grayscaleFilter, child: img);
    return img;
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
      );
}
