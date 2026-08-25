import 'dart:convert';

import 'toeic_part.dart';

/// 하루 할 일의 종류.
enum TaskKind {
  /// 특정 파트의 문항을 정해진 개수만큼 연습한다.
  part,

  /// 실전 모의고사를 응시한다.
  exam,

  /// 녹음 다시 듣기처럼 화면 이동이 필요 없는 할 일.
  review,
}

/// 하루 할 일 하나.
class CurriculumTask {
  /// 파트 연습. 예) Q1-2 문항 2개.
  const CurriculumTask.part(this.partId, this.count)
      : kind = TaskKind.part,
        text = null;

  /// 실전 모의고사 응시.
  const CurriculumTask.exam({this.count = 1})
      : kind = TaskKind.exam,
        partId = null,
        text = null;

  /// 복습처럼 앱 밖에서 하거나 녹음 기록만 보면 되는 할 일.
  const CurriculumTask.review(this.text)
      : kind = TaskKind.review,
        partId = null,
        count = 1;

  final TaskKind kind;

  /// [TaskKind.part] 일 때의 파트.
  final PartId? partId;

  /// 문항 수(파트) 또는 회차 수(모의고사).
  final int count;

  /// [TaskKind.review] 일 때 보여 줄 문구.
  final String? text;

  /// 목록에 보여 줄 한 줄.
  String get label => switch (kind) {
        TaskKind.part => '${partById(partId!).tabLabel} $count문항',
        TaskKind.exam => '실전 모의고사 $count회',
        TaskKind.review => text!,
      };

  /// 이 할 일에 걸리는 대략의 시간(초).
  ///
  /// 파트 연습은 실제 준비·답변 시간에 두 배를 곱한다. 말한 답을 한 번 더 듣고
  /// 정리하는 시간까지 감안한 값이다. 모의고사는 실제 시험 길이(약 20분)를 쓴다.
  int get estimatedSeconds => switch (kind) {
        TaskKind.part => secondsPerQuestion(partId!) * count * 2,
        TaskKind.exam => 20 * 60 * count,
        TaskKind.review => 5 * 60,
      };

  /// 파트별로 문항 하나를 푸는 데 실제로 걸리는 시간(초).
  ///
  /// Q5-7 과 Q8-10 은 문항 하나에 질문이 3개씩 들어 있어 따로 센다.
  /// Q5-7 은 질문마다 준비 3초 + 답변 15·15·30초,
  /// Q8-10 은 자료 확인 45초 + 답변 15·15·30초다.
  static int secondsPerQuestion(PartId id) => switch (id) {
        PartId.readAloud => 45 + 45,
        PartId.describePicture => 45 + 30,
        PartId.respondQuestions => (3 + 15) + (3 + 15) + (3 + 30),
        PartId.respondWithInfo => 45 + 15 + 15 + 30,
        PartId.expressOpinion => 45 + 60,
      };
}

/// 커리큘럼의 하루.
class CurriculumDay {
  const CurriculumDay({
    required this.day,
    required this.focus,
    required this.tasks,
    this.note,
  });

  /// 1부터 시작하는 날짜 번호.
  final int day;

  /// 그날의 주제. 예) "Q3-4 사진 묘사 틀 잡기"
  final String focus;

  final List<CurriculumTask> tasks;

  /// 그날 신경 쓸 점 한 줄.
  final String? note;

  /// 그날 예상 소요 시간(분). 올림해서 보여 준다.
  int get estimatedMinutes {
    final int seconds = tasks.fold<int>(
      0,
      (int sum, CurriculumTask t) => sum + t.estimatedSeconds,
    );
    return (seconds / 60).ceil();
  }

  /// 그날 풀어야 하는 문항 수(모의고사는 11문항으로 센다).
  int get questionCount => tasks.fold<int>(0, (int sum, CurriculumTask t) {
        return sum +
            switch (t.kind) {
              TaskKind.part => t.count,
              TaskKind.exam => 11 * t.count,
              TaskKind.review => 0,
            };
      });

  /// 진행 상태를 저장할 때 쓰는 키. 예) 'd3t1'
  String taskKey(int taskIndex) => 'd${day}t$taskIndex';
}

