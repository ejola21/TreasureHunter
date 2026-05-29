// features/play/map_play.dart — 맵 플레이 (flutter_map: 아이템 핀 + mine/dark 원 + 획득).
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../design_system/duo_tokens.dart';
import '../../game/game_engine.dart';
import '../../models/item_type.dart';
import '../../models/mission_item.dart';

const _dist = Distance();

class MapPlay extends StatelessWidget {
  final GameEngine engine;
  final LatLng? player;
  const MapPlay({super.key, required this.engine, this.player});

  void _tryAcquire(BuildContext context, MissionItem it) {
    if (engine.dicItemEnd[it.itemID] == 'Y') return;
    if (player != null && _dist(player!, it.coordinate) > it.rangeAR) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${it.itemType.displayLabel} — 더 가까이 가세요 (반경 ${it.rangeAR}m)')),
      );
      return;
    }
    engine.acquireItem(it);
  }

  @override
  Widget build(BuildContext context) {
    final center = player ??
        (engine.items.isNotEmpty ? engine.items.first.coordinate : const LatLng(37.5665, 126.9780));
    final visible = engine.items.where(engine.shouldShowOnMap).toList();
    return FlutterMap(
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
              width: 46, height: 46,
              child: GestureDetector(
                onTap: () => _tryAcquire(context, it),
                child: _pin(it, engine.dicItemEnd[it.itemID] == 'Y'),
              ),
            ),
        ]),
      ],
    );
  }

  Widget _pin(MissionItem it, bool acquired) => Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: acquired ? DuoColors.hare : (it.isMandatory ? DuoColors.fox : DuoColors.green500),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(it.itemType.displayLabel.characters.first,
            style: const TextStyle(color: Colors.white, fontFamily: DuoFonts.display, fontSize: 13)),
      );
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
      );
}
