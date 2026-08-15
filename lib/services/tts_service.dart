import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 지문을 읽어 주는 기능. 브라우저에 내장된 음성 합성(Web Speech API)을 쓴다.
///
/// 서버로 텍스트를 보내지 않고, 별도 API 키도 필요 없다.
/// 목소리 품질은 브라우저와 운영체제에 딸린 음성에 따라 달라진다.
class TtsService extends ChangeNotifier {
  TtsService._() {
    _tts
      ..setStartHandler(() {
        _speaking = true;
        notifyListeners();
      })
      ..setCompletionHandler(() {
        _speaking = false;
        notifyListeners();
      })
      ..setCancelHandler(() {
        _speaking = false;
        notifyListeners();
      })
      ..setErrorHandler((Object? message) {
        debugPrint('읽어주기에 실패했습니다: $message');
        _speaking = false;
        _available = false;
        notifyListeners();
      });
  }

  static final TtsService instance = TtsService._();

  /// 웹 SpeechSynthesisUtterance 의 rate 는 1.0 이 보통 속도다.
  static const double normalRate = 1.0;
  static const double slowRate = 0.7;

  final FlutterTts _tts = FlutterTts();

  bool _speaking = false;
  bool _available = true;
  bool _configured = false;
  double _rate = normalRate;

  /// 지금 읽고 있는 문장. 여러 곳에서 버튼을 눌러도 하나만 재생된다.
  String? _currentText;

  bool get isSpeaking => _speaking;
  bool get isAvailable => _available;
  double get rate => _rate;
  bool get isSlow => _rate == slowRate;

  bool isSpeakingText(String text) => _speaking && _currentText == text;

  Future<void> setSlow(bool slow) async {
    _rate = slow ? slowRate : normalRate;
    notifyListeners();
    final String? text = _currentText;
    if (_speaking && text != null) {
      // 속도를 바꾸면 읽던 문장을 새 속도로 다시 시작한다.
      await stop();
      await speak(text);
    }
  }

  /// 같은 문장을 다시 누르면 정지, 다른 문장이면 그쪽으로 전환한다.
  Future<void> toggle(String text) async {
    if (isSpeakingText(text)) {
      await stop();
      return;
    }
    await speak(text);
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await stop();
      if (!_configured) {
        await _tts.setLanguage('en-US');
        await _tts.setVolume(1.0);
        await _tts.setPitch(1.0);
        _configured = true;
      }
      await _tts.setSpeechRate(_rate);
      _currentText = text;
      // 시작 핸들러가 오지 않는 브라우저도 있어 즉시 표시를 켜 둔다.
      _speaking = true;
      notifyListeners();
      await _tts.speak(text);
    } on Object catch (e) {
      debugPrint('읽어주기에 실패했습니다: $e');
      _speaking = false;
      _available = false;
      _currentText = null;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Object catch (e) {
      debugPrint('읽어주기를 멈추지 못했습니다: $e');
    }
    _speaking = false;
    _currentText = null;
    notifyListeners();
  }
}
