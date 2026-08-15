import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 녹음 재생 담당. 한 번에 하나의 파일만 재생한다.
class PlaybackService extends ChangeNotifier {
  PlaybackService._() {
    _player.onPlayerComplete.listen((void _) {
      _playingPath = null;
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

  String? _playingPath;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  String? get playingPath => _playingPath;
  Duration get position => _position;
  Duration get duration => _duration;

  bool isPlaying(String path) => _playingPath == path;

  /// 같은 파일을 다시 누르면 정지, 다른 파일이면 그쪽으로 전환한다.
  Future<void> toggle(String path) async {
    if (_playingPath == path) {
      await stop();
      return;
    }
    await _player.stop();
    _playingPath = path;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
    try {
      await _player.play(DeviceFileSource(path));
    } on Exception catch (e) {
      debugPrint('재생 실패: $e');
      _playingPath = null;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _playingPath = null;
    _position = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
