import 'package:flutter_test/flutter_test.dart';
import 'package:toeic_speaking/models/question.dart';
import 'package:toeic_speaking/models/toeic_part.dart';

void main() {
  group('사용자 등록 문항 직렬화', () {
    test('낭독 문항이 JSON 왕복 후 보존된다', () {
      const Question original = Question(
        id: 'custom_readAloud_1',
        partId: PartId.readAloud,
        title: '내가 만든 지문',
        passage: 'Attention, visitors.',
        keyExpressions: <String>['표현 1', '표현 2'],
        isCustom: true,
      );

      final Question? restored = Question.fromJson(original.toJson());

      expect(restored, isNotNull);
      expect(restored!.id, original.id);
      expect(restored.partId, PartId.readAloud);
      expect(restored.title, original.title);
      expect(restored.passage, original.passage);
      expect(restored.keyExpressions, original.keyExpressions);
      expect(restored.isCustom, isTrue);
    });

    test('질문이 여러 개인 문항이 시간까지 보존된다', () {
      const Question original = Question(
        id: 'custom_respondQuestions_1',
        partId: PartId.respondQuestions,
        title: '내가 만든 인터뷰',
        prompts: <Prompt>[
          Prompt(
            label: 'Question 5',
            text: 'First?',
            prepSeconds: 3,
            answerSeconds: 15,
          ),
          Prompt(
            label: 'Question 7',
            text: 'Third?',
            prepSeconds: 3,
            answerSeconds: 30,
          ),
        ],
        isCustom: true,
      );

      final Question? restored = Question.fromJson(original.toJson());

      expect(restored, isNotNull);
      expect(restored!.prompts.length, 2);
      expect(restored.prompts[0].label, 'Question 5');
      expect(restored.prompts[1].answerSeconds, 30);
      expect(restored.totalSeconds, 3 + 15 + 3 + 30);
    });

    test('자료 표와 장면 설명이 보존된다', () {
      const Question original = Question(
        id: 'custom_respondWithInfo_1',
        partId: PartId.respondWithInfo,
        title: '내가 만든 일정표',
        table: InfoTable(
          title: 'Workshop',
          subtitle: 'June 14',
          rows: <List<String>>[
            <String>['9:00 A.M.', 'Registration', 'Lobby'],
            <String>['1:00 P.M.', 'Lunch', 'Cafeteria'],
          ],
        ),
        scene: SceneHint(place: '장소', details: <String>['상세 1']),
        prompts: <Prompt>[
          Prompt(text: 'Where?', prepSeconds: 3, answerSeconds: 15),
        ],
        isCustom: true,
      );

      final Question? restored = Question.fromJson(original.toJson());

      expect(restored, isNotNull);
      expect(restored!.table, isNotNull);
      expect(restored.table!.rows.length, 2);
      expect(restored.table!.rows[1][2], 'Cafeteria');
      expect(restored.scene!.place, '장소');
      expect(restored.scene!.details, <String>['상세 1']);
    });

    test('예시 음성 여부가 JSON 왕복 후 보존된다', () {
      const Question withAudio = Question(
        id: 'custom_readAloud_2',
        partId: PartId.readAloud,
        title: '예시 음성 있는 문항',
        passage: 'Attention.',
        isCustom: true,
        hasSampleAudio: true,
      );

      final Question? restored = Question.fromJson(withAudio.toJson());
      expect(restored, isNotNull);
      expect(restored!.hasSampleAudio, isTrue);
    });

    test('예시 음성이 없으면 기본값은 false 다', () {
      const Question noAudio = Question(
        id: 'custom_readAloud_3',
        partId: PartId.readAloud,
        title: '예시 음성 없는 문항',
        passage: 'Attention.',
        isCustom: true,
      );
      expect(noAudio.hasSampleAudio, isFalse);

      // 옛 형식(필드 자체가 없는 JSON)도 false 로 읽힌다.
      final Question? old = Question.fromJson(
        '{"id":"x","title":"t","partId":"readAloud"}',
      );
      expect(old, isNotNull);
      expect(old!.hasSampleAudio, isFalse);
    });

    test('기본 문항은 isCustom 이 false 다', () {
      const Question builtIn = Question(
        id: 'ra_01',
        partId: PartId.readAloud,
        title: '기본 문항',
        passage: '...',
      );
      expect(builtIn.isCustom, isFalse);
    });

    test('알 수 없는 파트나 필수 값이 빠지면 null 을 돌려준다', () {
      expect(
          Question.fromJson('{"id":"x","title":"t","partId":"없는파트"}'), isNull);
      expect(Question.fromJson('{"id":"x","partId":"readAloud"}'), isNull);
      expect(Question.fromJson('{bad json'), isNull);
    });
  });
}
