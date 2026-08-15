import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

import 'local_storage.dart';
import 'settings_store.dart';

/// 읽어주기에 쓰는 엔진.
enum TtsEngine {
  /// 브라우저 내장 음성 합성(Web Speech API). 무료지만 기계적으로 들린다.
  browser,

  /// Google Cloud Text-to-Speech. 자연스럽지만 API 키가 필요하다.
  google,
}

/// 지문을 읽어 준다.
///
/// 설정에 Google Cloud API 키가 있으면 그쪽을 쓰고, 없으면 브라우저 내장 음성으로
/// 대신 읽는다. Google 음성으로 만든 오디오는 IndexedDB 에 저장해 두고 같은 문장을
/// 다시 들을 때는 API 를 부르지 않는다(요금이 다시 발생하지 않는다).
class TtsService extends ChangeNotifier {
  TtsService._() {
    _browserTts
      ..setStartHandler(_onStart)
      ..setCompletionHandler(_onDone)
      ..setCancelHandler(_onDone)
      ..setErrorHandler((Object? message) {
        debugPrint('브라우저 읽어주기에 실패했습니다: $message');
        _browserAvailable = false;
        _onDone();
      });
    _player.onPlayerComplete.listen((void _) => _onDone());
  }

  static final TtsService instance = TtsService._();

  /// 웹 SpeechSynthesisUtterance 의 rate 는 1.0 이 보통 속도다.
  /// Google TTS 의 speakingRate 도 1.0 이 기준이라 값을 그대로 공유한다.
  static const double normalRate = 1.0;
  static const double slowRate = 0.7;

  static const String _endpoint =
      'https://texttospeech.googleapis.com/v1/text:synthesize';

  final FlutterTts _browserTts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();

  bool _speaking = false;
  bool _loading = false;
  bool _browserAvailable = true;
  bool _configured = false;
  double _rate = normalRate;
  String? _currentText;
  String? _lastError;

  bool get isSpeaking => _speaking;
  bool get isLoading => _loading;
  double get rate => _rate;
  bool get isSlow => _rate == slowRate;

  /// 마지막으로 실패한 이유. 성공하면 null 로 지워진다.
  String? get lastError => _lastError;

  /// 지금 쓰는 엔진.
  TtsEngine get engine =>
      SettingsStore.instance.hasApiKey ? TtsEngine.google : TtsEngine.browser;

  /// 브라우저 음성조차 쓸 수 없는 상태인지.
  bool get isAvailable => engine == TtsEngine.google || _browserAvailable;

  bool isSpeakingText(String text) => _speaking && _currentText == text;
  bool isLoadingText(String text) => _loading && _currentText == text;

  void _onStart() {
    _speaking = true;
    _loading = false;
    notifyListeners();
  }

  void _onDone() {
    _speaking = false;
    _loading = false;
    _currentText = null;
    notifyListeners();
  }

  Future<void> setSlow(bool slow) async {
    _rate = slow ? slowRate : normalRate;
    notifyListeners();
    final String? text = _currentText;
    if ((_speaking || _loading) && text != null) {
      // 속도를 바꾸면 읽던 문장을 새 속도로 다시 시작한다.
      await stop();
      await speak(text);
    }
  }

  /// 같은 문장을 다시 누르면 정지, 다른 문장이면 그쪽으로 전환한다.
  Future<void> toggle(String text) async {
    if (isSpeakingText(text) || isLoadingText(text)) {
      await stop();
      return;
    }
    await speak(text);
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await stop();
    _lastError = null;
    _currentText = text;

    if (SettingsStore.instance.hasApiKey) {
      _loading = true;
      notifyListeners();
      final Uint8List? audio = await _googleAudio(text);
      if (_currentText != text) return; // 그 사이 취소되었다
      if (audio != null) {
        try {
          _loading = false;
          _speaking = true;
          notifyListeners();
          await _player.play(BytesSource(audio, mimeType: 'audio/mpeg'));
          return;
        } on Object catch (e) {
          debugPrint('음성 재생에 실패했습니다: $e');
          _lastError = '음성을 재생하지 못했습니다.';
        }
      }
      // Google 쪽이 실패하면 브라우저 음성으로라도 읽어 준다.
      _loading = false;
      notifyListeners();
    }

    await _speakWithBrowser(text);
  }

