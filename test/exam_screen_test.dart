import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toeic_speaking/models/attempt.dart';
import 'package:toeic_speaking/models/exam_set.dart';
import 'package:toeic_speaking/models/question.dart';
import 'package:toeic_speaking/models/toeic_part.dart';
import 'package:toeic_speaking/screens/exam_screen.dart';
import 'package:toeic_speaking/theme.dart';

void main() {
  const Question readAloud = Question(
    id: 'q_ra',
    partId: PartId.readAloud,
    title: '공항 안내 방송',
    passage: 'Attention, passengers.',
    sampleAnswer: '모범 답안입니다.',
    keyExpressions: <String>['Attention, passengers.'],
  );
  const Question opinion = Question(
    id: 'q_eo',
    partId: PartId.expressOpinion,
    title: '재택근무',
    prompts: <Prompt>[
      Prompt(text: 'Do you agree?', prepSeconds: 45, answerSeconds: 60),
    ],
  );

  Question? lookup(String id) => switch (id) {
        'q_ra' => readAloud,
        'q_eo' => opinion,
        _ => null,
      };

  ExamPlan planOf(List<String> ids) => ExamPlan.build(
        ExamSet(id: 'set_test', title: '테스트 모의고사', questionIds: ids),
        lookup,
      );

  Widget wrap(ExamPlan plan) => MaterialApp(
        theme: AppTheme.light(),
        home: ExamScreen(plan: plan),
      );

  group('모의고사 시작 화면', () {
    testWidgets('회차 이름과 문항 수를 보여 준다', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(planOf(<String>['q_ra', 'q_eo'])));
      await tester.pump();

      expect(find.text('테스트 모의고사'), findsWidgets);
      expect(find.text('모의고사 시작 (2문항)'), findsOneWidget);
    });

    testWidgets('시작 전에는 모범 답안이 보이지 않는다', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(planOf(<String>['q_ra'])));
      await tester.pump();

      expect(find.text('모범 답안'), findsNothing);
      expect(find.text('모범 답안입니다.'), findsNothing);
    });

    testWidgets('문항이 없는 회차는 시작 버튼이 잠긴다', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(planOf(<String>[])));
      await tester.pump();

      final FilledButton button =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('찾지 못한 문항이 있으면 안내가 뜬다', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(planOf(<String>['q_ra', '지워진문항'])));
      await tester.pump();

      expect(find.textContaining('찾지 못해 건너뜁니다'), findsOneWidget);
    });

    testWidgets('시작 전 주의 사항을 보여 준다', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(planOf(<String>['q_ra'])));
      await tester.pump();

      expect(find.text('시작하기 전에'), findsOneWidget);
      expect(find.textContaining('저절로 흘러갑니다'), findsOneWidget);
    });
  });

  group('모의고사 녹음 기록', () {
    test('회차 정보가 JSON 왕복 후 보존된다', () {
      final Attempt original = Attempt(
        id: 'a1',
        questionId: 'q_ra',
        partId: PartId.readAloud,
        stepIndex: 0,
        promptLabel: 'Q1 · 공항 안내 방송',
        durationSeconds: 45,
        createdAt: DateTime(2026, 8, 25, 10, 30),
        examSetId: 'set_01',
        questionNumber: 1,
      );

      final Attempt? restored = Attempt.fromJson(original.toJson());

      expect(restored, isNotNull);
      expect(restored!.examSetId, 'set_01');
      expect(restored.questionNumber, 1);
      expect(restored.isExam, isTrue);
    });

    test('낱개 연습 녹음은 회차 정보가 비어 있다', () {
      final Attempt original = Attempt(
        id: 'a2',
        questionId: 'q_ra',
        partId: PartId.readAloud,
        stepIndex: 0,
        promptLabel: '공항 안내 방송',
        durationSeconds: 45,
        createdAt: DateTime(2026, 8, 25, 10, 30),
      );

      final Attempt? restored = Attempt.fromJson(original.toJson());

      expect(restored?.examSetId, isNull);
      expect(restored?.questionNumber, isNull);
      expect(restored?.isExam, isFalse);
    });
  });
}
