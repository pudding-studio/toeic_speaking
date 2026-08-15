import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'recording_storage.dart';

/// 녹음 재생 담당. 한 번에 하나만 재생한다.
/// 오디오는 재생 직전에 IndexedDB 에서 꺼내 온다.
class PlaybackService extends ChangeNotifier {
  PlaybackService._() {
    _player.onPlayerComplete.listen((void _) {
      _playingId = null;
      _position = Duration.zero;
      notifyListeners();
    });
    _player.onPositionChanged.listen((Duration p) {
      _position = p;
      notifyListeners();
    });
    _player.onDurationChanged.listen((Duration d) {
      _duration = d;
      notifyListeners();
    });
  }

  static final PlaybackService instance = PlaybackService._();

  final AudioPlayer _player = AudioPlayer();

  /// 캐시해 둔 data URL. 같은 녹음을 다시 들을 때 IndexedDB 를 또 읽지 않는다.
  final Map<String, String> _cache = <String, String>{};

  String? _playingId;
  String? _loadingId;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  String? get playingId => _playingId;
  Duration get position => _position;
  Duration get duration => _duration;

  bool isPlaying(String attemptId) => _playingId == attemptId;
  bool isLoading(String attemptId) => _loadingId == attemptId;

  /// 방금 녹음한 오디오를 캐시에 넣어 둔다(저장이 끝나기 전에도 바로 들을 수 있게).
  void cache(String attemptId, String dataUrl) => _cache[attemptId] = dataUrl;

  /// 같은 녹음을 다시 누르면 정지, 다른 녹음이면 그쪽으로 전환한다.
  Future<void> toggle(String attemptId) async {
    if (_playingId == attemptId) {
      await stop();
      return;
    }
    await _player.stop();
    _playingId = null;
    _loadingId = attemptId;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();

    final String? dataUrl = _cache[attemptId] ??
        await RecordingStorage.instance.loadAudio(attemptId);
    if (dataUrl == null) {
      debugPrint('재생할 오디오를 찾지 못했습니다: $attemptId');
      _loadingId = null;
      notifyListeners();
      return;
    }
    _cache[attemptId] = dataUrl;

    try {
      await _player.play(UrlSource(dataUrl));
      _loadingId = null;
      _playingId = attemptId;
      notifyListeners();
    } on Object catch (e) {
      debugPrint('재생 실패: $e');
      _loadingId = null;
      _playingId = null;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _playingId = null;
    _loadingId = null;
    _position = Duration.zero;
    notifyListeners();
  }

  void forget(String attemptId) => _cache.remove(attemptId);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
