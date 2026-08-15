import 'toeic_part.dart';

/// 사진 묘사 문항에서 사진 대신 제공되는 장면 설명(에셋 이미지 없이 동작하도록).
class SceneHint {
  const SceneHint({required this.place, required this.details});

  final String place;
  final List<String> details;
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
}

/// 한 문항. [followUps] 가 있으면 여러 개의 하위 질문을 순서대로 진행한다.
class Question {
  const Question({
    required this.id,
    required this.partId,
    required this.title,
    this.passage,
    this.scene,
    this.table,
    this.prompts = const <Prompt>[],
    this.sampleAnswer,
    this.keyExpressions = const <String>[],
  });

  final String id;
  final PartId partId;
  final String title;

  /// Q1-2 에서 읽을 지문.
  final String? passage;

  /// Q3-4 장면 설명.
  final SceneHint? scene;

  /// Q8-10 자료.
  final InfoTable? table;

  /// 실제로 답해야 하는 질문들. Q1-2 처럼 지문 낭독만 하는 경우 비어 있을 수 있다.
  final List<Prompt> prompts;

  final String? sampleAnswer;
  final List<String> keyExpressions;

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
}
