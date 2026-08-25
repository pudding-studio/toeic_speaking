import 'package:flutter/foundation.dart';

import '../data/exam_sets.dart';
import '../models/exam_set.dart';
import '../models/question.dart';
import '../models/toeic_part.dart';
import 'local_storage.dart';
import 'question_store.dart';

/// 기본 회차([kExamSets])와 앱에서 만든 회차를 합쳐서 관리한다.
///
/// 만든 회차는 이 브라우저의 IndexedDB 에만 저장된다.
class ExamSetStore extends ChangeNotifier {
  ExamSetStore._();

  static final ExamSetStore instance = ExamSetStore._();

  final List<ExamSet> _custom = <ExamSet>[];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// 회차를 저장할 수 있는지(시크릿 모드 등에서는 false).
  bool get isPersistent => LocalStorage.instance.isAvailable;

  List<ExamSet> get customSets => List<ExamSet>.unmodifiable(_custom);

  /// 기본 회차 + 만든 회차. 만든 회차가 뒤에 온다.
  List<ExamSet> get all => <ExamSet>[...kExamSets, ..._custom];

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final List<String> raw = await LocalStorage.instance.loadExamSetJson();
    _custom
      ..clear()
      ..addAll(raw.map(ExamSet.fromJson).whereType<ExamSet>());
    _sort();
    notifyListeners();
  }

  ExamSet? byId(String id) {
    for (final ExamSet s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// 새 회차에 쓸 id. 기본 회차 id 와 겹치지 않도록 접두사를 붙인다.
  String newId() => 'custom_set_${DateTime.now().millisecondsSinceEpoch}';

  /// 회차를 지금 등록된 문항으로 펼친 진행표로 바꾼다.
  ExamPlan planOf(ExamSet set) =>
      ExamPlan.build(set, (String id) => QuestionStore.instance.byId(id));

  /// 회차를 저장한다. 이미 있는 id 면 덮어쓴다.
  /// 저장에 실패하면 false 를 돌려주고 목록도 바꾸지 않는다.
  Future<bool> save(ExamSet set) async {
    final bool ok = await LocalStorage.instance.saveExamSet(
      id: set.id,
      examSetJson: set.toJson(),
    );
    if (!ok) return false;

    final int index = _custom.indexWhere((ExamSet s) => s.id == set.id);
    if (index >= 0) {
      _custom[index] = set;
    } else {
      _custom.add(set);
    }
    _sort();
    notifyListeners();
    return true;
  }

  Future<void> remove(ExamSet set) async {
    _custom.removeWhere((ExamSet s) => s.id == set.id);
    notifyListeners();
    await LocalStorage.instance.deleteExamSet(set.id);
  }

  /// 회차를 짤 때 고를 수 있는 문항. 파트별로 묶어 돌려준다.
  Map<PartId, List<Question>> questionsByPart() {
    final Map<PartId, List<Question>> result = <PartId, List<Question>>{};
    for (final Question q in QuestionStore.instance.all) {
      result.putIfAbsent(q.partId, () => <Question>[]).add(q);
    }
    return result;
  }

  void _sort() => _custom.sort((ExamSet a, ExamSet b) => a.id.compareTo(b.id));
}
