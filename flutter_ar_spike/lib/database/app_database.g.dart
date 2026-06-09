// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MissionInPlayTableTable extends MissionInPlayTable
    with TableInfo<$MissionInPlayTableTable, MissionInPlayTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MissionInPlayTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _missionIDMeta = const VerificationMeta(
    'missionID',
  );
  @override
  late final GeneratedColumn<String> missionID = GeneratedColumn<String>(
    'mission_i_d',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerIDMeta = const VerificationMeta(
    'playerID',
  );
  @override
  late final GeneratedColumn<String> playerID = GeneratedColumn<String>(
    'player_i_d',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startYNMeta = const VerificationMeta(
    'startYN',
  );
  @override
  late final GeneratedColumn<String> startYN = GeneratedColumn<String>(
    'start_y_n',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('N'),
  );
  static const VerificationMeta _endYNMeta = const VerificationMeta('endYN');
  @override
  late final GeneratedColumn<String> endYN = GeneratedColumn<String>(
    'end_y_n',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('N'),
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    missionID,
    playerID,
    startYN,
    endYN,
    startTime,
    endTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mission_in_play';
  @override
  VerificationContext validateIntegrity(
    Insertable<MissionInPlayTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mission_i_d')) {
      context.handle(
        _missionIDMeta,
        missionID.isAcceptableOrUnknown(data['mission_i_d']!, _missionIDMeta),
      );
    } else if (isInserting) {
      context.missing(_missionIDMeta);
    }
    if (data.containsKey('player_i_d')) {
      context.handle(
        _playerIDMeta,
        playerID.isAcceptableOrUnknown(data['player_i_d']!, _playerIDMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIDMeta);
    }
    if (data.containsKey('start_y_n')) {
      context.handle(
        _startYNMeta,
        startYN.isAcceptableOrUnknown(data['start_y_n']!, _startYNMeta),
      );
    }
    if (data.containsKey('end_y_n')) {
      context.handle(
        _endYNMeta,
        endYN.isAcceptableOrUnknown(data['end_y_n']!, _endYNMeta),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {missionID, playerID};
  @override
  MissionInPlayTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MissionInPlayTableData(
      missionID: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mission_i_d'],
      )!,
      playerID: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_i_d'],
      )!,
      startYN: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_y_n'],
      )!,
      endYN: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_y_n'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      ),
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
    );
  }

  @override
  $MissionInPlayTableTable createAlias(String alias) {
    return $MissionInPlayTableTable(attachedDatabase, alias);
  }
}

class MissionInPlayTableData extends DataClass
    implements Insertable<MissionInPlayTableData> {
  final String missionID;
  final String playerID;
  final String startYN;
  final String endYN;
  final DateTime? startTime;
  final DateTime? endTime;
  const MissionInPlayTableData({
    required this.missionID,
    required this.playerID,
    required this.startYN,
    required this.endYN,
    this.startTime,
    this.endTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mission_i_d'] = Variable<String>(missionID);
    map['player_i_d'] = Variable<String>(playerID);
    map['start_y_n'] = Variable<String>(startYN);
    map['end_y_n'] = Variable<String>(endYN);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<DateTime>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    return map;
  }

  MissionInPlayTableCompanion toCompanion(bool nullToAbsent) {
    return MissionInPlayTableCompanion(
      missionID: Value(missionID),
      playerID: Value(playerID),
      startYN: Value(startYN),
      endYN: Value(endYN),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
    );
  }

  factory MissionInPlayTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MissionInPlayTableData(
      missionID: serializer.fromJson<String>(json['missionID']),
      playerID: serializer.fromJson<String>(json['playerID']),
      startYN: serializer.fromJson<String>(json['startYN']),
      endYN: serializer.fromJson<String>(json['endYN']),
      startTime: serializer.fromJson<DateTime?>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'missionID': serializer.toJson<String>(missionID),
      'playerID': serializer.toJson<String>(playerID),
      'startYN': serializer.toJson<String>(startYN),
      'endYN': serializer.toJson<String>(endYN),
      'startTime': serializer.toJson<DateTime?>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
    };
  }

  MissionInPlayTableData copyWith({
    String? missionID,
    String? playerID,
    String? startYN,
    String? endYN,
    Value<DateTime?> startTime = const Value.absent(),
    Value<DateTime?> endTime = const Value.absent(),
  }) => MissionInPlayTableData(
    missionID: missionID ?? this.missionID,
    playerID: playerID ?? this.playerID,
    startYN: startYN ?? this.startYN,
    endYN: endYN ?? this.endYN,
    startTime: startTime.present ? startTime.value : this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
  );
  MissionInPlayTableData copyWithCompanion(MissionInPlayTableCompanion data) {
    return MissionInPlayTableData(
      missionID: data.missionID.present ? data.missionID.value : this.missionID,
      playerID: data.playerID.present ? data.playerID.value : this.playerID,
      startYN: data.startYN.present ? data.startYN.value : this.startYN,
      endYN: data.endYN.present ? data.endYN.value : this.endYN,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MissionInPlayTableData(')
          ..write('missionID: $missionID, ')
          ..write('playerID: $playerID, ')
          ..write('startYN: $startYN, ')
          ..write('endYN: $endYN, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(missionID, playerID, startYN, endYN, startTime, endTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MissionInPlayTableData &&
          other.missionID == this.missionID &&
          other.playerID == this.playerID &&
          other.startYN == this.startYN &&
          other.endYN == this.endYN &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime);
}

class MissionInPlayTableCompanion
    extends UpdateCompanion<MissionInPlayTableData> {
  final Value<String> missionID;
  final Value<String> playerID;
  final Value<String> startYN;
  final Value<String> endYN;
  final Value<DateTime?> startTime;
  final Value<DateTime?> endTime;
  final Value<int> rowid;
  const MissionInPlayTableCompanion({
    this.missionID = const Value.absent(),
    this.playerID = const Value.absent(),
    this.startYN = const Value.absent(),
    this.endYN = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MissionInPlayTableCompanion.insert({
    required String missionID,
    required String playerID,
    this.startYN = const Value.absent(),
    this.endYN = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : missionID = Value(missionID),
       playerID = Value(playerID);
  static Insertable<MissionInPlayTableData> custom({
    Expression<String>? missionID,
    Expression<String>? playerID,
    Expression<String>? startYN,
    Expression<String>? endYN,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (missionID != null) 'mission_i_d': missionID,
      if (playerID != null) 'player_i_d': playerID,
      if (startYN != null) 'start_y_n': startYN,
      if (endYN != null) 'end_y_n': endYN,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MissionInPlayTableCompanion copyWith({
    Value<String>? missionID,
    Value<String>? playerID,
    Value<String>? startYN,
    Value<String>? endYN,
    Value<DateTime?>? startTime,
    Value<DateTime?>? endTime,
    Value<int>? rowid,
  }) {
    return MissionInPlayTableCompanion(
      missionID: missionID ?? this.missionID,
      playerID: playerID ?? this.playerID,
      startYN: startYN ?? this.startYN,
      endYN: endYN ?? this.endYN,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (missionID.present) {
      map['mission_i_d'] = Variable<String>(missionID.value);
    }
    if (playerID.present) {
      map['player_i_d'] = Variable<String>(playerID.value);
    }
    if (startYN.present) {
      map['start_y_n'] = Variable<String>(startYN.value);
    }
    if (endYN.present) {
      map['end_y_n'] = Variable<String>(endYN.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MissionInPlayTableCompanion(')
          ..write('missionID: $missionID, ')
          ..write('playerID: $playerID, ')
          ..write('startYN: $startYN, ')
          ..write('endYN: $endYN, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MissionItemInPlayTableTable extends MissionItemInPlayTable
    with TableInfo<$MissionItemInPlayTableTable, MissionItemInPlayTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MissionItemInPlayTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _missionIDMeta = const VerificationMeta(
    'missionID',
  );
  @override
  late final GeneratedColumn<String> missionID = GeneratedColumn<String>(
    'mission_i_d',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerIDMeta = const VerificationMeta(
    'playerID',
  );
  @override
  late final GeneratedColumn<String> playerID = GeneratedColumn<String>(
    'player_i_d',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIDMeta = const VerificationMeta('itemID');
  @override
  late final GeneratedColumn<int> itemID = GeneratedColumn<int>(
    'item_i_d',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endYNMeta = const VerificationMeta('endYN');
  @override
  late final GeneratedColumn<String> endYN = GeneratedColumn<String>(
    'end_y_n',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('N'),
  );
  static const VerificationMeta _failCntMeta = const VerificationMeta(
    'failCnt',
  );
  @override
  late final GeneratedColumn<int> failCnt = GeneratedColumn<int>(
    'fail_cnt',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quizSeqMeta = const VerificationMeta(
    'quizSeq',
  );
  @override
  late final GeneratedColumn<int> quizSeq = GeneratedColumn<int>(
    'quiz_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    missionID,
    playerID,
    itemID,
    endYN,
    failCnt,
    startTime,
    endTime,
    quizSeq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mission_item_in_play';
  @override
  VerificationContext validateIntegrity(
    Insertable<MissionItemInPlayTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mission_i_d')) {
      context.handle(
        _missionIDMeta,
        missionID.isAcceptableOrUnknown(data['mission_i_d']!, _missionIDMeta),
      );
    } else if (isInserting) {
      context.missing(_missionIDMeta);
    }
    if (data.containsKey('player_i_d')) {
      context.handle(
        _playerIDMeta,
        playerID.isAcceptableOrUnknown(data['player_i_d']!, _playerIDMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIDMeta);
    }
    if (data.containsKey('item_i_d')) {
      context.handle(
        _itemIDMeta,
        itemID.isAcceptableOrUnknown(data['item_i_d']!, _itemIDMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIDMeta);
    }
    if (data.containsKey('end_y_n')) {
      context.handle(
        _endYNMeta,
        endYN.isAcceptableOrUnknown(data['end_y_n']!, _endYNMeta),
      );
    }
    if (data.containsKey('fail_cnt')) {
      context.handle(
        _failCntMeta,
        failCnt.isAcceptableOrUnknown(data['fail_cnt']!, _failCntMeta),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('quiz_seq')) {
      context.handle(
        _quizSeqMeta,
        quizSeq.isAcceptableOrUnknown(data['quiz_seq']!, _quizSeqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {missionID, playerID, itemID};
  @override
  MissionItemInPlayTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MissionItemInPlayTableData(
      missionID: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mission_i_d'],
      )!,
      playerID: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_i_d'],
      )!,
      itemID: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_i_d'],
      )!,
      endYN: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_y_n'],
      )!,
      failCnt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fail_cnt'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      ),
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      quizSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quiz_seq'],
      )!,
    );
  }

  @override
  $MissionItemInPlayTableTable createAlias(String alias) {
    return $MissionItemInPlayTableTable(attachedDatabase, alias);
  }
}

class MissionItemInPlayTableData extends DataClass
    implements Insertable<MissionItemInPlayTableData> {
  final String missionID;
  final String playerID;
  final int itemID;
  final String endYN;
  final int failCnt;
  final DateTime? startTime;
  final DateTime? endTime;
  final int quizSeq;
  const MissionItemInPlayTableData({
    required this.missionID,
    required this.playerID,
    required this.itemID,
    required this.endYN,
    required this.failCnt,
    this.startTime,
    this.endTime,
    required this.quizSeq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mission_i_d'] = Variable<String>(missionID);
    map['player_i_d'] = Variable<String>(playerID);
    map['item_i_d'] = Variable<int>(itemID);
    map['end_y_n'] = Variable<String>(endYN);
    map['fail_cnt'] = Variable<int>(failCnt);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<DateTime>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['quiz_seq'] = Variable<int>(quizSeq);
    return map;
  }

  MissionItemInPlayTableCompanion toCompanion(bool nullToAbsent) {
    return MissionItemInPlayTableCompanion(
      missionID: Value(missionID),
      playerID: Value(playerID),
      itemID: Value(itemID),
      endYN: Value(endYN),
      failCnt: Value(failCnt),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      quizSeq: Value(quizSeq),
    );
  }

  factory MissionItemInPlayTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MissionItemInPlayTableData(
      missionID: serializer.fromJson<String>(json['missionID']),
      playerID: serializer.fromJson<String>(json['playerID']),
      itemID: serializer.fromJson<int>(json['itemID']),
      endYN: serializer.fromJson<String>(json['endYN']),
      failCnt: serializer.fromJson<int>(json['failCnt']),
      startTime: serializer.fromJson<DateTime?>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      quizSeq: serializer.fromJson<int>(json['quizSeq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'missionID': serializer.toJson<String>(missionID),
      'playerID': serializer.toJson<String>(playerID),
      'itemID': serializer.toJson<int>(itemID),
      'endYN': serializer.toJson<String>(endYN),
      'failCnt': serializer.toJson<int>(failCnt),
      'startTime': serializer.toJson<DateTime?>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'quizSeq': serializer.toJson<int>(quizSeq),
    };
  }

  MissionItemInPlayTableData copyWith({
    String? missionID,
    String? playerID,
    int? itemID,
    String? endYN,
    int? failCnt,
    Value<DateTime?> startTime = const Value.absent(),
    Value<DateTime?> endTime = const Value.absent(),
    int? quizSeq,
  }) => MissionItemInPlayTableData(
    missionID: missionID ?? this.missionID,
    playerID: playerID ?? this.playerID,
    itemID: itemID ?? this.itemID,
    endYN: endYN ?? this.endYN,
    failCnt: failCnt ?? this.failCnt,
    startTime: startTime.present ? startTime.value : this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    quizSeq: quizSeq ?? this.quizSeq,
  );
  MissionItemInPlayTableData copyWithCompanion(
    MissionItemInPlayTableCompanion data,
  ) {
    return MissionItemInPlayTableData(
      missionID: data.missionID.present ? data.missionID.value : this.missionID,
      playerID: data.playerID.present ? data.playerID.value : this.playerID,
      itemID: data.itemID.present ? data.itemID.value : this.itemID,
      endYN: data.endYN.present ? data.endYN.value : this.endYN,
      failCnt: data.failCnt.present ? data.failCnt.value : this.failCnt,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      quizSeq: data.quizSeq.present ? data.quizSeq.value : this.quizSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MissionItemInPlayTableData(')
          ..write('missionID: $missionID, ')
          ..write('playerID: $playerID, ')
          ..write('itemID: $itemID, ')
          ..write('endYN: $endYN, ')
          ..write('failCnt: $failCnt, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('quizSeq: $quizSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    missionID,
    playerID,
    itemID,
    endYN,
    failCnt,
    startTime,
    endTime,
    quizSeq,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MissionItemInPlayTableData &&
          other.missionID == this.missionID &&
          other.playerID == this.playerID &&
          other.itemID == this.itemID &&
          other.endYN == this.endYN &&
          other.failCnt == this.failCnt &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.quizSeq == this.quizSeq);
}

class MissionItemInPlayTableCompanion
    extends UpdateCompanion<MissionItemInPlayTableData> {
  final Value<String> missionID;
  final Value<String> playerID;
  final Value<int> itemID;
  final Value<String> endYN;
  final Value<int> failCnt;
  final Value<DateTime?> startTime;
  final Value<DateTime?> endTime;
  final Value<int> quizSeq;
  final Value<int> rowid;
  const MissionItemInPlayTableCompanion({
    this.missionID = const Value.absent(),
    this.playerID = const Value.absent(),
    this.itemID = const Value.absent(),
    this.endYN = const Value.absent(),
    this.failCnt = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.quizSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MissionItemInPlayTableCompanion.insert({
    required String missionID,
    required String playerID,
    required int itemID,
    this.endYN = const Value.absent(),
    this.failCnt = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.quizSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : missionID = Value(missionID),
       playerID = Value(playerID),
       itemID = Value(itemID);
  static Insertable<MissionItemInPlayTableData> custom({
    Expression<String>? missionID,
    Expression<String>? playerID,
    Expression<int>? itemID,
    Expression<String>? endYN,
    Expression<int>? failCnt,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<int>? quizSeq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (missionID != null) 'mission_i_d': missionID,
      if (playerID != null) 'player_i_d': playerID,
      if (itemID != null) 'item_i_d': itemID,
      if (endYN != null) 'end_y_n': endYN,
      if (failCnt != null) 'fail_cnt': failCnt,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (quizSeq != null) 'quiz_seq': quizSeq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MissionItemInPlayTableCompanion copyWith({
    Value<String>? missionID,
    Value<String>? playerID,
    Value<int>? itemID,
    Value<String>? endYN,
    Value<int>? failCnt,
    Value<DateTime?>? startTime,
    Value<DateTime?>? endTime,
    Value<int>? quizSeq,
    Value<int>? rowid,
  }) {
    return MissionItemInPlayTableCompanion(
      missionID: missionID ?? this.missionID,
      playerID: playerID ?? this.playerID,
      itemID: itemID ?? this.itemID,
      endYN: endYN ?? this.endYN,
      failCnt: failCnt ?? this.failCnt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      quizSeq: quizSeq ?? this.quizSeq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (missionID.present) {
      map['mission_i_d'] = Variable<String>(missionID.value);
    }
    if (playerID.present) {
      map['player_i_d'] = Variable<String>(playerID.value);
    }
    if (itemID.present) {
      map['item_i_d'] = Variable<int>(itemID.value);
    }
    if (endYN.present) {
      map['end_y_n'] = Variable<String>(endYN.value);
    }
    if (failCnt.present) {
      map['fail_cnt'] = Variable<int>(failCnt.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (quizSeq.present) {
      map['quiz_seq'] = Variable<int>(quizSeq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MissionItemInPlayTableCompanion(')
          ..write('missionID: $missionID, ')
          ..write('playerID: $playerID, ')
          ..write('itemID: $itemID, ')
          ..write('endYN: $endYN, ')
          ..write('failCnt: $failCnt, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('quizSeq: $quizSeq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemRnPInPlayTableTable extends ItemRnPInPlayTable
    with TableInfo<$ItemRnPInPlayTableTable, ItemRnPInPlayTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemRnPInPlayTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _missionIDMeta = const VerificationMeta(
    'missionID',
  );
  @override
  late final GeneratedColumn<String> missionID = GeneratedColumn<String>(
    'mission_i_d',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerIDMeta = const VerificationMeta(
    'playerID',
  );
  @override
  late final GeneratedColumn<String> playerID = GeneratedColumn<String>(
    'player_i_d',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ableCntMeta = const VerificationMeta(
    'ableCnt',
  );
  @override
  late final GeneratedColumn<int> ableCnt = GeneratedColumn<int>(
    'able_cnt',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _ableTimeMeta = const VerificationMeta(
    'ableTime',
  );
  @override
  late final GeneratedColumn<DateTime> ableTime = GeneratedColumn<DateTime>(
    'able_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _acquiredTimeMeta = const VerificationMeta(
    'acquiredTime',
  );
  @override
  late final GeneratedColumn<DateTime> acquiredTime = GeneratedColumn<DateTime>(
    'acquired_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    missionID,
    playerID,
    itemType,
    ableCnt,
    ableTime,
    acquiredTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_rnp_in_play';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemRnPInPlayTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mission_i_d')) {
      context.handle(
        _missionIDMeta,
        missionID.isAcceptableOrUnknown(data['mission_i_d']!, _missionIDMeta),
      );
    } else if (isInserting) {
      context.missing(_missionIDMeta);
    }
    if (data.containsKey('player_i_d')) {
      context.handle(
        _playerIDMeta,
        playerID.isAcceptableOrUnknown(data['player_i_d']!, _playerIDMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIDMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('able_cnt')) {
      context.handle(
        _ableCntMeta,
        ableCnt.isAcceptableOrUnknown(data['able_cnt']!, _ableCntMeta),
      );
    }
    if (data.containsKey('able_time')) {
      context.handle(
        _ableTimeMeta,
        ableTime.isAcceptableOrUnknown(data['able_time']!, _ableTimeMeta),
      );
    }
    if (data.containsKey('acquired_time')) {
      context.handle(
        _acquiredTimeMeta,
        acquiredTime.isAcceptableOrUnknown(
          data['acquired_time']!,
          _acquiredTimeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {missionID, playerID, itemType};
  @override
  ItemRnPInPlayTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemRnPInPlayTableData(
      missionID: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mission_i_d'],
      )!,
      playerID: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_i_d'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      ableCnt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}able_cnt'],
      )!,
      ableTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}able_time'],
      ),
      acquiredTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}acquired_time'],
      ),
    );
  }

  @override
  $ItemRnPInPlayTableTable createAlias(String alias) {
    return $ItemRnPInPlayTableTable(attachedDatabase, alias);
  }
}

class ItemRnPInPlayTableData extends DataClass
    implements Insertable<ItemRnPInPlayTableData> {
  final String missionID;
  final String playerID;
  final String itemType;
  final int ableCnt;
  final DateTime? ableTime;
  final DateTime? acquiredTime;
  const ItemRnPInPlayTableData({
    required this.missionID,
    required this.playerID,
    required this.itemType,
    required this.ableCnt,
    this.ableTime,
    this.acquiredTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mission_i_d'] = Variable<String>(missionID);
    map['player_i_d'] = Variable<String>(playerID);
    map['item_type'] = Variable<String>(itemType);
    map['able_cnt'] = Variable<int>(ableCnt);
    if (!nullToAbsent || ableTime != null) {
      map['able_time'] = Variable<DateTime>(ableTime);
    }
    if (!nullToAbsent || acquiredTime != null) {
      map['acquired_time'] = Variable<DateTime>(acquiredTime);
    }
    return map;
  }

  ItemRnPInPlayTableCompanion toCompanion(bool nullToAbsent) {
    return ItemRnPInPlayTableCompanion(
      missionID: Value(missionID),
      playerID: Value(playerID),
      itemType: Value(itemType),
      ableCnt: Value(ableCnt),
      ableTime: ableTime == null && nullToAbsent
          ? const Value.absent()
          : Value(ableTime),
      acquiredTime: acquiredTime == null && nullToAbsent
          ? const Value.absent()
          : Value(acquiredTime),
    );
  }

  factory ItemRnPInPlayTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemRnPInPlayTableData(
      missionID: serializer.fromJson<String>(json['missionID']),
      playerID: serializer.fromJson<String>(json['playerID']),
      itemType: serializer.fromJson<String>(json['itemType']),
      ableCnt: serializer.fromJson<int>(json['ableCnt']),
      ableTime: serializer.fromJson<DateTime?>(json['ableTime']),
      acquiredTime: serializer.fromJson<DateTime?>(json['acquiredTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'missionID': serializer.toJson<String>(missionID),
      'playerID': serializer.toJson<String>(playerID),
      'itemType': serializer.toJson<String>(itemType),
      'ableCnt': serializer.toJson<int>(ableCnt),
      'ableTime': serializer.toJson<DateTime?>(ableTime),
      'acquiredTime': serializer.toJson<DateTime?>(acquiredTime),
    };
  }

  ItemRnPInPlayTableData copyWith({
    String? missionID,
    String? playerID,
    String? itemType,
    int? ableCnt,
    Value<DateTime?> ableTime = const Value.absent(),
    Value<DateTime?> acquiredTime = const Value.absent(),
  }) => ItemRnPInPlayTableData(
    missionID: missionID ?? this.missionID,
    playerID: playerID ?? this.playerID,
    itemType: itemType ?? this.itemType,
    ableCnt: ableCnt ?? this.ableCnt,
    ableTime: ableTime.present ? ableTime.value : this.ableTime,
    acquiredTime: acquiredTime.present ? acquiredTime.value : this.acquiredTime,
  );
  ItemRnPInPlayTableData copyWithCompanion(ItemRnPInPlayTableCompanion data) {
    return ItemRnPInPlayTableData(
      missionID: data.missionID.present ? data.missionID.value : this.missionID,
      playerID: data.playerID.present ? data.playerID.value : this.playerID,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      ableCnt: data.ableCnt.present ? data.ableCnt.value : this.ableCnt,
      ableTime: data.ableTime.present ? data.ableTime.value : this.ableTime,
      acquiredTime: data.acquiredTime.present
          ? data.acquiredTime.value
          : this.acquiredTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemRnPInPlayTableData(')
          ..write('missionID: $missionID, ')
          ..write('playerID: $playerID, ')
          ..write('itemType: $itemType, ')
          ..write('ableCnt: $ableCnt, ')
          ..write('ableTime: $ableTime, ')
          ..write('acquiredTime: $acquiredTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    missionID,
    playerID,
    itemType,
    ableCnt,
    ableTime,
    acquiredTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemRnPInPlayTableData &&
          other.missionID == this.missionID &&
          other.playerID == this.playerID &&
          other.itemType == this.itemType &&
          other.ableCnt == this.ableCnt &&
          other.ableTime == this.ableTime &&
          other.acquiredTime == this.acquiredTime);
}

class ItemRnPInPlayTableCompanion
    extends UpdateCompanion<ItemRnPInPlayTableData> {
  final Value<String> missionID;
  final Value<String> playerID;
  final Value<String> itemType;
  final Value<int> ableCnt;
  final Value<DateTime?> ableTime;
  final Value<DateTime?> acquiredTime;
  final Value<int> rowid;
  const ItemRnPInPlayTableCompanion({
    this.missionID = const Value.absent(),
    this.playerID = const Value.absent(),
    this.itemType = const Value.absent(),
    this.ableCnt = const Value.absent(),
    this.ableTime = const Value.absent(),
    this.acquiredTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemRnPInPlayTableCompanion.insert({
    required String missionID,
    required String playerID,
    required String itemType,
    this.ableCnt = const Value.absent(),
    this.ableTime = const Value.absent(),
    this.acquiredTime = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : missionID = Value(missionID),
       playerID = Value(playerID),
       itemType = Value(itemType);
  static Insertable<ItemRnPInPlayTableData> custom({
    Expression<String>? missionID,
    Expression<String>? playerID,
    Expression<String>? itemType,
    Expression<int>? ableCnt,
    Expression<DateTime>? ableTime,
    Expression<DateTime>? acquiredTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (missionID != null) 'mission_i_d': missionID,
      if (playerID != null) 'player_i_d': playerID,
      if (itemType != null) 'item_type': itemType,
      if (ableCnt != null) 'able_cnt': ableCnt,
      if (ableTime != null) 'able_time': ableTime,
      if (acquiredTime != null) 'acquired_time': acquiredTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemRnPInPlayTableCompanion copyWith({
    Value<String>? missionID,
    Value<String>? playerID,
    Value<String>? itemType,
    Value<int>? ableCnt,
    Value<DateTime?>? ableTime,
    Value<DateTime?>? acquiredTime,
    Value<int>? rowid,
  }) {
    return ItemRnPInPlayTableCompanion(
      missionID: missionID ?? this.missionID,
      playerID: playerID ?? this.playerID,
      itemType: itemType ?? this.itemType,
      ableCnt: ableCnt ?? this.ableCnt,
      ableTime: ableTime ?? this.ableTime,
      acquiredTime: acquiredTime ?? this.acquiredTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (missionID.present) {
      map['mission_i_d'] = Variable<String>(missionID.value);
    }
    if (playerID.present) {
      map['player_i_d'] = Variable<String>(playerID.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (ableCnt.present) {
      map['able_cnt'] = Variable<int>(ableCnt.value);
    }
    if (ableTime.present) {
      map['able_time'] = Variable<DateTime>(ableTime.value);
    }
    if (acquiredTime.present) {
      map['acquired_time'] = Variable<DateTime>(acquiredTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemRnPInPlayTableCompanion(')
          ..write('missionID: $missionID, ')
          ..write('playerID: $playerID, ')
          ..write('itemType: $itemType, ')
          ..write('ableCnt: $ableCnt, ')
          ..write('ableTime: $ableTime, ')
          ..write('acquiredTime: $acquiredTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MissionInPlayTableTable missionInPlayTable =
      $MissionInPlayTableTable(this);
  late final $MissionItemInPlayTableTable missionItemInPlayTable =
      $MissionItemInPlayTableTable(this);
  late final $ItemRnPInPlayTableTable itemRnPInPlayTable =
      $ItemRnPInPlayTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    missionInPlayTable,
    missionItemInPlayTable,
    itemRnPInPlayTable,
  ];
}

typedef $$MissionInPlayTableTableCreateCompanionBuilder =
    MissionInPlayTableCompanion Function({
      required String missionID,
      required String playerID,
      Value<String> startYN,
      Value<String> endYN,
      Value<DateTime?> startTime,
      Value<DateTime?> endTime,
      Value<int> rowid,
    });
typedef $$MissionInPlayTableTableUpdateCompanionBuilder =
    MissionInPlayTableCompanion Function({
      Value<String> missionID,
      Value<String> playerID,
      Value<String> startYN,
      Value<String> endYN,
      Value<DateTime?> startTime,
      Value<DateTime?> endTime,
      Value<int> rowid,
    });

class $$MissionInPlayTableTableFilterComposer
    extends Composer<_$AppDatabase, $MissionInPlayTableTable> {
  $$MissionInPlayTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get missionID => $composableBuilder(
    column: $table.missionID,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerID => $composableBuilder(
    column: $table.playerID,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startYN => $composableBuilder(
    column: $table.startYN,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endYN => $composableBuilder(
    column: $table.endYN,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MissionInPlayTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MissionInPlayTableTable> {
  $$MissionInPlayTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get missionID => $composableBuilder(
    column: $table.missionID,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerID => $composableBuilder(
    column: $table.playerID,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startYN => $composableBuilder(
    column: $table.startYN,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endYN => $composableBuilder(
    column: $table.endYN,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MissionInPlayTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MissionInPlayTableTable> {
  $$MissionInPlayTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get missionID =>
      $composableBuilder(column: $table.missionID, builder: (column) => column);

  GeneratedColumn<String> get playerID =>
      $composableBuilder(column: $table.playerID, builder: (column) => column);

  GeneratedColumn<String> get startYN =>
      $composableBuilder(column: $table.startYN, builder: (column) => column);

  GeneratedColumn<String> get endYN =>
      $composableBuilder(column: $table.endYN, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);
}

class $$MissionInPlayTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MissionInPlayTableTable,
          MissionInPlayTableData,
          $$MissionInPlayTableTableFilterComposer,
          $$MissionInPlayTableTableOrderingComposer,
          $$MissionInPlayTableTableAnnotationComposer,
          $$MissionInPlayTableTableCreateCompanionBuilder,
          $$MissionInPlayTableTableUpdateCompanionBuilder,
          (
            MissionInPlayTableData,
            BaseReferences<
              _$AppDatabase,
              $MissionInPlayTableTable,
              MissionInPlayTableData
            >,
          ),
          MissionInPlayTableData,
          PrefetchHooks Function()
        > {
  $$MissionInPlayTableTableTableManager(
    _$AppDatabase db,
    $MissionInPlayTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MissionInPlayTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MissionInPlayTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MissionInPlayTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> missionID = const Value.absent(),
                Value<String> playerID = const Value.absent(),
                Value<String> startYN = const Value.absent(),
                Value<String> endYN = const Value.absent(),
                Value<DateTime?> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MissionInPlayTableCompanion(
                missionID: missionID,
                playerID: playerID,
                startYN: startYN,
                endYN: endYN,
                startTime: startTime,
                endTime: endTime,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String missionID,
                required String playerID,
                Value<String> startYN = const Value.absent(),
                Value<String> endYN = const Value.absent(),
                Value<DateTime?> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MissionInPlayTableCompanion.insert(
                missionID: missionID,
                playerID: playerID,
                startYN: startYN,
                endYN: endYN,
                startTime: startTime,
                endTime: endTime,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MissionInPlayTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MissionInPlayTableTable,
      MissionInPlayTableData,
      $$MissionInPlayTableTableFilterComposer,
      $$MissionInPlayTableTableOrderingComposer,
      $$MissionInPlayTableTableAnnotationComposer,
      $$MissionInPlayTableTableCreateCompanionBuilder,
      $$MissionInPlayTableTableUpdateCompanionBuilder,
      (
        MissionInPlayTableData,
        BaseReferences<
          _$AppDatabase,
          $MissionInPlayTableTable,
          MissionInPlayTableData
        >,
      ),
      MissionInPlayTableData,
      PrefetchHooks Function()
    >;
typedef $$MissionItemInPlayTableTableCreateCompanionBuilder =
    MissionItemInPlayTableCompanion Function({
      required String missionID,
      required String playerID,
      required int itemID,
      Value<String> endYN,
      Value<int> failCnt,
      Value<DateTime?> startTime,
      Value<DateTime?> endTime,
      Value<int> quizSeq,
      Value<int> rowid,
    });
typedef $$MissionItemInPlayTableTableUpdateCompanionBuilder =
    MissionItemInPlayTableCompanion Function({
      Value<String> missionID,
      Value<String> playerID,
      Value<int> itemID,
      Value<String> endYN,
      Value<int> failCnt,
      Value<DateTime?> startTime,
      Value<DateTime?> endTime,
      Value<int> quizSeq,
      Value<int> rowid,
    });

class $$MissionItemInPlayTableTableFilterComposer
    extends Composer<_$AppDatabase, $MissionItemInPlayTableTable> {
  $$MissionItemInPlayTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get missionID => $composableBuilder(
    column: $table.missionID,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerID => $composableBuilder(
    column: $table.playerID,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemID => $composableBuilder(
    column: $table.itemID,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endYN => $composableBuilder(
    column: $table.endYN,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failCnt => $composableBuilder(
    column: $table.failCnt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quizSeq => $composableBuilder(
    column: $table.quizSeq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MissionItemInPlayTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MissionItemInPlayTableTable> {
  $$MissionItemInPlayTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get missionID => $composableBuilder(
    column: $table.missionID,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerID => $composableBuilder(
    column: $table.playerID,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemID => $composableBuilder(
    column: $table.itemID,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endYN => $composableBuilder(
    column: $table.endYN,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failCnt => $composableBuilder(
    column: $table.failCnt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quizSeq => $composableBuilder(
    column: $table.quizSeq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MissionItemInPlayTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MissionItemInPlayTableTable> {
  $$MissionItemInPlayTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get missionID =>
      $composableBuilder(column: $table.missionID, builder: (column) => column);

  GeneratedColumn<String> get playerID =>
      $composableBuilder(column: $table.playerID, builder: (column) => column);

  GeneratedColumn<int> get itemID =>
      $composableBuilder(column: $table.itemID, builder: (column) => column);

  GeneratedColumn<String> get endYN =>
      $composableBuilder(column: $table.endYN, builder: (column) => column);

  GeneratedColumn<int> get failCnt =>
      $composableBuilder(column: $table.failCnt, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get quizSeq =>
      $composableBuilder(column: $table.quizSeq, builder: (column) => column);
}

class $$MissionItemInPlayTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MissionItemInPlayTableTable,
          MissionItemInPlayTableData,
          $$MissionItemInPlayTableTableFilterComposer,
          $$MissionItemInPlayTableTableOrderingComposer,
          $$MissionItemInPlayTableTableAnnotationComposer,
          $$MissionItemInPlayTableTableCreateCompanionBuilder,
          $$MissionItemInPlayTableTableUpdateCompanionBuilder,
          (
            MissionItemInPlayTableData,
            BaseReferences<
              _$AppDatabase,
              $MissionItemInPlayTableTable,
              MissionItemInPlayTableData
            >,
          ),
          MissionItemInPlayTableData,
          PrefetchHooks Function()
        > {
  $$MissionItemInPlayTableTableTableManager(
    _$AppDatabase db,
    $MissionItemInPlayTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MissionItemInPlayTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MissionItemInPlayTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MissionItemInPlayTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> missionID = const Value.absent(),
                Value<String> playerID = const Value.absent(),
                Value<int> itemID = const Value.absent(),
                Value<String> endYN = const Value.absent(),
                Value<int> failCnt = const Value.absent(),
                Value<DateTime?> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<int> quizSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MissionItemInPlayTableCompanion(
                missionID: missionID,
                playerID: playerID,
                itemID: itemID,
                endYN: endYN,
                failCnt: failCnt,
                startTime: startTime,
                endTime: endTime,
                quizSeq: quizSeq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String missionID,
                required String playerID,
                required int itemID,
                Value<String> endYN = const Value.absent(),
                Value<int> failCnt = const Value.absent(),
                Value<DateTime?> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<int> quizSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MissionItemInPlayTableCompanion.insert(
                missionID: missionID,
                playerID: playerID,
                itemID: itemID,
                endYN: endYN,
                failCnt: failCnt,
                startTime: startTime,
                endTime: endTime,
                quizSeq: quizSeq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MissionItemInPlayTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MissionItemInPlayTableTable,
      MissionItemInPlayTableData,
      $$MissionItemInPlayTableTableFilterComposer,
      $$MissionItemInPlayTableTableOrderingComposer,
      $$MissionItemInPlayTableTableAnnotationComposer,
      $$MissionItemInPlayTableTableCreateCompanionBuilder,
      $$MissionItemInPlayTableTableUpdateCompanionBuilder,
      (
        MissionItemInPlayTableData,
        BaseReferences<
          _$AppDatabase,
          $MissionItemInPlayTableTable,
          MissionItemInPlayTableData
        >,
      ),
      MissionItemInPlayTableData,
      PrefetchHooks Function()
    >;
typedef $$ItemRnPInPlayTableTableCreateCompanionBuilder =
    ItemRnPInPlayTableCompanion Function({
      required String missionID,
      required String playerID,
      required String itemType,
      Value<int> ableCnt,
      Value<DateTime?> ableTime,
      Value<DateTime?> acquiredTime,
      Value<int> rowid,
    });
typedef $$ItemRnPInPlayTableTableUpdateCompanionBuilder =
    ItemRnPInPlayTableCompanion Function({
      Value<String> missionID,
      Value<String> playerID,
      Value<String> itemType,
      Value<int> ableCnt,
      Value<DateTime?> ableTime,
      Value<DateTime?> acquiredTime,
      Value<int> rowid,
    });

class $$ItemRnPInPlayTableTableFilterComposer
    extends Composer<_$AppDatabase, $ItemRnPInPlayTableTable> {
  $$ItemRnPInPlayTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get missionID => $composableBuilder(
    column: $table.missionID,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerID => $composableBuilder(
    column: $table.playerID,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ableCnt => $composableBuilder(
    column: $table.ableCnt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ableTime => $composableBuilder(
    column: $table.ableTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get acquiredTime => $composableBuilder(
    column: $table.acquiredTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ItemRnPInPlayTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemRnPInPlayTableTable> {
  $$ItemRnPInPlayTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get missionID => $composableBuilder(
    column: $table.missionID,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerID => $composableBuilder(
    column: $table.playerID,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ableCnt => $composableBuilder(
    column: $table.ableCnt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ableTime => $composableBuilder(
    column: $table.ableTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get acquiredTime => $composableBuilder(
    column: $table.acquiredTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemRnPInPlayTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemRnPInPlayTableTable> {
  $$ItemRnPInPlayTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get missionID =>
      $composableBuilder(column: $table.missionID, builder: (column) => column);

  GeneratedColumn<String> get playerID =>
      $composableBuilder(column: $table.playerID, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<int> get ableCnt =>
      $composableBuilder(column: $table.ableCnt, builder: (column) => column);

  GeneratedColumn<DateTime> get ableTime =>
      $composableBuilder(column: $table.ableTime, builder: (column) => column);

  GeneratedColumn<DateTime> get acquiredTime => $composableBuilder(
    column: $table.acquiredTime,
    builder: (column) => column,
  );
}

class $$ItemRnPInPlayTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemRnPInPlayTableTable,
          ItemRnPInPlayTableData,
          $$ItemRnPInPlayTableTableFilterComposer,
          $$ItemRnPInPlayTableTableOrderingComposer,
          $$ItemRnPInPlayTableTableAnnotationComposer,
          $$ItemRnPInPlayTableTableCreateCompanionBuilder,
          $$ItemRnPInPlayTableTableUpdateCompanionBuilder,
          (
            ItemRnPInPlayTableData,
            BaseReferences<
              _$AppDatabase,
              $ItemRnPInPlayTableTable,
              ItemRnPInPlayTableData
            >,
          ),
          ItemRnPInPlayTableData,
          PrefetchHooks Function()
        > {
  $$ItemRnPInPlayTableTableTableManager(
    _$AppDatabase db,
    $ItemRnPInPlayTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemRnPInPlayTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemRnPInPlayTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemRnPInPlayTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> missionID = const Value.absent(),
                Value<String> playerID = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<int> ableCnt = const Value.absent(),
                Value<DateTime?> ableTime = const Value.absent(),
                Value<DateTime?> acquiredTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemRnPInPlayTableCompanion(
                missionID: missionID,
                playerID: playerID,
                itemType: itemType,
                ableCnt: ableCnt,
                ableTime: ableTime,
                acquiredTime: acquiredTime,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String missionID,
                required String playerID,
                required String itemType,
                Value<int> ableCnt = const Value.absent(),
                Value<DateTime?> ableTime = const Value.absent(),
                Value<DateTime?> acquiredTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemRnPInPlayTableCompanion.insert(
                missionID: missionID,
                playerID: playerID,
                itemType: itemType,
                ableCnt: ableCnt,
                ableTime: ableTime,
                acquiredTime: acquiredTime,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ItemRnPInPlayTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemRnPInPlayTableTable,
      ItemRnPInPlayTableData,
      $$ItemRnPInPlayTableTableFilterComposer,
      $$ItemRnPInPlayTableTableOrderingComposer,
      $$ItemRnPInPlayTableTableAnnotationComposer,
      $$ItemRnPInPlayTableTableCreateCompanionBuilder,
      $$ItemRnPInPlayTableTableUpdateCompanionBuilder,
      (
        ItemRnPInPlayTableData,
        BaseReferences<
          _$AppDatabase,
          $ItemRnPInPlayTableTable,
          ItemRnPInPlayTableData
        >,
      ),
      ItemRnPInPlayTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MissionInPlayTableTableTableManager get missionInPlayTable =>
      $$MissionInPlayTableTableTableManager(_db, _db.missionInPlayTable);
  $$MissionItemInPlayTableTableTableManager get missionItemInPlayTable =>
      $$MissionItemInPlayTableTableTableManager(
        _db,
        _db.missionItemInPlayTable,
      );
  $$ItemRnPInPlayTableTableTableManager get itemRnPInPlayTable =>
      $$ItemRnPInPlayTableTableTableManager(_db, _db.itemRnPInPlayTable);
}
