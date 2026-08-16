import 'package:flutter/foundation.dart';

import '../data/question_bank.dart';
import '../models/question.dart';
import '../models/toeic_part.dart';
import 'local_storage.dart';
import 'question_transfer.dart';

/// 기본 제공 문항([kQuestions])과 앱에서 등록한 문항을 합쳐서 관리한다.
///
/// 등록한 문항은 이 브라우저의 IndexedDB 에만 저장된다.
class QuestionStore extends ChangeNotifier {
  QuestionStore._();

  static final QuestionStore instance = QuestionStore._();

  final List<Question> _custom = <Question>[];

  /// 사진 바이트 캐시. 화면을 다시 그릴 때마다 저장소를 읽지 않도록 들고 있는다.
  final Map<String, Uint8List?> _imageCache = <String, Uint8List?>{};

  /// 예시 음성 바이트 캐시.
  final Map<String, Uint8List?> _audioCache = <String, Uint8List?>{};

  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// 등록한 문항을 저장할 수 있는지(시크릿 모드 등에서는 false).
  bool get isPersistent => LocalStorage.instance.isAvailable;

  List<Question> get customQuestions => List<Question>.unmodifiable(_custom);

  /// 기본 문항 + 등록한 문항. 등록한 문항이 뒤에 온다.
  List<Question> get all => <Question>[...kQuestions, ..._custom];

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final List<String> raw = await LocalStorage.instance.loadQuestionJson();
    _custom
      ..clear()
      ..addAll(raw.map(Question.fromJson).whereType<Question>());
    _sort();
    notifyListeners();
  }

  List<Question> ofPart(PartId partId) =>
      all.where((Question q) => q.partId == partId).toList(growable: false);

  Question? byId(String id) {
    for (final Question q in all) {
      if (q.id == id) return q;
    }
    return null;
  }

  /// 새 문항에 쓸 id 를 만든다. 기본 문항 id 와 겹치지 않도록 접두사를 붙인다.
  String newId(PartId partId) =>
      'custom_${partId.name}_${DateTime.now().millisecondsSinceEpoch}';

  /// 문항을 저장한다. 이미 있는 id 면 덮어쓴다.
  /// 저장에 실패하면 false 를 돌려주고 목록도 바꾸지 않는다.
  Future<bool> save(
    Question question, {
    Uint8List? imageBytes,
    Uint8List? audioBytes,
    bool removeAudio = false,
  }) async {
    final bool ok = await LocalStorage.instance.saveQuestion(
      id: question.id,
      questionJson: question.toJson(),
      imageBytes: imageBytes,
      audioBytes: audioBytes,
      removeAudio: removeAudio,
    );
    if (!ok) return false;

    final int index = _custom.indexWhere((Question q) => q.id == question.id);
    if (index >= 0) {
      _custom[index] = question;
    } else {
      _custom.add(question);
    }
    if (imageBytes != null) _imageCache[question.id] = imageBytes;
    if (audioBytes != null) {
      _audioCache[question.id] = audioBytes;
    } else if (removeAudio) {
      _audioCache.remove(question.id);
    }
    _sort();
    notifyListeners();
    return true;
  }

  Future<void> remove(Question question) async {
    _custom.removeWhere((Question q) => q.id == question.id);
    _imageCache.remove(question.id);
    _audioCache.remove(question.id);
    notifyListeners();
    await LocalStorage.instance.deleteQuestion(question.id);
  }

  /// 등록한 문항의 사진. 없으면 null.
  Future<Uint8List?> imageOf(String questionId) async {
    if (_imageCache.containsKey(questionId)) return _imageCache[questionId];
    final Uint8List? bytes =
        await LocalStorage.instance.loadQuestionImage(questionId);
    _imageCache[questionId] = bytes;
    return bytes;
  }

  /// 문항에 붙여 둔 예시 음성. 없으면 null.
  Future<Uint8List?> audioOf(String questionId) async {
    if (_audioCache.containsKey(questionId)) return _audioCache[questionId];
    final Uint8List? bytes =
        await LocalStorage.instance.loadQuestionAudio(questionId);
    _audioCache[questionId] = bytes;
    return bytes;
  }

  /// 등록한 문항을 사진·예시 음성까지 묶어서 내보낼 형태로 모은다.
  Future<List<QuestionBundle>> exportBundles() async {
    final List<QuestionBundle> bundles = <QuestionBundle>[];
    for (final Question q in _custom) {
      bundles.add(
        QuestionBundle(
          question: q,
          image: await imageOf(q.id),
          audio: q.hasSampleAudio ? await audioOf(q.id) : null,
        ),
      );
    }
    return bundles;
  }

  /// 가져온 문항을 저장한다. 같은 id 가 있으면 덮어쓴다.
  /// 돌려주는 값은 (새로 추가한 수, 덮어쓴 수, 저장하지 못한 수).
  Future<({int added, int replaced, int failed})> importBundles(
    List<QuestionBundle> bundles,
  ) async {
    int added = 0;
    int replaced = 0;
    int failed = 0;

    for (final QuestionBundle bundle in bundles) {
      final bool exists =
          _custom.any((Question q) => q.id == bundle.question.id);
      final bool ok = await save(
        bundle.question,
        imageBytes: bundle.image,
        audioBytes: bundle.audio,
      );
      if (!ok) {
        failed++;
      } else if (exists) {
        replaced++;
      } else {
        added++;
      }
    }
    return (added: added, replaced: replaced, failed: failed);
  }

  void _sort() => _custom.sort((Question a, Question b) {
        final int byPart = a.partId.index.compareTo(b.partId.index);
        return byPart != 0 ? byPart : a.id.compareTo(b.id);
      });
}
