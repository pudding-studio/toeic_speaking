import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toeic_speaking/models/question.dart';
import 'package:toeic_speaking/models/toeic_part.dart';
import 'package:toeic_speaking/screens/practice_screen.dart';
import 'package:toeic_speaking/theme.dart';
import 'package:toeic_speaking/widgets/tts_controls.dart';

void main() {
  Widget wrapQuestion(Question question) => MaterialApp(
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

  group('연습 화면의 읽어주기 노출', () {
    testWidgets('낭독 문항에는 읽어주기 컨트롤이 있다', (WidgetTester tester) async {
      await tester.pumpWidget(wrapQuestion(readAloud));
      await tester.pump();
      expect(find.byType(TtsControls), findsOneWidget);
    });

    testWidgets('읽을 지문이 없는 문항에는 읽어주기 컨트롤이 없다', (WidgetTester tester) async {
      await tester.pumpWidget(wrapQuestion(opinion));
      await tester.pump();
      expect(find.byType(TtsControls), findsNothing);
    });
  });

  group('읽어주기 컨트롤 겉모습', () {
    Widget wrapView({
      bool enabled = true,
      bool available = true,
      bool speaking = false,
      bool loading = false,
      bool slow = false,
      String statusLabel = '브라우저 음성',
      VoidCallback? onToggle,
      ValueChanged<bool>? onSlowChanged,
    }) {
      return MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: TtsControlsView(
            color: Colors.blue,
            enabled: enabled,
            available: available,
            speaking: speaking,
            loading: loading,
            slow: slow,
            statusLabel: statusLabel,
            onToggle: onToggle ?? () {},
            onSlowChanged: onSlowChanged ?? (bool _) {},
          ),
        ),
      );
    }

    testWidgets('평소에는 들어보기 버튼과 속도 선택이 보인다', (WidgetTester tester) async {
      await tester.pumpWidget(wrapView());
      expect(find.text('들어보기'), findsOneWidget);
      expect(find.text('보통'), findsOneWidget);
      expect(find.text('느리게'), findsOneWidget);
    });

    testWidgets('읽는 중에는 정지로 바뀐다', (WidgetTester tester) async {
      await tester.pumpWidget(wrapView(speaking: true));
      expect(find.text('정지'), findsOneWidget);
      expect(find.text('들어보기'), findsNothing);
    });

    testWidgets('음성을 만드는 중에는 버튼이 잠긴다', (WidgetTester tester) async {
      await tester.pumpWidget(wrapView(loading: true));
      expect(find.text('만드는 중'), findsOneWidget);
      final FilledButton button =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('녹음 중에는 버튼이 잠기고 안내가 뜬다', (WidgetTester tester) async {
      await tester
          .pumpWidget(wrapView(enabled: false, statusLabel: '녹음 중에는 멈춤'));
      final FilledButton button =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.text('녹음 중에는 멈춤'), findsOneWidget);
    });

    testWidgets('쓸 수 없는 환경에서는 안내만 보여 준다', (WidgetTester tester) async {
      await tester.pumpWidget(wrapView(available: false));
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('이 브라우저에서는 읽어주기를 쓸 수 없습니다.'), findsOneWidget);
    });

    testWidgets('버튼을 누르면 콜백이 불린다', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(wrapView(onToggle: () => taps++));
      await tester.tap(find.text('들어보기'));
      expect(taps, 1);
    });

    testWidgets('속도를 바꾸면 콜백에 값이 전달된다', (WidgetTester tester) async {
      bool? received;
      await tester.pumpWidget(
        wrapView(onSlowChanged: (bool slow) => received = slow),
      );
      await tester.tap(find.text('느리게'));
      expect(received, isTrue);
    });

    testWidgets('현재 엔진·음성 이름이 표시된다', (WidgetTester tester) async {
      await tester.pumpWidget(wrapView(statusLabel: '브라우저 음성 · Samantha'));
      expect(find.text('브라우저 음성 · Samantha'), findsOneWidget);
    });
  });
}
