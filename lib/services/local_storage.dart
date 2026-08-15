import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_browser.dart';

/// 브라우저 IndexedDB 에 이 기기의 데이터를 저장한다.
///
/// - `attempts`: 녹음 메타데이터(JSON 문자열)
/// - `audio`: 녹음 오디오(base64 data URL 문자열)
/// - `questions`: 앱에서 등록한 문항(JSON 문자열)
/// - `questionImages`: 등록한 문항의 사진(바이트)
///
/// 오디오와 사진은 용량이 크므로 목록을 그릴 때는 읽지 않고 필요할 때만 꺼낸다.
/// 시크릿 모드 등으로 IndexedDB 를 쓸 수 없으면 [isAvailable] 이 false 가 되고
/// 모든 메서드가 조용히 아무 것도 하지 않는다(그 세션 동안은 메모리에만 남는다).
class LocalStorage {
  LocalStorage._();

  static final LocalStorage instance = LocalStorage._();

  static const String _dbName = 'toeic_speaking';

  /// v2 에서 문항 스토어를 추가했다. 기존 녹음은 그대로 유지된다.
  static const int _dbVersion = 2;
  static const String _attemptStore = 'attempts';
  static const String _audioStore = 'audio';
  static const String _questionStore = 'questions';
  static const String _questionImageStore = 'questionImages';

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

  /// 문항을 저장한다. [imageBytes] 가 null 이면 기존 사진을 그대로 둔다.
  Future<bool> saveQuestion({
    required String id,
    required String questionJson,
    Uint8List? imageBytes,
  }) async {
    final Database? db = await open();
    if (db == null) return false;
    try {
      final Transaction txn = db.transactionList(
        <String>[_questionStore, _questionImageStore],
        idbModeReadWrite,
      );
      await txn.objectStore(_questionStore).put(questionJson, id);
      if (imageBytes != null) {
        await txn.objectStore(_questionImageStore).put(imageBytes, id);
      }
      await txn.completed;
      return true;
    } on Object catch (e) {
      debugPrint('문항을 저장하지 못했습니다: $e');
      return false;
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
        <String>[_questionStore, _questionImageStore],
        idbModeReadWrite,
      );
      await txn.objectStore(_questionStore).delete(id);
      await txn.objectStore(_questionImageStore).delete(id);
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
