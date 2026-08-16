import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'question_store.dart';

/// 문항에 붙여 둔 예시 음성을 재생한다.
/// 한 번에 하나만 재생되고, 답변 녹음과 겹치지 않도록 화면 쪽에서 막는다.
class SampleAudioService extends ChangeNotifier {
  SampleAudioService._() {
    _player.onPlayerComplete.listen((void _) {
      _playingId = null;
      notifyListeners();
    });
  }

  static final SampleAudioService instance = SampleAudioService._();

  final AudioPlayer _player = AudioPlayer();

  String? _playingId;
  String? _loadingId;

  bool isPlaying(String questionId) => _playingId == questionId;
  bool isLoading(String questionId) => _loadingId == questionId;

  /// 같은 문항을 다시 누르면 정지, 다른 문항이면 그쪽으로 전환한다.
  Future<void> toggle(String questionId) async {
    if (_playingId == questionId || _loadingId == questionId) {
      await stop();
      return;
    }
    await _player.stop();
    _playingId = null;
    _loadingId = questionId;
    notifyListeners();

    final Uint8List? bytes = await QuestionStore.instance.audioOf(questionId);
    if (_loadingId != questionId) return; // 그 사이 취소되었다

    if (bytes == null || bytes.isEmpty) {
      debugPrint('예시 음성을 찾지 못했습니다: $questionId');
      _loadingId = null;
      notifyListeners();
      return;
    }

    try {
      _loadingId = null;
      _playingId = questionId;
      notifyListeners();
      await _player.play(BytesSource(bytes));
    } on Object catch (e) {
      debugPrint('예시 음성 재생에 실패했습니다: $e');
      _playingId = null;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _playingId = null;
    _loadingId = null;
    notifyListeners();
  }
}
