import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_browser.dart';

/// 브라우저 IndexedDB 에 이 기기의 데이터를 저장한다.
///
/// - `attempts`: 녹음 메타데이터(JSON 문자열)
/// - `audio`: 녹음 오디오(base64 data URL 문자열)
/// - `questions`: 앱에서 등록한 문항(JSON 문자열)
/// - `questionImages`: 등록한 문항의 사진(바이트)
/// - `examSets`: 직접 만든 모의고사 회차(JSON 문자열)
///
/// 오디오와 사진은 용량이 크므로 목록을 그릴 때는 읽지 않고 필요할 때만 꺼낸다.
/// 시크릿 모드 등으로 IndexedDB 를 쓸 수 없으면 [isAvailable] 이 false 가 되고
/// 모든 메서드가 조용히 아무 것도 하지 않는다(그 세션 동안은 메모리에만 남는다).
class LocalStorage {
  LocalStorage._();

  static final LocalStorage instance = LocalStorage._();

  static const String _dbName = 'toeic_speaking';

  /// v5 에서 모의고사 회차 스토어를 추가했다. 기존 데이터는 그대로 유지된다.
  static const int _dbVersion = 5;
  static const String _attemptStore = 'attempts';
  static const String _audioStore = 'audio';
  static const String _questionStore = 'questions';
  static const String _questionImageStore = 'questionImages';
  static const String _settingsStore = 'settings';
  static const String _ttsCacheStore = 'ttsCache';
  static const String _questionAudioStore = 'questionAudio';
  static const String _examSetStore = 'examSets';

  Database? _db;
  Future<Database?>? _opening;
  bool _unavailable = false;

  /// IndexedDB 를 쓸 수 있는지. [open] 을 한 번 시도한 뒤에 의미가 있다.
  bool get isAvailable => !_unavailable;

  Future<Database?> open() {
    if (_db != null) return Future<Database?>.value(_db);
    if (_unavailable) return Future<Database?>.value();
    return _opening ??= _openInternal();
  }

  Future<Database?> _openInternal() async {
    try {
      final IdbFactory? factory = getIdbFactory();
      if (factory == null) {
        _unavailable = true;
        return null;
      }
      _db = await factory.open(
        _dbName,
        version: _dbVersion,
        onUpgradeNeeded: (VersionChangeEvent event) {
          final Database db = event.database;
          if (!db.objectStoreNames.contains(_attemptStore)) {
            db.createObjectStore(_attemptStore);
          }
          if (!db.objectStoreNames.contains(_audioStore)) {
            db.createObjectStore(_audioStore);
          }
          if (!db.objectStoreNames.contains(_questionStore)) {
            db.createObjectStore(_questionStore);
          }
          if (!db.objectStoreNames.contains(_questionImageStore)) {
            db.createObjectStore(_questionImageStore);
          }
          if (!db.objectStoreNames.contains(_settingsStore)) {
            db.createObjectStore(_settingsStore);
          }
          if (!db.objectStoreNames.contains(_ttsCacheStore)) {
            db.createObjectStore(_ttsCacheStore);
          }
          if (!db.objectStoreNames.contains(_questionAudioStore)) {
            db.createObjectStore(_questionAudioStore);
          }
          if (!db.objectStoreNames.contains(_examSetStore)) {
            db.createObjectStore(_examSetStore);
          }
        },
      );
      return _db;
    } on Object catch (e) {
      debugPrint('IndexedDB 를 열 수 없습니다: $e');
      _unavailable = true;
      return null;
    } finally {
      _opening = null;
    }
  }

  /// 저장된 메타데이터를 모두 읽어 온다(정렬은 호출한 쪽에서).
  Future<List<String>> loadAttemptJson() async {
    final Database? db = await open();
    if (db == null) return const <String>[];
    try {
      final Transaction txn = db.transaction(_attemptStore, idbModeReadOnly);
      final List<String> result = <String>[];
      await txn
          .objectStore(_attemptStore)
          .openCursor(autoAdvance: true)
          .forEach((CursorWithValue cursor) {
        final Object value = cursor.value;
        if (value is String) result.add(value);
      });
      await txn.completed;
      return result;
    } on Object catch (e) {
      debugPrint('녹음 목록을 읽지 못했습니다: $e');
      return const <String>[];
    }
  }

  Future<void> saveAttempt({
    required String id,
    required String attemptJson,
    required String audioDataUrl,
  }) async {
    final Database? db = await open();
    if (db == null) return;
    try {
      final Transaction txn = db.transactionList(
        <String>[_attemptStore, _audioStore],
        idbModeReadWrite,
      );
      await txn.objectStore(_attemptStore).put(attemptJson, id);
      await txn.objectStore(_audioStore).put(audioDataUrl, id);
      await txn.completed;
    } on Object catch (e) {
      debugPrint('녹음을 저장하지 못했습니다: $e');
    }
  }

