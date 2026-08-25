import 'dart:convert';

import 'question.dart';
import 'toeic_part.dart';

/// 모의고사 한 회.
///
/// 실제 시험 순서(Q1 → Q11)대로 문항 id 를 담는다. 문항 자체는 여기에 복사하지 않고
/// [QuestionStore] 에서 찾아 쓰기 때문에, 문항을 고치면 회차에도 그대로 반영된다.
///
/// 한 회는 문항 7개(낭독 2 + 사진 2 + 듣고 답하기 1 + 정보 활용 1 + 의견 1)로
/// 이루어지고, 답변 단계로 펼치면 11문항이 된다.
class ExamSet {
  const ExamSet({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.questionIds = const <String>[],
    this.isCustom = false,
  });

  final String id;

  /// 예) "실전 모의고사 1회"
  final String title;

  /// 목록에서 어떤 문항으로 짜였는지 알려 주는 한 줄 설명.
  final String subtitle;

  /// 시험 순서대로 늘어놓은 문항 id.
  final List<String> questionIds;

  /// 앱에서 직접 만든 회차인지. 이 브라우저에만 저장된다.
  final bool isCustom;

  ExamSet copyWith({
    String? title,
    String? subtitle,
    List<String>? questionIds,
  }) {
    return ExamSet(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      questionIds: questionIds ?? this.questionIds,
      isCustom: isCustom,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        if (subtitle.isNotEmpty) 'subtitle': subtitle,
        'questionIds': questionIds,
        'isCustom': isCustom,
      };

  static ExamSet? fromMap(Map<String, dynamic> map) {
    final String? id = map['id'] as String?;
    final String? title = map['title'] as String?;
    if (id == null || title == null) return null;

    final Object? rawIds = map['questionIds'];
    return ExamSet(
      id: id,
      title: title,
      subtitle: (map['subtitle'] as String?) ?? '',
      questionIds: rawIds is List
          ? rawIds.whereType<String>().toList()
          : const <String>[],
      // 저장돼 있던 회차는 모두 직접 만든 것이다.
      isCustom: (map['isCustom'] as bool?) ?? true,
    );
  }

  String toJson() => jsonEncode(toMap());

  static ExamSet? fromJson(String source) {
    try {
      final Object? decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) return null;
      return fromMap(decoded);
    } on FormatException {
      return null;
    }
  }
}

/// 모의고사에서 실제로 답변하는 한 단계.
///
/// 문항 하나가 여러 단계를 가질 수 있다. 예를 들어 Q5-7 문항 하나는
/// 질문 3개짜리라 단계 3개(5번·6번·7번)로 펼쳐진다.
class ExamStep {
  const ExamStep({
    required this.question,
    required this.promptIndex,
    required this.number,
    required this.isPartStart,
  });

  final Question question;

  /// [Question.steps] 안에서의 위치.
  final int promptIndex;

  /// 시험 전체에서 몇 번 문항인지(1~11).
  final int number;

  /// 이 단계 앞에서 파트 안내를 보여 줘야 하는지(파트가 바뀌는 첫 단계).
  final bool isPartStart;

  Prompt get prompt => question.steps[promptIndex];
  PartId get partId => question.partId;
  ToeicPart get part => question.part;

  int get totalSeconds => prompt.prepSeconds + prompt.answerSeconds;
}

/// 회차를 실제 진행 순서대로 펼친 진행표.
class ExamPlan {
  const ExamPlan({
    required this.set,
    required this.steps,
    required this.missingIds,
  });

  final ExamSet set;

  /// 1번부터 마지막 번호까지, 답변 단계를 순서대로 늘어놓은 것.
  final List<ExamStep> steps;

  /// 문항을 찾지 못한 id. 등록한 문항을 지운 뒤 회차만 남은 경우 등.
  final List<String> missingIds;

  bool get isEmpty => steps.isEmpty;

  bool get isComplete => missingIds.isEmpty && steps.length == 11;

  /// 회차에 실제로 들어 있는 문항 수(단계 수가 아니라 문항 수).
  int get questionCount =>
      steps.map((ExamStep s) => s.question.id).toSet().length;

  /// 준비 시간 + 답변 시간의 합. 안내 시간은 빼고 계산한다.
  Duration get totalDuration => Duration(
        seconds: steps.fold<int>(
          0,
          (int sum, ExamStep s) => sum + s.totalSeconds,
        ),
      );

  /// 회차에 들어 있는 문항을 순서대로(중복 없이) 돌려준다.
  List<Question> get questions {
    final List<Question> result = <Question>[];
    for (final ExamStep step in steps) {
      if (result.isEmpty || result.last.id != step.question.id) {
        result.add(step.question);
      }
    }
    return result;
  }

  /// 문항 id 목록을 실제 진행표로 바꾼다.
  ///
  /// [lookup] 은 id 로 문항을 찾아 주는 함수(없으면 null). 저장소를 직접 보지 않아
  /// 그대로 테스트할 수 있다. 찾지 못한 id 는 건너뛰고 [missingIds] 에 모은다.
  static ExamPlan build(ExamSet set, Question? Function(String id) lookup) {
    final List<ExamStep> steps = <ExamStep>[];
    final List<String> missing = <String>[];
    PartId? previousPart;
    int number = 1;

    for (final String id in set.questionIds) {
      final Question? question = lookup(id);
      if (question == null) {
        missing.add(id);
        continue;
      }
      final int stepCount = question.steps.length;
      for (int i = 0; i < stepCount; i++) {
        steps.add(
          ExamStep(
            question: question,
            promptIndex: i,
            number: number,
            // 파트가 바뀌는 첫 단계에서만 안내를 띄운다.
            isPartStart: i == 0 && question.partId != previousPart,
          ),
        );
        number++;
      }
      previousPart = question.partId;
    }

    return ExamPlan(set: set, steps: steps, missingIds: missing);
  }
}