/// 며칠짜리 학습 계획 한 벌.
class Curriculum {
  const Curriculum({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.forWhom,
    required this.days,
  });

  final String id;

  /// 예) "1주 완성"
  final String title;

  /// 한 줄 소개.
  final String subtitle;

  /// 어떤 사람에게 맞는 계획인지.
  final String forWhom;

  final List<CurriculumDay> days;

  int get totalDays => days.length;

  /// 계획 전체에서 풀게 되는 문항 수.
  int get totalQuestions =>
      days.fold<int>(0, (int sum, CurriculumDay d) => sum + d.questionCount);

  /// 계획 전체의 모의고사 응시 횟수.
  int get examCount => days.fold<int>(0, (int sum, CurriculumDay d) {
        return sum +
            d.tasks
                .where((CurriculumTask t) => t.kind == TaskKind.exam)
                .fold<int>(0, (int s, CurriculumTask t) => s + t.count);
      });

  /// 하루 평균 예상 시간(분).
  int get averageMinutes {
    if (days.isEmpty) return 0;
    final int total = days.fold<int>(
        0, (int sum, CurriculumDay d) => sum + d.estimatedMinutes);
    return (total / days.length).round();
  }

  /// 계획 전체에서 할 일이 몇 개인지.
  int get totalTasks =>
      days.fold<int>(0, (int sum, CurriculumDay d) => sum + d.tasks.length);

  CurriculumDay? dayAt(int day) {
    for (final CurriculumDay d in days) {
      if (d.day == day) return d;
    }
    return null;
  }
}

/// 어느 계획을 언제 시작했고 무엇을 끝냈는지.
///
/// 계획 자체는 코드에 들어 있으므로 여기에는 진행 상태만 담는다.
class CurriculumProgress {
  const CurriculumProgress({
    required this.curriculumId,
    required this.startedAt,
    this.doneTaskKeys = const <String>{},
  });

  final String curriculumId;

  /// 시작한 날(자정 기준). 오늘이 며칠째인지 계산하는 데 쓴다.
  final DateTime startedAt;

  /// 끝낸 할 일의 키([CurriculumDay.taskKey]).
  final Set<String> doneTaskKeys;

  /// 시작일을 1일째로 본다. 하루도 안 지났으면 1.
  int dayNumberOn(DateTime now) {
    final DateTime from = DateTime(
      startedAt.year,
      startedAt.month,
      startedAt.day,
    );
    final DateTime to = DateTime(now.year, now.month, now.day);
    return to.difference(from).inDays + 1;
  }

  bool isDone(String taskKey) => doneTaskKeys.contains(taskKey);

  /// 하루의 할 일을 모두 끝냈는지.
  bool isDayDone(CurriculumDay day) {
    if (day.tasks.isEmpty) return false;
    for (int i = 0; i < day.tasks.length; i++) {
      if (!isDone(day.taskKey(i))) return false;
    }
    return true;
  }

  CurriculumProgress toggle(String taskKey) {
    final Set<String> next = <String>{...doneTaskKeys};
    if (!next.remove(taskKey)) next.add(taskKey);
    return CurriculumProgress(
      curriculumId: curriculumId,
      startedAt: startedAt,
      doneTaskKeys: next,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'curriculumId': curriculumId,
        'startedAt': startedAt.toIso8601String(),
        'doneTaskKeys': doneTaskKeys.toList(),
      };

  static CurriculumProgress? fromMap(Map<String, dynamic> map) {
    final String? id = map['curriculumId'] as String?;
    final String? startedAt = map['startedAt'] as String?;
    if (id == null || startedAt == null) return null;
    final DateTime? parsed = DateTime.tryParse(startedAt);
    if (parsed == null) return null;

    final Object? rawKeys = map['doneTaskKeys'];
    return CurriculumProgress(
      curriculumId: id,
      startedAt: parsed,
      doneTaskKeys: rawKeys is List
          ? rawKeys.whereType<String>().toSet()
          : const <String>{},
    );
  }

  String toJson() => jsonEncode(toMap());

  static CurriculumProgress? fromJson(String source) {
    try {
      final Object? decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) return null;
      return fromMap(decoded);
    } on FormatException {
      return null;
    }
  }
}