  /// 재생용 오디오(data URL)를 꺼낸다. 없으면 null.
  Future<String?> loadAudio(String id) async {
    final Database? db = await open();
    if (db == null) return null;
    try {
      final Transaction txn = db.transaction(_audioStore, idbModeReadOnly);
      final Object? value = await txn.objectStore(_audioStore).getObject(id);
      await txn.completed;
      return value is String ? value : null;
    } on Object catch (e) {
      debugPrint('녹음을 읽지 못했습니다: $e');
      return null;
    }
  }

  Future<void> delete(String id) async {
    final Database? db = await open();
    if (db == null) return;
    try {
      final Transaction txn = db.transactionList(
        <String>[_attemptStore, _audioStore],
        idbModeReadWrite,
      );
      await txn.objectStore(_attemptStore).delete(id);
      await txn.objectStore(_audioStore).delete(id);
      await txn.completed;
    } on Object catch (e) {
      debugPrint('녹음을 삭제하지 못했습니다: $e');
    }
  }

  // ─────────────────────── 앱에서 등록한 문항 ───────────────────────

  /// 저장된 문항 JSON 을 모두 읽어 온다.
  Future<List<String>> loadQuestionJson() async {
    final Database? db = await open();
    if (db == null) return const <String>[];
    try {
      final Transaction txn = db.transaction(_questionStore, idbModeReadOnly);
      final List<String> result = <String>[];
      await txn
          .objectStore(_questionStore)
          .openCursor(autoAdvance: true)
          .forEach((CursorWithValue cursor) {
        final Object value = cursor.value;
        if (value is String) result.add(value);
      });
      await txn.completed;
      return result;
    } on Object catch (e) {
      debugPrint('문항 목록을 읽지 못했습니다: $e');
      return const <String>[];
    }
  }

  /// 문항을 저장한다.
  /// [imageBytes] / [audioBytes] 가 null 이면 기존 것을 그대로 둔다.
  /// [removeAudio] 가 true 면 저장돼 있던 예시 음성을 지운다.
  Future<bool> saveQuestion({
    required String id,
    required String questionJson,
    Uint8List? imageBytes,
    Uint8List? audioBytes,
    bool removeAudio = false,
  }) async {
    final Database? db = await open();
    if (db == null) return false;
    try {
      final Transaction txn = db.transactionList(
        <String>[_questionStore, _questionImageStore, _questionAudioStore],
        idbModeReadWrite,
      );
      await txn.objectStore(_questionStore).put(questionJson, id);
      if (imageBytes != null) {
        await txn.objectStore(_questionImageStore).put(imageBytes, id);
      }
      if (audioBytes != null) {
        await txn.objectStore(_questionAudioStore).put(audioBytes, id);
      } else if (removeAudio) {
        await txn.objectStore(_questionAudioStore).delete(id);
      }
      await txn.completed;
      return true;
    } on Object catch (e) {
      debugPrint('문항을 저장하지 못했습니다: $e');
      return false;
    }
  }

  /// 문항에 붙여 둔 예시 음성. 없으면 null.
  Future<Uint8List?> loadQuestionAudio(String id) async {
    final Database? db = await open();
    if (db == null) return null;
    try {
      final Transaction txn =
          db.transaction(_questionAudioStore, idbModeReadOnly);
      final Object? value =
          await txn.objectStore(_questionAudioStore).getObject(id);
      await txn.completed;
      return _asBytes(value);
    } on Object catch (e) {
      debugPrint('예시 음성을 읽지 못했습니다: $e');
      return null;
    }
  }

  /// 문항 사진 바이트를 꺼낸다. 없으면 null.
  Future<Uint8List?> loadQuestionImage(String id) async {
    final Database? db = await open();
    if (db == null) return null;
    try {
      final Transaction txn =
          db.transaction(_questionImageStore, idbModeReadOnly);
      final Object? value =
          await txn.objectStore(_questionImageStore).getObject(id);
      await txn.completed;
      return _asBytes(value);
    } on Object catch (e) {
      debugPrint('문항 사진을 읽지 못했습니다: $e');
      return null;
    }
  }

  Future<void> deleteQuestion(String id) async {
    final Database? db = await open();
    if (db == null) return;
    try {
      final Transaction txn = db.transactionList(
        <String>[_questionStore, _questionImageStore, _questionAudioStore],
        idbModeReadWrite,
      );
      await txn.objectStore(_questionStore).delete(id);
      await txn.objectStore(_questionImageStore).delete(id);
      await txn.objectStore(_questionAudioStore).delete(id);
      await txn.completed;
    } on Object catch (e) {
      debugPrint('문항을 삭제하지 못했습니다: $e');
    }
  }

  /// IndexedDB 가 돌려주는 값을 바이트로 통일한다.
  /// 브라우저 구현에 따라 Uint8List / ByteBuffer / List<int> 로 올 수 있다.
  static Uint8List? _asBytes(Object? value) {
    if (value is Uint8List) return value;
    if (value is ByteBuffer) return value.asUint8List();
    if (value is List<int>) return Uint8List.fromList(value);
    return null;
  }

  // ─────────────────────── 직접 만든 모의고사 회차 ───────────────────────

