import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toeic_speaking/models/question.dart';
import 'package:toeic_speaking/models/toeic_part.dart';
import 'package:toeic_speaking/screens/practice_screen.dart';
import 'package:toeic_speaking/theme.dart';

void main() {
  Widget wrap(Question question) => MaterialApp(
        theme: AppTheme.light(),
        home: PracticeScreen(question: question),
      );

  const Question withImage = Question(
    id: 'test_img',
    partId: PartId.describePicture,
    title: '사진 있는 문항',
    imagePath: 'assets/images/questions/test.jpg',
    scene: SceneHint(place: '테스트 장소', details: <String>['테스트 상세']),
  );

  const Question withSceneOnly = Question(
    id: 'test_scene',
    partId: PartId.describePicture,
    title: '사진 없는 문항',
    scene: SceneHint(place: '테스트 장소', details: <String>['테스트 상세']),
  );

  testWidgets('imagePath 가 있으면 사진을 보여 준다', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(withImage));
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('사진'), findsOneWidget);
  });

  testWidgets('사진이 있으면 텍스트 장면 설명은 생략한다', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(withImage));
    await tester.pump();

    expect(find.text('사진 상황'), findsNothing);
    expect(find.text('테스트 장소'), findsNothing);
  });

  testWidgets('사진이 없으면 텍스트 장면 설명을 보여 준다', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(withSceneOnly));
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.text('사진 상황'), findsOneWidget);
    expect(find.text('테스트 장소'), findsOneWidget);
  });

  testWidgets('에셋을 못 찾아도 화면이 깨지지 않는다', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(withImage));
    await tester.pumpAndSettle();

    // errorBuilder 가 대체 화면을 그리고, 연습 시작 버튼은 그대로 눌릴 수 있어야 한다.
    expect(tester.takeException(), isNull);
    expect(find.text('연습 시작'), findsOneWidget);
  });
}
