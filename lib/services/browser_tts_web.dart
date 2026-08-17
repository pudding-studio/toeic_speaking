import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// 브라우저 내장 음성 합성(Web Speech API)을 직접 다룬다.
///
/// `flutter_tts` 의 웹 구현을 쓰지 않는 이유:
/// 그쪽은 `getVoices()` 가 빈 배열이면 언어를 아예 설정하지 않는다. 그런데 크롬은
/// 첫 호출에서 목록을 비워서 돌려주고 나중에 `voiceschanged` 로 채운다. 그 결과
/// 영어 지문을 시스템 기본 음성(한국어 환경이면 한국어)으로 읽는 문제가 생겼다.
/// 여기서는 목록이 채워질 때까지 기다렸다가 영어 음성을 골라 확실히 지정한다.
class BrowserTts {
  BrowserTts();

  web.SpeechSynthesis get _synth => web.window.speechSynthesis;

  /// 마지막으로 고른 음성 이름. 어떤 음성으로 읽는지 화면에 보여 주기 위한 값.
  String? lastVoiceName;

  bool get isSupported => true;

  /// 목록이 채워질 때까지 기다린다. 크롬은 처음에 빈 배열을 돌려준다.
  Future<List<web.SpeechSynthesisVoice>> _voices() async {
    List<web.SpeechSynthesisVoice> list = _synth.getVoices().toDart;
    if (list.isNotEmpty) return list;

    final Completer<void> ready = Completer<void>();
    _synth.onvoiceschanged = (web.Event _) {
      if (!ready.isCompleted) ready.complete();
    }.toJS;
    // 이벤트가 오지 않는 브라우저도 있으므로 짧게만 기다린다.
    await ready.future.timeout(
      const Duration(milliseconds: 1500),
      onTimeout: () {},
    );
    _synth.onvoiceschanged = null;

    list = _synth.getVoices().toDart;
    return list;
  }

  /// [languageCode] 에 맞는 음성을 고른다. 정확히 맞는 것 → 같은 언어 → 없으면 null.
  web.SpeechSynthesisVoice? _pick(
    List<web.SpeechSynthesisVoice> voices,
    String languageCode,
  ) {
    if (voices.isEmpty) return null;
    final String wanted = languageCode.toLowerCase();
    final String prefix = wanted.split('-').first;

    // 1) en-US 처럼 완전히 일치
    for (final web.SpeechSynthesisVoice v in voices) {
      if (v.lang.toLowerCase().replaceAll('_', '-') == wanted) return v;
    }
    // 2) 같은 언어의 다른 지역 (en-GB 등). 기기 내장 음성을 먼저 본다.
    final List<web.SpeechSynthesisVoice> sameLanguage = voices
        .where((web.SpeechSynthesisVoice v) =>
            v.lang.toLowerCase().startsWith(prefix))
        .toList()
      ..sort((web.SpeechSynthesisVoice a, web.SpeechSynthesisVoice b) {
        if (a.localService == b.localService) return 0;
        return a.localService ? -1 : 1;
      });
    return sameLanguage.isEmpty ? null : sameLanguage.first;
  }

  /// 읽기 시작한다. 끝나거나 실패하면 콜백으로 알려 준다.
  Future<void> speak(
    String text, {
    required String languageCode,
    required double rate,
    VoidCallback? onStart,
    VoidCallback? onDone,
    void Function(String message)? onError,
  }) async {
    stop();

    final List<web.SpeechSynthesisVoice> voices = await _voices();
    final web.SpeechSynthesisVoice? voice = _pick(voices, languageCode);

    final web.SpeechSynthesisUtterance utterance =
        web.SpeechSynthesisUtterance(text);
    // 음성을 못 골랐더라도 lang 은 반드시 지정한다.
    // 이것만으로도 대부분의 브라우저가 해당 언어 음성을 쓴다.
    utterance.lang = voice?.lang ?? languageCode;
    if (voice != null) utterance.voice = voice;
    utterance.rate = rate;
    utterance.volume = 1.0;
    utterance.pitch = 1.0;

    lastVoiceName = voice?.name;
    if (voice == null) {
      debugPrint('$languageCode 음성을 찾지 못해 브라우저 기본 음성으로 읽습니다.');
    }

    utterance.onstart = (web.Event _) {
      onStart?.call();
    }.toJS;
    utterance.onend = (web.Event _) {
      onDone?.call();
    }.toJS;
    utterance.onerror = (web.Event _) {
      onError?.call('읽어주기에 실패했습니다.');
    }.toJS;

    _synth.speak(utterance);
  }

  void stop() {
    try {
      _synth.cancel();
    } on Object catch (e) {
      debugPrint('읽어주기를 멈추지 못했습니다: $e');
    }
  }
}