  Future<List<String>> loadExamSetJson() async {
    final Database? db = await open();
    if (db == null) return const <String>[];
    try {
      final Transaction txn = db.transaction(_examSetStore, idbModeReadOnly);
      final List<String> result = <String>[];
      await txn
          .objectStore(_examSetStore)
          .openCursor(autoAdvance: true)
          .forEach((CursorWithValue cursor) {
        final Object value = cursor.value;
        if (value is String) result.add(value);
      });
      await txn.completed;
      return result;
    } on Object catch (e) {
      debugPrint('회차 목록을 읽지 못했습니다: $e');
      return const <String>[];
    }
  }

  /// 회차를 저장한다. 이미 있는 id 면 덮어쓴다.
  Future<bool> saveExamSet({
    required String id,
    required String examSetJson,
  }) async {
    final Database? db = await open();
    if (db == null) return false;
    try {
      final Transaction txn = db.transaction(_examSetStore, idbModeReadWrite);
      await txn.objectStore(_examSetStore).put(examSetJson, id);
      await txn.completed;
      return true;
    } on Object catch (e) {
      debugPrint('회차를 저장하지 못했습니다: $e');
      return false;
    }
  }

  Future<void> deleteExamSet(String id) async {
    final Database? db = await open();
    if (db == null) return;
    try {
      final Transaction txn = db.transaction(_examSetStore, idbModeReadWrite);
      await txn.objectStore(_examSetStore).delete(id);
      await txn.completed;
    } on Object catch (e) {
      debugPrint('회차를 삭제하지 못했습니다: $e');
    }
  }

  // ─────────────────────────── 설정 ───────────────────────────

  Future<String?> loadSetting(String key) async {
    final Database? db = await open();
    if (db == null) return null;
    try {
      final Transaction txn = db.transaction(_settingsStore, idbModeReadOnly);
      final Object? value =
          await txn.objectStore(_settingsStore).getObject(key);
      await txn.completed;
      return value is String ? value : null;
    } on Object catch (e) {
      debugPrint('설정을 읽지 못했습니다: $e');
      return null;
    }
  }

  Future<void> saveSetting(String key, String? value) async {
    final Database? db = await open();
    if (db == null) return;
    try {
      final Transaction txn = db.transaction(_settingsStore, idbModeReadWrite);
      if (value == null) {
        await txn.objectStore(_settingsStore).delete(key);
      } else {
        await txn.objectStore(_settingsStore).put(value, key);
      }
      await txn.completed;
    } on Object catch (e) {
      debugPrint('설정을 저장하지 못했습니다: $e');
    }
  }

  // ─────────────────────── 읽어주기 음성 캐시 ───────────────────────

  /// 이미 만들어 둔 음성. 있으면 API 를 다시 부르지 않는다.
  Future<Uint8List?> loadTtsAudio(String key) async {
    final Database? db = await open();
    if (db == null) return null;
    try {
      final Transaction txn = db.transaction(_ttsCacheStore, idbModeReadOnly);
      final Object? value =
          await txn.objectStore(_ttsCacheStore).getObject(key);
      await txn.completed;
      return _asBytes(value);
    } on Object catch (e) {
      debugPrint('음성 캐시를 읽지 못했습니다: $e');
      return null;
    }
  }

  Future<void> saveTtsAudio(String key, Uint8List bytes) async {
    final Database? db = await open();
    if (db == null) return;
    try {
      final Transaction txn = db.transaction(_ttsCacheStore, idbModeReadWrite);
      await txn.objectStore(_ttsCacheStore).put(bytes, key);
      await txn.completed;
    } on Object catch (e) {
      debugPrint('음성 캐시를 저장하지 못했습니다: $e');
    }
  }

  /// 캐시에 들어 있는 음성 개수.
  Future<int> ttsCacheCount() async {
    final Database? db = await open();
    if (db == null) return 0;
    try {
      final Transaction txn = db.transaction(_ttsCacheStore, idbModeReadOnly);
      final int count = await txn.objectStore(_ttsCacheStore).count();
      await txn.completed;
      return count;
    } on Object catch (e) {
      debugPrint('음성 캐시 개수를 세지 못했습니다: $e');
      return 0;
    }
  }

  Future<void> clearTtsCache() async {
    final Database? db = await open();
    if (db == null) return;
    try {
      final Transaction txn = db.transaction(_ttsCacheStore, idbModeReadWrite);
      await txn.objectStore(_ttsCacheStore).clear();
      await txn.completed;
    } on Object catch (e) {
      debugPrint('음성 캐시를 비우지 못했습니다: $e');
    }
  }

  Future<void> clear() async {
    final Database? db = await open();
    if (db == null) return;
    try {
      final Transaction txn = db.transactionList(
        <String>[_attemptStore, _audioStore],
        idbModeReadWrite,
      );
      await txn.objectStore(_attemptStore).clear();
      await txn.objectStore(_audioStore).clear();
      await txn.completed;
    } on Object catch (e) {
      debugPrint('녹음을 비우지 못했습니다: $e');
    }
  }
}
