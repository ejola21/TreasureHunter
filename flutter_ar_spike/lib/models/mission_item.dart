// models/mission_item.dart — MissionItem.swift 이식.
import 'package:latlong2/latlong.dart';
import 'game_state.dart';
import 'item_type.dart';
import 'item_quiz.dart';
import 'show_type.dart';

class MissionItem {
  String missionID;
  int itemID;
  MandatoryFlag mandatory;
  ItemType itemType;
  double latitude;
  double longitude;
  int blackCnt;
  int blackTime;
  int rangeAR;
  ShowType showType;
  int effectiveRange;
  int effectiveTime;
  int itemGame;
  String info;
  int relationItemID;
  int quizSeq;
  int rnpSeq;
  List<ItemQuiz> quizzes;

  MissionItem({
    required this.missionID,
    required this.itemID,
    this.mandatory = MandatoryFlag.optional,
    this.itemType = ItemType.simple,
    this.latitude = 0,
    this.longitude = 0,
    this.blackCnt = 5,
    this.blackTime = 300,
    this.rangeAR = 30,
    this.showType = ShowType.all,
    this.effectiveRange = 0,
    this.effectiveTime = 0,
    this.itemGame = 0,
    this.info = '',
    this.relationItemID = 0,
    this.quizSeq = 1,
    this.rnpSeq = 0,
    List<ItemQuiz>? quizzes,
  }) : quizzes = quizzes ?? [];

  String get id => '${missionID}_$itemID';
  LatLng get coordinate => LatLng(latitude, longitude);
  bool get isMandatory => mandatory == MandatoryFlag.mandatory;
  bool get isMiniGame => itemType == ItemType.simple && itemGame > 0;
  String get mapIconName => itemType.mapIcon(mandatory: isMandatory);
  String get arIconName => itemType.arIcon(mandatory: isMandatory);

  factory MissionItem.fromJson(Map<String, dynamic> j) {
    final quizJson = j['quizzes'] as List<dynamic>?;
    return MissionItem(
      missionID: j['MissionID'] as String? ?? '',
      itemID: (j['ItemID'] as num).toInt(),
      mandatory: MandatoryFlag.fromInt((j['Mandatory'] as num?)?.toInt() ?? 0),
      itemType: ItemType.fromCode(j['ItemType']?.toString()),
      latitude: (j['Latitude'] as num?)?.toDouble() ?? 0,
      longitude: (j['Longitude'] as num?)?.toDouble() ?? 0,
      blackCnt: (j['BlackCnt'] as num?)?.toInt() ?? 5,
      blackTime: (j['BlackTime'] as num?)?.toInt() ?? 300,
      rangeAR: (j['RangeAR'] as num?)?.toInt() ?? 30,
      showType: ShowType.fromCode(j['ShowType']?.toString()),
      effectiveRange: (j['EffectiveRange'] as num?)?.toInt() ?? 0,
      effectiveTime: (j['EffectiveTime'] as num?)?.toInt() ?? 0,
      itemGame: (j['ItemGame'] as num?)?.toInt() ?? 0,
      info: j['Info'] as String? ?? '',
      relationItemID: (j['RelationItemID'] as num?)?.toInt() ?? 0,
      quizSeq: (j['quizSeq'] as num?)?.toInt() ?? 1,
      rnpSeq: (j['rnpSeq'] as num?)?.toInt() ?? 0,
      quizzes: quizJson
          ?.map((e) => ItemQuiz.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
