import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// `record` 패키지를 감싼 얇은 래퍼.
/// 권한 확인 → 파일 경로 생성 → 녹음 시작/중지까지만 담당한다.
class RecorderService {
  RecorderService._();

  static final RecorderService instance = RecorderService._();

  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<bool> get isRecording => _recorder.isRecording();

  /// 녹음 파일이 저장되는 디렉터리. 없으면 만든다.
  Future<Directory> recordingsDirectory() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${base.path}/recordings');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 녹음을 시작한다. 마이크 권한이 없으면 false 를 돌려준다.
  Future<bool> start({required String questionId, required int stepIndex}) async {
    if (!await _recorder.hasPermission()) return false;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    final Directory dir = await recordingsDirectory();
    final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String path = '${dir.path}/${questionId}_${stepIndex}_$stamp.m4a';
    _currentPath = path;
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
    return true;
  }

  /// 녹음을 멈추고 저장된 파일 경로를 돌려준다. 파일이 비어 있으면 null.
  Future<String?> stop() async {
    final String? path = await _recorder.stop() ?? _currentPath;
    _currentPath = null;
    if (path == null) return null;
    final File file = File(path);
    if (!file.existsSync() || file.lengthSync() == 0) {
      if (file.existsSync()) {
        await file.delete();
      }
      return null;
    }
    return path;
  }

  /// 저장하지 않고 취소한다.
  Future<void> cancel() async {
    final String? path = await stop();
    if (path == null) return;
    final File file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Stream<Amplitude> amplitudeStream() =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 160));

  void dispose() => _recorder.dispose();
}
