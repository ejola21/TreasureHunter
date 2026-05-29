// game/play_models.dart — 플레이 상태 모델 (MissionInPlay/MissionItemInPlay/ItemRnPInPlay 이식).

class MissionInPlay {
  final String missionID;
  final String playerID;
  String startYN; // "Y"/"N"
  String endYN;
  DateTime? startTime;
  DateTime? endTime;

  MissionInPlay({
    required this.missionID,
    required this.playerID,
    this.startYN = 'N',
    this.endYN = 'N',
    this.startTime,
    this.endTime,
  });

  bool get hasStarted => startYN == 'Y';
}

class MissionItemInPlay {
  final String missionID;
  final String playerID;
  final int itemID;
  String endYN; // "Y"/"N"
  int failCnt;
  DateTime? startTime;
  DateTime? endTime;
  int quizSeq;

  MissionItemInPlay({
    required this.missionID,
    required this.playerID,
    required this.itemID,
    this.endYN = 'N',
    this.failCnt = 0,
    this.startTime,
    this.endTime,
    this.quizSeq = 1,
  });
}

class ItemRnPInPlay {
  final String missionID;
  final String playerID;
  final String itemType;
  int ableCnt;
  DateTime? ableTime;
  DateTime? acquiredTime;

  ItemRnPInPlay({
    required this.missionID,
    required this.playerID,
    required this.itemType,
    this.ableCnt = 0,
    this.ableTime,
    this.acquiredTime,
  });
}
