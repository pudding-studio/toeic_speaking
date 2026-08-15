import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toeic_speaking/models/toeic_part.dart';
import 'package:toeic_speaking/screens/home_screen.dart';
import 'package:toeic_speaking/theme.dart';

void main() {
  Widget wrap() => MaterialApp(
        theme: AppTheme.light(),
        home: const HomeScreen(),
      );

  testWidgets('상단 탭에 전체 + 5개 파트 + 녹음 기록이 모두 있다', (WidgetTester tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final TabBar tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.tabs.length, kToeicParts.length + 2);
  });

  testWidgets('상단 탭은 가로 스크롤이 가능하다', (WidgetTester tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final TabBar tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.isScrollable, isTrue);
  });

  testWidgets('파트 탭으로 이동하면 해당 파트 제목이 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final ToeicPart part = kToeicParts.first;
    await tester.tap(
      find.descendant(
        of: find.byType(TabBar),
        matching: find.text(part.tabLabel),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(part.englishTitle), findsOneWidget);
  });
}