  Future<void> _speakWithBrowser(String text) async {
    if (!_browserAvailable) {
      _onDone();
      return;
    }
    try {
      if (!_configured) {
        await _browserTts
            .setLanguage(SettingsStore.instance.voice.languageCode);
        await _browserTts.setVolume(1.0);
        await _browserTts.setPitch(1.0);
        _configured = true;
      }
      await _browserTts.setSpeechRate(_rate);
      _currentText = text;
      // 시작 핸들러가 오지 않는 브라우저도 있어 즉시 표시를 켜 둔다.
      _speaking = true;
      notifyListeners();
      await _browserTts.speak(text);
    } on Object catch (e) {
      debugPrint('브라우저 읽어주기에 실패했습니다: $e');
      _browserAvailable = false;
      _lastError = '이 브라우저에서는 읽어주기를 쓸 수 없습니다.';
      _onDone();
    }
  }

  /// 캐시에 있으면 그대로 쓰고, 없으면 Google TTS 를 불러 만들고 저장한다.
  Future<Uint8List?> _googleAudio(String text) async {
    final SettingsStore settings = SettingsStore.instance;
    final String cacheKey = ttsCacheKey(
      text: text,
      voiceName: settings.voice.name,
      rate: _rate,
    );

    final Uint8List? cached =
        await LocalStorage.instance.loadTtsAudio(cacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    final Uint8List? fresh = await synthesize(
      text: text,
      apiKey: settings.apiKey!,
      voice: settings.voice,
      rate: _rate,
      onError: (String message) => _lastError = message,
    );
    if (fresh == null) return null;

    await LocalStorage.instance.saveTtsAudio(cacheKey, fresh);
    return fresh;
  }

  /// Google Cloud Text-to-Speech 를 호출해 mp3 바이트를 받는다.
  /// 실패하면 [onError] 로 사람이 읽을 수 있는 이유를 넘기고 null 을 돌려준다.
  static Future<Uint8List?> synthesize({
    required String text,
    required String apiKey,
    required TtsVoice voice,
    required double rate,
    void Function(String message)? onError,
  }) async {
    try {
      final http.Response response = await http
          .post(
            Uri.parse('$_endpoint?key=$apiKey'),
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, dynamic>{
              'input': <String, String>{'text': text},
              'voice': <String, String>{
                'languageCode': voice.languageCode,
                'name': voice.name,
              },
              'audioConfig': <String, dynamic>{
                'audioEncoding': 'MP3',
                'speakingRate': rate,
              },
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        onError?.call(_errorMessage(response));
        debugPrint('Google TTS 오류 ${response.statusCode}: ${response.body}');
        return null;
      }

      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        onError?.call('응답을 이해하지 못했습니다.');
        return null;
      }
      final String? content = decoded['audioContent'] as String?;
      if (content == null || content.isEmpty) {
        onError?.call('응답에 음성이 없습니다.');
        return null;
      }
      return base64Decode(content);
    } on Object catch (e) {
      debugPrint('Google TTS 호출에 실패했습니다: $e');
      onError?.call('음성을 만들지 못했습니다. 네트워크 상태를 확인해 주세요.');
      return null;
    }
  }

  /// HTTP 오류를 한국어 안내로 바꾼다.
  static String _errorMessage(http.Response response) {
    String detail = '';
    try {
      final Object? decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final Object? error = decoded['error'];
        if (error is Map<String, dynamic>) {
          detail = (error['message'] as String?) ?? '';
        }
      }
    } on FormatException {
      detail = '';
    }

    switch (response.statusCode) {
      case 400:
        return 'API 키가 올바르지 않습니다. 다시 확인해 주세요.';
      case 403:
        return 'API 키가 거부되었습니다. Cloud Text-to-Speech API 가 켜져 있는지, '
            '키 제한이 이 사이트를 막고 있지 않은지 확인해 주세요.'
            '${detail.isEmpty ? '' : '\n($detail)'}';
      case 429:
        return '요청 한도를 넘었습니다. 잠시 후 다시 시도해 주세요.';
      default:
        return '음성을 만들지 못했습니다 (오류 ${response.statusCode}).'
            '${detail.isEmpty ? '' : '\n$detail'}';
    }
  }

  Future<void> stop() async {
    try {
      await _browserTts.stop();
    } on Object catch (e) {
      debugPrint('읽어주기를 멈추지 못했습니다: $e');
    }
    try {
      await _player.stop();
    } on Object catch (e) {
      debugPrint('음성 재생을 멈추지 못했습니다: $e');
    }
    _speaking = false;
    _loading = false;
    _currentText = null;
    notifyListeners();
  }
}

/// 같은 문장·음성·속도면 같은 키가 나온다. 캐시 적중 여부를 결정한다.
String ttsCacheKey({
  required String text,
  required String voiceName,
  required double rate,
}) {
  final Digest digest = sha256.convert(utf8.encode(text));
  return '${voiceName}_${rate.toStringAsFixed(2)}_$digest';
}
