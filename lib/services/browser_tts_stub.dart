import 'package:flutter/foundation.dart';

/// 웹이 아닌 환경(위젯 테스트 등)에서 쓰이는 빈 구현.
class BrowserTts {
  BrowserTts();

  String? lastVoiceName;

  bool get isSupported => false;

  Future<void> speak(
    String text, {
    required String languageCode,
    required double rate,
    VoidCallback? onStart,
    VoidCallback? onDone,
    void Function(String message)? onError,
  }) async {
    onError?.call('이 환경에서는 읽어주기를 쓸 수 없습니다.');
  }

  void stop() {}
}
