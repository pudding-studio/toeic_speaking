import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

/// 브라우저 마이크 녹음을 담당한다.
///
/// 웹에서는 `record` 가 MediaRecorder 로 녹음한 뒤 blob URL 을 돌려준다.
/// blob URL 은 새로고침하면 무효가 되므로, 녹음이 끝나면 바이트를 읽어
/// base64 data URL 로 바꿔 두고 그것을 저장/재생에 사용한다.
class RecorderService {
  RecorderService._();

  static final RecorderService instance = RecorderService._();

  /// 브라우저가 가장 널리 지원하는 조합(WebM/Opus).
  static const RecordConfig _config = RecordConfig(
    encoder: AudioEncoder.opus,
    bitRate: 64000,
    sampleRate: 44100,
    numChannels: 1,
  );

  final AudioRecorder _recorder = AudioRecorder();

  /// 마이크 사용 권한이 있는지(없으면 브라우저가 권한 창을 띄운다).
  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<bool> get isRecording => _recorder.isRecording();

  /// 녹음을 시작한다. 마이크를 쓸 수 없으면 false.
  Future<bool> start() async {
    try {
      if (!await _recorder.hasPermission()) return false;
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      // 웹에서는 경로를 쓰지 않는다(결과는 blob URL 로 돌아온다).
      await _recorder.start(_config, path: '');
      return true;
    } on Object catch (e) {
      debugPrint('녹음을 시작하지 못했습니다: $e');
      return false;
    }
  }

  /// 녹음을 멈추고 재생·저장에 쓸 data URL 을 돌려준다.
  /// 녹음된 소리가 없으면 null.
  Future<String?> stopAndRead() async {
    String? blobUrl;
    try {
      blobUrl = await _recorder.stop();
    } on Object catch (e) {
      debugPrint('녹음을 멈추지 못했습니다: $e');
      return null;
    }
    if (blobUrl == null || blobUrl.isEmpty) return null;

    try {
      final Uint8List bytes = await http.readBytes(Uri.parse(blobUrl));
      if (bytes.isEmpty) return null;
      return 'data:$_mimeType;base64,${base64Encode(bytes)}';
    } on Object catch (e) {
      debugPrint('녹음 데이터를 읽지 못했습니다: $e');
      return null;
    }
  }

  /// 저장하지 않고 취소한다.
  Future<void> cancel() async {
    try {
      await _recorder.stop();
    } on Object catch (e) {
      debugPrint('녹음을 취소하지 못했습니다: $e');
    }
  }

  static const String _mimeType = 'audio/webm';

  void dispose() => _recorder.dispose();
}
