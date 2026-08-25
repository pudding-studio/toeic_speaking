import 'package:flutter/foundation.dart';

import '../data/curricula.dart';
import '../models/curriculum.dart';
import 'local_storage.dart';

/// 지금 진행 중인 학습 계획과 그 진행 상태를 들고 있는다.
///
/// 계획 자체는 코드([kCurricula])에 있으므로, 저장하는 것은 어느 계획을 언제
/// 시작했고 무엇을 끝냈는지 뿐이다. 설정과 같은 스토어를 쓰기 때문에
/// 데이터베이스 버전을 올릴 필요가 없다.
class CurriculumStore extends ChangeNotifier {
  CurriculumStore._();

  static final CurriculumStore instance = CurriculumStore._();

  static const String _key = 'curriculumProgress';

  CurriculumProgress? _progress;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// 진행 중인 계획이 없으면 null.
  CurriculumProgress? get progress => _progress;

  /// 진행 중인 계획. 저장된 id 가 더 이상 없는 계획이면 null.
  Curriculum? get active {
    final String? id = _progress?.curriculumId;
    if (id == null) return null;
    return byId(id);
  }

  bool get hasActive => active != null;

  /// 진행 상태를 저장할 수 있는지(시크릿 모드 등에서는 false).
  bool get isPersistent => LocalStorage.instance.isAvailable;

  Curriculum? byId(String id) {
    for (final Curriculum c in kCurricula) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final String? raw = await LocalStorage.instance.loadSetting(_key);
    if (raw != null) _progress = CurriculumProgress.fromJson(raw);
    notifyListeners();
  }

  /// 계획을 시작한다. 다른 계획을 하고 있었다면 진행 상태는 버려진다.
  Future<void> start(Curriculum curriculum, {DateTime? now}) async {
    final DateTime today = now ?? DateTime.now();
    _progress = CurriculumProgress(
      curriculumId: curriculum.id,
      startedAt: DateTime(today.year, today.month, today.day),
    );
    notifyListeners();
    await _save();
  }

  /// 계획을 그만둔다.
  Future<void> stop() async {
    _progress = null;
    notifyListeners();
    await LocalStorage.instance.saveSetting(_key, null);
  }

  /// 할 일 하나를 끝냈다고 표시하거나 되돌린다.
  Future<void> toggleTask(String taskKey) async {
    final CurriculumProgress? current = _progress;
    if (current == null) return;
    _progress = current.toggle(taskKey);
    notifyListeners();
    await _save();
  }

  /// 오늘이 며칠째인지. 계획 마지막 날을 넘어가면 마지막 날로 붙잡아 둔다.
  int todayNumber({DateTime? now}) {
    final Curriculum? curriculum = active;
    final CurriculumProgress? current = _progress;
    if (curriculum == null || current == null) return 1;
    final int day = current.dayNumberOn(now ?? DateTime.now());
    if (day < 1) return 1;
    if (day > curriculum.totalDays) return curriculum.totalDays;
    return day;
  }

  /// 계획 마지막 날이 지났는지.
  bool isOverdue({DateTime? now}) {
    final Curriculum? curriculum = active;
    final CurriculumProgress? current = _progress;
    if (curriculum == null || current == null) return false;
    return current.dayNumberOn(now ?? DateTime.now()) > curriculum.totalDays;
  }

  /// 끝낸 할 일 수 / 전체 할 일 수.
  ({int done, int total}) counts() {
    final Curriculum? curriculum = active;
    final CurriculumProgress? current = _progress;
    if (curriculum == null || current == null) {
      return (done: 0, total: 0);
    }
    int done = 0;
    for (final CurriculumDay day in curriculum.days) {
      for (int i = 0; i < day.tasks.length; i++) {
        if (current.isDone(day.taskKey(i))) done++;
      }
    }
    return (done: done, total: curriculum.totalTasks);
  }

  Future<void> _save() async {
    final CurriculumProgress? current = _progress;
    if (current == null) return;
    await LocalStorage.instance.saveSetting(_key, current.toJson());
  }
}
