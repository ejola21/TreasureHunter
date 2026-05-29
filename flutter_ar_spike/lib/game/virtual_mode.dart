// game/virtual_mode.dart — VirtualModeManager 대응 (가상 모드 좌표 오프셋).
// start 아이템을 현재 플레이어 위치로 정렬하도록 전체 아이템 좌표를 평행이동.
import 'package:latlong2/latlong.dart';
import '../models/item_type.dart';
import '../models/mission_item.dart';

class VirtualModeManager {
  /// items 를 제자리 수정. player 위치가 없으면 false (미적용).
  static bool applyOffset(List<MissionItem> items, LatLng? player, {required bool isNewStart}) {
    if (player == null) return false;
    final start = items.where((it) => it.itemType == ItemType.start).firstOrNull;
    if (start == null) return false;
    final dLat = player.latitude - start.latitude;
    final dLon = player.longitude - start.longitude;
    for (final it in items) {
      it.latitude += dLat;
      it.longitude += dLon;
    }
    return true;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
