/// 브라우저 내장 음성 합성. 웹에서만 실제로 동작한다.
///
/// `package:web` 은 웹에서만 컴파일되므로, Dart VM(위젯 테스트 등)에서는
/// 아무 것도 하지 않는 구현이 대신 쓰이도록 조건부로 가져온다.
library;

export 'browser_tts_stub.dart'
    if (dart.library.js_interop) 'browser_tts_web.dart';
