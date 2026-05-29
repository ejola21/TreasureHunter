// game/play_alert.dart — 아이템 획득/이벤트 알림 (ItemAcquiredAlert 이식).
class ItemAcquiredAlert {
  final String title;
  final String message;
  final String itemIconName;
  const ItemAcquiredAlert({required this.title, required this.message, this.itemIconName = ''});
}
