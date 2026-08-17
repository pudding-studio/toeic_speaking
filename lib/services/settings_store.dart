import 'package:flutter/foundation.dart';

import 'local_storage.dart';

/// Google Cloud Text-to-Speech 에서 고를 수 있는 음성.
/// Neural2 계열은 사람 목소리에 가깝고, 월 100만 자까지 무료 한도가 있다.
class TtsVoice {
  const TtsVoice({
    required this.name,
    required this.languageCode,
    required this.label,
  });

  /// 예) 'en-US-Neural2-C'
  final String name;

  /// 예) 'en-US'
  final String languageCode;

  /// 화면에 보여 줄 이름.
  final String label;
}

const List<TtsVoice> kTtsVoices = <TtsVoice>[
  TtsVoice(
    name: 'en-US-Neural2-C',
    languageCode: 'en-US',
    label: '미국 영어 · 여성 (C)',
  ),
  TtsVoice(
    name: 'en-US-Neural2-F',
    languageCode: 'en-US',
    label: '미국 영어 · 여성 (F)',
  ),
  TtsVoice(
    name: 'en-US-Neural2-D',
    languageCode: 'en-US',
    label: '미국 영어 · 남성 (D)',
  ),
  TtsVoice(
    name: 'en-US-Neural2-J',
    languageCode: 'en-US',
    label: '미국 영어 · 남성 (J)',
  ),
  TtsVoice(
    name: 'en-GB-Neural2-A',
    languageCode: 'en-GB',
    label: '영국 영어 · 여성 (A)',
  ),
  TtsVoice(
    name: 'en-GB-Neural2-B',
    languageCode: 'en-GB',
    label: '영국 영어 · 남성 (B)',
  ),
  TtsVoice(
    name: 'en-AU-Neural2-A',
    languageCode: 'en-AU',
    label: '호주 영어 · 여성 (A)',
  ),
];

/// 이 브라우저에만 저장되는 설정.
class SettingsStore extends ChangeNotifier {
  SettingsStore._();

  static final SettingsStore instance = SettingsStore._();

  static const String _keyApiKey = 'googleTtsApiKey';
  static const String _keyVoice = 'ttsVoiceName';

  String? _apiKey;
  String _voiceName = kTtsVoices.first.name;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// 키가 없으면 브라우저 내장 음성으로 읽는다.
  String? get apiKey => _apiKey;
  bool get hasApiKey => (_apiKey ?? '').isNotEmpty;

  TtsVoice get voice => kTtsVoices.firstWhere(
        (TtsVoice v) => v.name == _voiceName,
        orElse: () => kTtsVoices.first,
      );

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final List<String?> values = await Future.wait(<Future<String?>>[
      LocalStorage.instance.loadSetting(_keyApiKey),
      LocalStorage.instance.loadSetting(_keyVoice),
    ]);
    _apiKey = values[0];
    _voiceName = values[1] ?? kTtsVoices.first.name;
    notifyListeners();
  }

  Future<void> setApiKey(String? key) async {
    final String? trimmed = (key ?? '').trim().isEmpty ? null : key!.trim();
    _apiKey = trimmed;
    notifyListeners();
    await LocalStorage.instance.saveSetting(_keyApiKey, trimmed);
  }

  Future<void> setVoice(String voiceName) async {
    _voiceName = voiceName;
    notifyListeners();
    await LocalStorage.instance.saveSetting(_keyVoice, voiceName);
  }
}
