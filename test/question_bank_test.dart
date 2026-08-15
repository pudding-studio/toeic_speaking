import 'package:flutter_test/flutter_test.dart';
import 'package:toeic_speaking/data/question_bank.dart';
import 'package:toeic_speaking/models/attempt.dart';
import 'package:toeic_speaking/models/question.dart';
import 'package:toeic_speaking/models/toeic_part.dart';

void main() {
  group('문항 데이터', () {
    test('모든 파트에 연습 문항이 하나 이상 있다', () {
      for (final ToeicPart part in kToeicParts) {
        expect(
          questionsOfPart(part.id),
          isNotEmpty,
          reason: '${part.title} 에 문항이 없습니다',
        );
      }
    });

    test('문항 id 는 중복되지 않는다', () {
      final Set<String> ids = kQuestions.map((Question q) => q.id).toSet();
      expect(ids.length, kQuestions.length);
    });

    test('모든 문항의 단계에는 답변 시간이 있다', () {
      for (final Question q in kQuestions) {
        expect(q.steps, isNotEmpty);
        for (final Prompt p in q.steps) {
          expect(p.answerSeconds, greaterThan(0));
          expect(p.prepSeconds, greaterThanOrEqualTo(0));
        }
      }
    });

    test('낭독형 문항은 지문을 가진다', () {
      for (final Question q in questionsOfPart(PartId.readAloud)) {
        expect(q.passage, isNotNull);
      }
    });

    test('Q11 은 60초 답변, 45초 준비다', () {
      for (final Question q in questionsOfPart(PartId.expressOpinion)) {
        expect(q.steps.single.answerSeconds, 60);
        expect(q.steps.single.prepSeconds, 45);
      }
    });

    test('사진 묘사 문항은 사진이나 장면 설명 중 하나를 가진다', () {
      for (final Question q in questionsOfPart(PartId.describePicture)) {
        expect(
          q.imagePath != null || q.scene != null,
          isTrue,
          reason: '${q.id} 에 사진(imagePath)도 장면 설명(scene)도 없습니다',
        );
      }
    });

    test('문항 이미지 경로는 에셋 폴더를 가리킨다', () {
      for (final Question q in kQuestions) {
        final String? path = q.imagePath;
        if (path == null) continue;
        expect(
          path.startsWith('assets/images/questions/'),
          isTrue,
          reason: '${q.id} 의 imagePath 가 에셋 폴더 밖을 가리킵니다: $path',
        );
      }
    });

    test('questionById 는 존재하는 id 를 찾고 없는 id 에는 null 을 준다', () {
      expect(questionById(kQuestions.first.id), isNotNull);
      expect(questionById('없는_id'), isNull);
    });
  });

  group('Attempt 직렬화', () {
    test('JSON 왕복 후 값이 보존된다', () {
      final Attempt original = Attempt(
        id: 'a1',
        questionId: 'ra_01',
        partId: PartId.describePicture,
        stepIndex: 2,
        promptLabel: 'Question 7',
        durationSeconds: 30,
        createdAt: DateTime.parse('2026-01-02T03:04:05.000'),
      );

      final Attempt? restored = Attempt.fromJson(original.toJson());

      expect(restored, isNotNull);
      expect(restored!.id, original.id);
      expect(restored.questionId, original.questionId);
      expect(restored.partId, original.partId);
      expect(restored.stepIndex, original.stepIndex);
      expect(restored.promptLabel, original.promptLabel);
      expect(restored.durationSeconds, original.durationSeconds);
      expect(restored.createdAt, original.createdAt);
    });

    test('깨진 JSON 은 null 을 돌려준다', () {
      expect(Attempt.fromJson('{bad json'), isNull);
      expect(Attempt.fromJson('{"id":"x"}'), isNull);
    });
  });
}
