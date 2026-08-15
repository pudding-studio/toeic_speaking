import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toeic_speaking/models/question.dart';
import 'package:toeic_speaking/models/toeic_part.dart';
import 'package:toeic_speaking/screens/practice_screen.dart';
import 'package:toeic_speaking/theme.dart';
import 'package:toeic_speaking/widgets/tts_controls.dart';

void main() {
  Widget wrap(Question question) => MaterialApp(
        theme: AppTheme.light(),
        home: PracticeScreen(question: question),
      );

  const Question readAloud = Question(
    id: 'test_ra',
    partId: PartId.readAloud,
    title: '낭독 문항',
    passage: 'Attention, passengers.',
  );

  const Question opinion = Question(
    id: 'test_eo',
    partId: PartId.expressOpinion,
    title: '의견 문항',
    prompts: <Prompt>[
      Prompt(text: 'Do you agree?', prepSeconds: 45, answerSeconds: 60),
    ],
  );

  testWidgets('낭독 문항에는 읽어주기 컨트롤이 있다', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(readAloud));
    await tester.pump();

    expect(find.byType(TtsControls), findsOneWidget);
    expect(find.text('들어보기'), findsOneWidget);
    expect(find.text('보통'), findsOneWidget);
    expect(find.text('느리게'), findsOneWidget);
  });

  testWidgets('읽을 지문이 없는 문항에는 읽어주기 컨트롤이 없다', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(opinion));
    await tester.pump();

    expect(find.byType(TtsControls), findsNothing);
  });

  testWidgets('컨트롤을 끄면 버튼이 비활성화되고 안내가 뜬다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: TtsControls(
            text: 'hello',
            color: Colors.blue,
            enabled: false,
          ),
        ),
      ),
    );
    await tester.pump();

    final FilledButton button = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(button.onPressed, isNull);
    expect(find.text('녹음 중에는 멈춤'), findsOneWidget);
  });
}
