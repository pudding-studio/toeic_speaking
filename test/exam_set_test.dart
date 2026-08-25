import 'package:flutter_test/flutter_test.dart';
import 'package:toeic_speaking/data/exam_sets.dart';
import 'package:toeic_speaking/data/question_bank.dart';
import 'package:toeic_speaking/models/exam_set.dart';
import 'package:toeic_speaking/models/question.dart';
import 'package:toeic_speaking/models/toeic_part.dart';

void main() {
  Question? lookupBuiltIn(String id) {
    for (final Question q in kQuestions) {
      if (q.id == id) return q;
    }
    return null;
  }

  group('기본 회차', () {
    test('회차마다 문항 id 가 모두 실제로 있는 문항이다', () {
      for (final ExamSet set in kExamSets) {
        for (final String id in set.questionIds) {
          expect(
            lookupBuiltIn(id),
            isNotNull,
            reason: '${set.title} 의 $id 를 문제 은행에서 찾지 못했습니다.',
          );
        }
      }
    });

    test('회차마다 11문항으로 펼쳐진다', () {
      for (final ExamSet set in kExamSets) {
        final ExamPlan plan = ExamPlan.build(set, lookupBuiltIn);
        expect(
          plan.steps.length,
          11,
          reason: '${set.title} 이 11문항이 아닙니다.',
        );
        expect(plan.isComplete, isTrue);
      }
    });

    test('회차마다 실제 시험과 같은 파트 순서로 짜여 있다', () {
      const List<PartId> expected = <PartId>[
        PartId.readAloud,
        PartId.readAloud,
        PartId.describePicture,
        PartId.describePicture,
        PartId.respondQuestions,
        PartId.respondQuestions,
        PartId.respondQuestions,
        PartId.respondWithInfo,
        PartId.respondWithInfo,
        PartId.respondWithInfo,
        PartId.expressOpinion,
      ];
      for (final ExamSet set in kExamSets) {
        final ExamPlan plan = ExamPlan.build(set, lookupBuiltIn);
        expect(
          plan.steps.map((ExamStep s) => s.partId).toList(),
          expected,
          reason: '${set.title} 의 파트 순서가 실제 시험과 다릅니다.',
        );
      }
    });

    test('회차끼리 문항이 겹치지 않는다', () {
      final Set<String> seen = <String>{};
      for (final ExamSet set in kExamSets) {
        for (final String id in set.questionIds) {
          expect(seen.add(id), isTrue, reason: '$id 가 여러 회차에 들어 있습니다.');
        }
      }
    });

    test('기본 회차는 isCustom 이 false 다', () {
      for (final ExamSet set in kExamSets) {
        expect(set.isCustom, isFalse);
      }
    });
  });

  group('진행표 만들기', () {
    const Question readAloud = Question(
      id: 'q_ra',
      partId: PartId.readAloud,
      title: '낭독',
      passage: 'Attention, passengers.',
    );
    const Question threeQuestions = Question(
      id: 'q_rq',
      partId: PartId.respondQuestions,
      title: '인터뷰',
      prompts: <Prompt>[
        Prompt(text: 'Q5', prepSeconds: 3, answerSeconds: 15),
        Prompt(text: 'Q6', prepSeconds: 3, answerSeconds: 15),
        Prompt(text: 'Q7', prepSeconds: 3, answerSeconds: 30),
      ],
    );

    Question? lookup(String id) => switch (id) {
          'q_ra' => readAloud,
          'q_rq' => threeQuestions,
          _ => null,
        };

    test('질문이 여러 개인 문항은 단계로 펼쳐지고 번호가 이어진다', () {
      final ExamPlan plan = ExamPlan.build(
        const ExamSet(
          id: 's',
          title: '테스트',
          questionIds: <String>['q_ra', 'q_rq'],
        ),
        lookup,
      );

      expect(plan.steps.length, 4);
      expect(
          plan.steps.map((ExamStep s) => s.number).toList(), <int>[1, 2, 3, 4]);
      expect(plan.questionCount, 2);
    });

    test('파트가 바뀌는 첫 단계에서만 안내를 띄운다', () {
      final ExamPlan plan = ExamPlan.build(
        const ExamSet(
          id: 's',
          title: '테스트',
          questionIds: <String>['q_ra', 'q_rq'],
        ),
        lookup,
      );

      expect(
        plan.steps.map((ExamStep s) => s.isPartStart).toList(),
        <bool>[true, true, false, false],
      );
    });

    test('같은 파트가 이어지면 두 번째 문항에서는 안내를 띄우지 않는다', () {
      final ExamPlan plan = ExamPlan.build(
        const ExamSet(
          id: 's',
          title: '테스트',
          questionIds: <String>['q_ra', 'q_ra'],
        ),
        lookup,
      );

      expect(
        plan.steps.map((ExamStep s) => s.isPartStart).toList(),
        <bool>[true, false],
      );
    });

    test('찾지 못한 문항은 건너뛰고 missingIds 에 남는다', () {
      final ExamPlan plan = ExamPlan.build(
        const ExamSet(
          id: 's',
          title: '테스트',
          questionIds: <String>['q_ra', '없는문항', 'q_rq'],
        ),
        lookup,
      );

      expect(plan.missingIds, <String>['없는문항']);
      expect(plan.steps.length, 4);
      expect(plan.isComplete, isFalse);
      // 번호는 실제로 응시하는 문항 기준으로 이어져야 한다.
      expect(plan.steps.last.number, 4);
    });

    test('문항이 하나도 없으면 빈 진행표가 된다', () {
      final ExamPlan plan = ExamPlan.build(
        const ExamSet(id: 's', title: '테스트'),
        lookup,
      );

      expect(plan.isEmpty, isTrue);
      expect(plan.totalDuration, Duration.zero);
    });

    test('총 시간은 준비 시간과 답변 시간을 모두 더한 값이다', () {
      final ExamPlan plan = ExamPlan.build(
        const ExamSet(
          id: 's',
          title: '테스트',
          questionIds: <String>['q_rq'],
        ),
        lookup,
      );

      // (3+15) + (3+15) + (3+30)
      expect(plan.totalDuration, const Duration(seconds: 69));
    });
  });

  group('회차 직렬화', () {
    test('JSON 왕복 후 값이 보존된다', () {
      const ExamSet original = ExamSet(
        id: 'custom_set_1',
        title: '나만의 모의고사 1회',
        subtitle: '지문 · 사진',
        questionIds: <String>['a', 'b', 'c'],
        isCustom: true,
      );

      final ExamSet? restored = ExamSet.fromJson(original.toJson());

      expect(restored, isNotNull);
      expect(restored!.id, original.id);
      expect(restored.title, original.title);
      expect(restored.subtitle, original.subtitle);
      expect(restored.questionIds, original.questionIds);
      expect(restored.isCustom, isTrue);
    });

    test('id 나 이름이 없으면 null 을 돌려준다', () {
      expect(ExamSet.fromMap(<String, dynamic>{'title': '이름만'}), isNull);
      expect(ExamSet.fromMap(<String, dynamic>{'id': 'id만'}), isNull);
    });

    test('깨진 JSON 은 null 을 돌려준다', () {
      expect(ExamSet.fromJson('{어쩌구'), isNull);
    });

    test('isCustom 이 없으면 직접 만든 회차로 본다', () {
      final ExamSet? restored = ExamSet.fromMap(<String, dynamic>{
        'id': 's',
        'title': '이름',
        'questionIds': <String>['a'],
      });

      expect(restored?.isCustom, isTrue);
    });
  });
}
