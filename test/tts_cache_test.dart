import 'package:flutter_test/flutter_test.dart';
import 'package:toeic_speaking/services/settings_store.dart';
import 'package:toeic_speaking/services/tts_service.dart';

void main() {
  group('음성 캐시 키', () {
    const String text = 'Attention, passengers.';

    test('같은 문장·음성·속도면 같은 키가 나온다', () {
      final String a =
          ttsCacheKey(text: text, voiceName: 'en-US-Neural2-C', rate: 1.0);
      final String b =
          ttsCacheKey(text: text, voiceName: 'en-US-Neural2-C', rate: 1.0);
      expect(a, b);
    });

    test('문장이 다르면 키가 다르다', () {
      final String a =
          ttsCacheKey(text: text, voiceName: 'en-US-Neural2-C', rate: 1.0);
      final String b = ttsCacheKey(
          text: 'Different.', voiceName: 'en-US-Neural2-C', rate: 1.0);
      expect(a, isNot(b));
    });

    test('음성이 다르면 키가 다르다', () {
      final String a =
          ttsCacheKey(text: text, voiceName: 'en-US-Neural2-C', rate: 1.0);
      final String b =
          ttsCacheKey(text: text, voiceName: 'en-US-Neural2-D', rate: 1.0);
      expect(a, isNot(b));
    });

    test('속도가 다르면 키가 다르다', () {
      final String normal = ttsCacheKey(
        text: text,
        voiceName: 'en-US-Neural2-C',
        rate: TtsService.normalRate,
      );
      final String slow = ttsCacheKey(
        text: text,
        voiceName: 'en-US-Neural2-C',
        rate: TtsService.slowRate,
      );
      expect(normal, isNot(slow));
    });
  });

  group('음성 목록', () {
    test('이름이 중복되지 않는다', () {
      final Set<String> names = kTtsVoices.map((TtsVoice v) => v.name).toSet();
      expect(names.length, kTtsVoices.length);
    });

    test('음성 이름은 해당 언어 코드로 시작한다', () {
      for (final TtsVoice v in kTtsVoices) {
        expect(
          v.name.startsWith(v.languageCode),
          isTrue,
          reason: '${v.name} 이 ${v.languageCode} 로 시작하지 않습니다',
        );
      }
    });
  });
}
