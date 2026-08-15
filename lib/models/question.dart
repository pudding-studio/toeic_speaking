import 'dart:convert';

import 'toeic_part.dart';

/// 사진 묘사 문항에서 사진 대신 제공되는 장면 설명.
class SceneHint {
  const SceneHint({required this.place, required this.details});

  final String place;
  final List<String> details;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'place': place,
        'details': details,
      };

  static SceneHint? fromMap(Map<String, dynamic> map) {
    final String? place = map['place'] as String?;
    if (place == null) return null;
    return SceneHint(
      place: place,
      details: _stringList(map['details']),
    );
  }
}

/// Q8-10 에서 45초 동안 읽는 표 형태의 자료.
class InfoTable {
  const InfoTable({
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  final String title;
  final String subtitle;

  /// 각 행은 [시간/구분, 내용, 담당/장소] 형태의 3열.
  final List<List<String>> rows;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'title': title,
        'subtitle': subtitle,
        'rows': rows,
      };

  static InfoTable? fromMap(Map<String, dynamic> map) {
    final String? title = map['title'] as String?;
    if (title == null) return null;
    final Object? rawRows = map['rows'];
    final List<List<String>> rows = <List<String>>[];
    if (rawRows is List) {
      for (final Object? row in rawRows) {
        rows.add(_stringList(row));
      }
    }
    return InfoTable(
      title: title,
      subtitle: (map['subtitle'] as String?) ?? '',
      rows: rows,
    );
  }
}

/// 한 문항.
class Question {
  const Question({
    required this.id,
    required this.partId,
    required this.title,
    this.passage,
    this.imagePath,
    this.scene,
    this.table,
    this.prompts = const <Prompt>[],
    this.sampleAnswer,
    this.keyExpressions = const <String>[],
    this.isCustom = false,
  });

  final String id;
  final PartId partId;
  final String title;

  /// Q1-2 에서 읽을 지문.
  final String? passage;

  /// Q3-4 사진 에셋 경로. 예) 'assets/images/questions/dp_01.jpg'
  /// 앱에서 등록한 문항([isCustom])의 사진은 이 경로가 아니라
  /// 브라우저 저장소에서 문항 id 로 꺼내 온다.
  final String? imagePath;

  /// Q3-4 장면 설명. 사진이 없을 때의 대체 수단.
  final SceneHint? scene;

  /// Q8-10 자료.
  final InfoTable? table;

  /// 실제로 답해야 하는 질문들. Q1-2 처럼 지문 낭독만 하는 경우 비어 있을 수 있다.
  final List<Prompt> prompts;

  final String? sampleAnswer;
  final List<String> keyExpressions;

  /// 앱 화면에서 사용자가 직접 등록한 문항인지. 이 브라우저에만 저장된다.
  final bool isCustom;

  ToeicPart get part => partById(partId);

  /// 이 문항에서 진행할 단계. 낭독형이면 지문 자체가 하나의 단계가 된다.
  List<Prompt> get steps {
    if (prompts.isNotEmpty) return prompts;
    return <Prompt>[
      Prompt(
        text: title,
        prepSeconds: part.defaultPrepSeconds,
        answerSeconds: part.defaultAnswerSeconds,
      ),
    ];
  }

  int get totalSeconds => steps.fold<int>(
        0,
        (int sum, Prompt p) => sum + p.prepSeconds + p.answerSeconds,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'partId': partId.name,
        'title': title,
        if (passage != null) 'passage': passage,
        if (scene != null) 'scene': scene!.toMap(),
        if (table != null) 'table': table!.toMap(),
        if (prompts.isNotEmpty)
          'prompts': prompts.map((Prompt p) => p.toMap()).toList(),
        if (sampleAnswer != null) 'sampleAnswer': sampleAnswer,
        if (keyExpressions.isNotEmpty) 'keyExpressions': keyExpressions,
        'isCustom': isCustom,
      };

  static Question? fromMap(Map<String, dynamic> map) {
    final String? id = map['id'] as String?;
    final String? title = map['title'] as String?;
    if (id == null || title == null) return null;

    final String? partName = map['partId'] as String?;
    PartId? partId;
    for (final PartId p in PartId.values) {
      if (p.name == partName) {
        partId = p;
        break;
      }
    }
    if (partId == null) return null;

    final Object? rawScene = map['scene'];
    final Object? rawTable = map['table'];
    final Object? rawPrompts = map['prompts'];

    return Question(
      id: id,
      partId: partId,
      title: title,
      passage: map['passage'] as String?,
      scene:
          rawScene is Map<String, dynamic> ? SceneHint.fromMap(rawScene) : null,
      table:
          rawTable is Map<String, dynamic> ? InfoTable.fromMap(rawTable) : null,
      prompts: rawPrompts is List
          ? rawPrompts
              .whereType<Map<String, dynamic>>()
              .map(Prompt.fromMap)
              .whereType<Prompt>()
              .toList()
          : const <Prompt>[],
      sampleAnswer: map['sampleAnswer'] as String?,
      keyExpressions: _stringList(map['keyExpressions']),
      isCustom: (map['isCustom'] as bool?) ?? true,
    );
  }

  String toJson() => jsonEncode(toMap());

  static Question? fromJson(String source) {
    try {
      final Object? decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) return null;
      return fromMap(decoded);
    } on FormatException {
      return null;
    }
  }
}

/// 개별 질문(발화 단위).
class Prompt {
  const Prompt({
    required this.text,
    required this.prepSeconds,
    required this.answerSeconds,
    this.label,
    this.hint,
  });

  final String text;
  final int prepSeconds;
  final int answerSeconds;

  /// 예) "Question 5"
  final String? label;

  /// 답변 화면 하단에 뜨는 짧은 힌트.
  final String? hint;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'text': text,
        'prepSeconds': prepSeconds,
        'answerSeconds': answerSeconds,
        if (label != null) 'label': label,
        if (hint != null) 'hint': hint,
      };

  static Prompt? fromMap(Map<String, dynamic> map) {
    final String? text = map['text'] as String?;
    if (text == null) return null;
    return Prompt(
      text: text,
      prepSeconds: (map['prepSeconds'] as num?)?.toInt() ?? 0,
      answerSeconds: (map['answerSeconds'] as num?)?.toInt() ?? 15,
      label: map['label'] as String?,
      hint: map['hint'] as String?,
    );
  }
}

List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().toList(growable: false);
}
