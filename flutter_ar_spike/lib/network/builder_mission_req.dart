// network/builder_mission_req.dart — RestAPIDTO.swift BuilderMissionReq 이식.
// POST/PATCH /api/v1/missions 요청 body. 서버 필드명(PascalCase) 그대로.
import '../models/mission.dart';
import '../models/parse_utils.dart';

class BuilderMissionReq {
  final BuilderMissionFields mission;
  final List<BuilderItemFields> items;
  final List<BuilderQuizFields> quizzes;
  const BuilderMissionReq({required this.mission, required this.items, required this.quizzes});

  Map<String, dynamic> toJson() => {
        'mission': mission.toJson(),
        'items': items.map((e) => e.toJson()).toList(),
        'quizzes': quizzes.map((e) => e.toJson()).toList(),
      };

  /// Mission(+items+quizzes) → 요청 body 조립. MissionID/Designer/WriteDate 는 서버 발급이라 제외.
  factory BuilderMissionReq.fromMission(Mission m) {
    final items = m.items
        .map((it) => BuilderItemFields(
              itemID: it.itemID,
              mandatory: it.mandatory.value,
              itemType: it.itemType.code,
              latitude: it.latitude,
              longitude: it.longitude,
              blackCnt: it.blackCnt,
              blackTime: it.blackTime,
              rangeAR: it.rangeAR,
              showType: it.showType.code,
              effectiveRange: it.effectiveRange,
              effectiveTime: it.effectiveTime,
              itemGame: it.itemGame,
              info: it.info,
              relationItemID: it.relationItemID,
            ))
        .toList();
    final quizzes = <BuilderQuizFields>[];
    for (final it in m.items) {
      for (final q in it.quizzes) {
        quizzes.add(BuilderQuizFields(
          itemID: it.itemID,
          seq: q.seq,
          quiz: q.quiz,
          answer: q.answer,
          probability: q.probability,
        ));
      }
    }
    return BuilderMissionReq(
      mission: BuilderMissionFields(
        title: m.title,
        description: m.description,
        place: m.place,
        limitTime: hmsString(m.limitTime),
        status: m.status.value,
        virtual: m.isVirtual.value,
        lang: m.lang,
        badgeImageName: m.badgeImageName,
      ),
      items: items,
      quizzes: quizzes,
    );
  }
}

class BuilderMissionFields {
  final String title, description, place, limitTime, lang;
  final int status, virtual;
  final String? badgeImageName;
  const BuilderMissionFields({
    required this.title,
    required this.description,
    required this.place,
    required this.limitTime,
    required this.status,
    required this.virtual,
    required this.lang,
    this.badgeImageName,
  });
  Map<String, dynamic> toJson() => {
        'Title': title,
        'Description': description,
        'Place': place,
        'LimitTime': limitTime,
        'Status': status,
        'Virtual': virtual,
        'Lang': lang,
        'BadgeImageName': badgeImageName,
      };
}

class BuilderItemFields {
  final int itemID, mandatory, blackCnt, blackTime, rangeAR, effectiveRange, effectiveTime, itemGame, relationItemID;
  final String itemType, showType, info;
  final double latitude, longitude;
  const BuilderItemFields({
    required this.itemID,
    required this.mandatory,
    required this.itemType,
    required this.latitude,
    required this.longitude,
    required this.blackCnt,
    required this.blackTime,
    required this.rangeAR,
    required this.showType,
    required this.effectiveRange,
    required this.effectiveTime,
    required this.itemGame,
    required this.info,
    required this.relationItemID,
  });
  Map<String, dynamic> toJson() => {
        'ItemID': itemID,
        'Mandatory': mandatory,
        'ItemType': itemType,
        'Latitude': latitude,
        'Longitude': longitude,
        'BlackCnt': blackCnt,
        'BlackTime': blackTime,
        'RangeAR': rangeAR,
        'ShowType': showType,
        'EffectiveRange': effectiveRange,
        'EffectiveTime': effectiveTime,
        'ItemGame': itemGame,
        'Info': info,
        'RelationItemID': relationItemID,
      };
}

class BuilderQuizFields {
  final int itemID, seq, probability;
  final String quiz, answer;
  const BuilderQuizFields({
    required this.itemID,
    required this.seq,
    required this.quiz,
    required this.answer,
    required this.probability,
  });
  Map<String, dynamic> toJson() => {
        'ItemID': itemID,
        'Seq': seq,
        'Quiz': quiz,
        'Answer': answer,
        'Probability': probability,
      };
}
