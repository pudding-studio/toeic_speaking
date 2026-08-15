import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/attempt_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AttemptStore.instance.load();
  runApp(const ToeicSpeakingApp());
}

class ToeicSpeakingApp extends StatelessWidget {
  const ToeicSpeakingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOEIC Speaking 연습',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      // 넓은 화면(PC 브라우저)에서 화면 전체로 늘어나지 않도록 가운데 정렬한다.
      builder: (BuildContext context, Widget? child) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
