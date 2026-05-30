// models/mission.dart — Mission.swift 이식 (다중포맷 디코딩: LimitTime/Status/Virtual/날짜).
import 'game_state.dart';
import 'mission_item.dart';
import 'parse_utils.dart';

class Mission {
  String id; // MissionID
  String title;
  String description;
  String place;
  String designer;
  DateTime? startTime;
  int limitTime; // 초. 서버 "HH:MM:SS" → 변환. 0=무제한
  String quiz;
  String answer;
  MissionStatus status;
  List<MissionItem> items;
  DateTime writeDate;
  PlayMode isVirtual;
  int seq;
  String lang;

  // 서버 추가 필드
  int playCnt;
  int failCnt;
  int recommendCnt;
  double recommendAvg;
  String shortUser1, shortUser2, shortUser3;
  String shortRecord1, shortRecord2, shortRecord3;
  String? badgeImageName;

  Mission({
    required this.id,
    this.title = '',
    this.description = '',
    this.place = '',
    this.designer = '',
    this.startTime,
    this.limitTime = 0,
    this.quiz = '',
    this.answer = '',
    this.status = MissionStatus.unpublished,
    List<MissionItem>? items,
    DateTime? writeDate,
    this.isVirtual = PlayMode.real,
    this.seq = 0,
    this.lang = '',
    this.playCnt = 0,
    this.failCnt = 0,
    this.recommendCnt = 0,
    this.recommendAvg = 0,
    this.shortUser1 = '',
    this.shortUser2 = '',
    this.shortUser3 = '',
    this.shortRecord1 = '',
    this.shortRecord2 = '',
    this.shortRecord3 = '',
    this.badgeImageName,
  })  : items = items ?? [],
        writeDate = writeDate ?? DateTime.now();

  factory Mission.fromJson(Map<String, dynamic> j) {
    // LimitTime: "HH:MM:SS" 문자열 또는 Int 초.
    final rawLimit = j['LimitTime'];
    final int limit = rawLimit is String
        ? parseHms(rawLimit)
        : (rawLimit is num ? (rawLimit.toInt() < 0 ? 0 : rawLimit.toInt()) : 0);

    // Status: Int(0/2) 또는 문자열("0"/"2"). 알 수 없으면 unpublished.
    final rawStatus = j['Status'];
    final int statusInt = rawStatus is num
        ? rawStatus.toInt()
        : (rawStatus is String ? (int.tryParse(rawStatus) ?? 0) : 0);

    // Virtual: Bool 또는 Int.
    final rawVirtual = j['Virtual'];
    final PlayMode virtual = rawVirtual is bool
        ? (rawVirtual ? PlayMode.virtual : PlayMode.real)
        : PlayMode.fromInt((rawVirtual as num?)?.toInt() ?? 0);

    final itemsJson = j['items'] as List<dynamic>?;

    return Mission(
      id: j['MissionID'] as String,
      title: j['Title'] as String? ?? '',
      description: j['Description'] as String? ?? '',
      place: j['Place'] as String? ?? '',
      designer: j['Designer'] as String? ?? '',
      startTime: parseFlexibleDate(j['StartTime'] as String?),
      limitTime: limit,
      quiz: j['Quiz'] as String? ?? '',
      answer: j['Answer'] as String? ?? '',
      status: MissionStatus.fromInt(statusInt),
      items: itemsJson
          ?.map((e) => MissionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      writeDate: parseFlexibleDate(j['WriteDate'] as String?) ?? DateTime.now(),
      isVirtual: virtual,
      seq: (j['seq'] as num?)?.toInt() ?? 0,
      lang: j['lang'] as String? ?? '',
      playCnt: (j['PlayCnt'] as num?)?.toInt() ?? 0,
      failCnt: (j['FailCnt'] as num?)?.toInt() ?? 0,
      recommendCnt: (j['RecommendCnt'] as num?)?.toInt() ?? 0,
      recommendAvg: (j['RecommendAvg'] as num?)?.toDouble() ?? 0,
      shortUser1: j['ShortUser1'] as String? ?? '',
      shortUser2: j['ShortUser2'] as String? ?? '',
      shortUser3: j['ShortUser3'] as String? ?? '',
      shortRecord1: j['ShortRecord1'] as String? ?? '',
      shortRecord2: j['ShortRecord2'] as String? ?? '',
      shortRecord3: j['ShortRecord3'] as String? ?? '',
      badgeImageName: j['BadgeImageName'] as String?,
    );
  }

  /// 뱃지 다운로드 URL.
  /// - http(s):// 시작 → 그대로 사용
  /// - "/badge/..." 절대경로 → 호스트(43.201.188.35:8080) + path
  /// - "badge-xxx.png" 단순 파일명 → `…/playspot/badge/<name>` (레거시 경로)
  String? get badgeImageUrl {
    final name = badgeImageName;
    if (name == null || name.isEmpty) return null;
    if (name.startsWith('http://') || name.startsWith('https://')) return name;
    if (name.startsWith('/')) return 'http://43.201.188.35:8080$name';
    return 'http://43.201.188.35:8080/playspot/badge/$name';
  }
}
