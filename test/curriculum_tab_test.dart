import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toeic_speaking/data/curricula.dart';
import 'package:toeic_speaking/models/curriculum.dart';
import 'package:toeic_speaking/models/toeic_part.dart';
import 'package:toeic_speaking/screens/curriculum_tab.dart';
import 'package:toeic_speaking/theme.dart';

void main() {
  Widget wrap() => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: CurriculumTab(
            onSelectPart: (PartId _) {},
            onSelectExam: () {},
          ),
        ),
      );

  group('학습 계획 탭', () {
    // 저장소를 쓸 수 없는 테스트 환경에서는 진행 중인 계획이 없으므로
    // 언제나 계획 고르기 화면이 나온다.
    testWidgets('계획을 고르기 전에는 안내와 고르기 버튼을 보여 준다', (WidgetTester tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text('학습 계획'), findsOneWidget);
      expect(find.text('계획 고르기'), findsOneWidget);
    });

    testWidgets('고를 수 있는 계획을 모두 보여 준다', (WidgetTester tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      for (final Curriculum c in kCurricula) {
        expect(
          find.textContaining(c.title),
          findsWidgets,
          reason: '${c.title} 이 목록에 없습니다.',
        );
      }
    });

    testWidgets('계획 소개에 하루 평균 시간과 실전 횟수가 들어 있다', (WidgetTester tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      final Curriculum first = kCurricula.first;
      expect(
        find.text(
          '${first.title} · 하루 평균 ${first.averageMinutes}분 · '
          '실전 ${first.examCount}회',
        ),
        findsOneWidget,
      );
    });
  });
}
