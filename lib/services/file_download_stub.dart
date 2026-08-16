import 'package:flutter/foundation.dart';

/// 웹이 아닌 환경(위젯 테스트 등)에서 쓰이는 빈 구현.
void downloadBytes({
  required Uint8List bytes,
  required String fileName,
  String mimeType = 'application/octet-stream',
}) {
  debugPrint('이 환경에서는 파일을 내려받을 수 없습니다: $fileName');
}
