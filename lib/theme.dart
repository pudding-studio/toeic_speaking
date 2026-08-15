import 'package:flutter/material.dart';

import 'models/toeic_part.dart';

class AppTheme {
  static const Color seed = Color(0xFF2F5BEA);

  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF6F7FB)
          : scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  /// 파트별 강조 색. 탭·배지·카드 액센트에 일관되게 사용한다.
  static Color partColor(PartId id) {
    switch (id) {
      case PartId.readAloud:
        return const Color(0xFF2F5BEA);
      case PartId.describePicture:
        return const Color(0xFF00897B);
      case PartId.respondQuestions:
        return const Color(0xFFE07A1F);
      case PartId.respondWithInfo:
        return const Color(0xFF7B3FE4);
      case PartId.expressOpinion:
        return const Color(0xFFD1425A);
    }
  }

  static IconData partIcon(PartId id) {
    switch (id) {
      case PartId.readAloud:
        return Icons.record_voice_over_outlined;
      case PartId.describePicture:
        return Icons.image_outlined;
      case PartId.respondQuestions:
        return Icons.headset_mic_outlined;
      case PartId.respondWithInfo:
        return Icons.table_chart_outlined;
      case PartId.expressOpinion:
        return Icons.forum_outlined;
    }
  }
}

String formatSeconds(int seconds) {
  final int m = seconds ~/ 60;
  final int s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
