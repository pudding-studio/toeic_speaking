import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attempt.dart';
import '../models/toeic_part.dart';

/// 녹음 기록을 SharedPreferences 에 JSON 배열로 저장한다.
/// 최신 기록이 항상 앞에 오도록 유지한다.
class AttemptStore extends ChangeNotifier {
  AttemptStore._();

  static final AttemptStore instance = AttemptStore._();

  static const String _key = 'attempts_v1';

  final List<Attempt> _attempts = <Attempt>[];
  bool _loaded = false;

  List<Attempt> get attempts => List<Attempt>.unmodifiable(_attempts);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_key) ?? const <String>[];
    _attempts
      ..clear()
      ..addAll(
        raw.map(Attempt.fromJson).whereType<Attempt>(),
      );
    _sort();
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(Attempt attempt) async {
    _attempts.insert(0, attempt);
    _sort();
    await _persist();
    notifyListeners();
  }

  /// 기록과 함께 실제 음성 파일도 삭제한다.
  Future<void> remove(Attempt attempt) async {
    _attempts.removeWhere((Attempt a) => a.id == attempt.id);
    await _persist();
    notifyListeners();
    try {
      final File file = File(attempt.filePath);
      if (file.existsSync()) await file.delete();
    } on FileSystemException catch (e) {
      debugPrint('녹음 파일 삭제 실패: $e');
    }
  }

  Future<void> clearAll() async {
    final List<Attempt> copy = List<Attempt>.of(_attempts);
    _attempts.clear();
    await _persist();
    notifyListeners();
    for (final Attempt a in copy) {
      try {
        final File file = File(a.filePath);
        if (file.existsSync()) await file.delete();
      } on FileSystemException catch (e) {
        debugPrint('녹음 파일 삭제 실패: $e');
      }
    }
  }

  List<Attempt> ofQuestion(String questionId) => _attempts
      .where((Attempt a) => a.questionId == questionId)
      .toList(growable: false);

  List<Attempt> ofPart(PartId partId) =>
      _attempts.where((Attempt a) => a.partId == partId).toList(growable: false);

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

  void _sort() =>
      _attempts.sort((Attempt a, Attempt b) => b.createdAt.compareTo(a.createdAt));

  Future<void> _persist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _attempts.map((Attempt a) => a.toJson()).toList(growable: false),
    );
  }
}
