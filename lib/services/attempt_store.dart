import 'package:flutter/foundation.dart';

import '../models/attempt.dart';
import '../models/toeic_part.dart';
import 'local_storage.dart';

/// 녹음 기록 목록을 들고 있는 저장소.
/// 메타데이터는 메모리에, 오디오는 IndexedDB 에 둔다.
class AttemptStore extends ChangeNotifier {
  AttemptStore._();

  static final AttemptStore instance = AttemptStore._();

  final List<Attempt> _attempts = <Attempt>[];
  bool _loaded = false;

  List<Attempt> get attempts => List<Attempt>.unmodifiable(_attempts);
  bool get isLoaded => _loaded;

  /// IndexedDB 를 못 쓰는 브라우저(시크릿 모드 등)에서는 새로고침 시 기록이 사라진다.
  bool get isPersistent => LocalStorage.instance.isAvailable;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final List<String> raw = await LocalStorage.instance.loadAttemptJson();
    _attempts
      ..clear()
      ..addAll(raw.map(Attempt.fromJson).whereType<Attempt>());
    _sort();
    notifyListeners();
  }

  Future<void> add(Attempt attempt, String audioDataUrl) async {
    _attempts.insert(0, attempt);
    _sort();
    notifyListeners();
    await LocalStorage.instance.saveAttempt(
      id: attempt.id,
      attemptJson: attempt.toJson(),
      audioDataUrl: audioDataUrl,
    );
  }

  Future<void> remove(Attempt attempt) async {
    _attempts.removeWhere((Attempt a) => a.id == attempt.id);
    notifyListeners();
    await LocalStorage.instance.delete(attempt.id);
  }

  Future<void> clearAll() async {
    _attempts.clear();
    notifyListeners();
    await LocalStorage.instance.clear();
  }

  List<Attempt> ofQuestion(String questionId) => _attempts
      .where((Attempt a) => a.questionId == questionId)
      .toList(growable: false);

  List<Attempt> ofPart(PartId partId) => _attempts
      .where((Attempt a) => a.partId == partId)
      .toList(growable: false);

  int countOfPart(PartId partId) =>
      _attempts.where((Attempt a) => a.partId == partId).length;

  /// 연습한 날짜(중복 제거) 개수 — 홈 화면 통계용.
  int get practicedDayCount => _attempts
      .map((Attempt a) => DateTime(
            a.createdAt.year,
            a.createdAt.month,
            a.createdAt.day,
          ))
      .toSet()
      .length;

  Duration get totalDuration => Duration(
        seconds: _attempts.fold<int>(
          0,
          (int sum, Attempt a) => sum + a.durationSeconds,
        ),
      );

  void _sort() => _attempts
      .sort((Attempt a, Attempt b) => b.createdAt.compareTo(a.createdAt));
}
