import 'package:flutter/material.dart';

import '../models/exam_set.dart';
import '../models/question.dart';
import '../models/toeic_part.dart';
import '../services/exam_set_store.dart';
import '../services/question_store.dart';
import '../theme.dart';
import '../widgets/question_content.dart';

/// 한 회차에 들어가는 자리. 실제 시험 구성과 같다.
/// 낭독 2 + 사진 묘사 2 + 듣고 답하기 1 + 정보 활용 1 + 의견 1 = 문항 7개(=11문항).
class _Slot {
  const _Slot({required this.partId, required this.label});

  final PartId partId;

  /// 예) "Q1", "Q5-7"
  final String label;
}

const List<_Slot> _kSlots = <_Slot>[
  _Slot(partId: PartId.readAloud, label: 'Q1'),
  _Slot(partId: PartId.readAloud, label: 'Q2'),
  _Slot(partId: PartId.describePicture, label: 'Q3'),
  _Slot(partId: PartId.describePicture, label: 'Q4'),
  _Slot(partId: PartId.respondQuestions, label: 'Q5-7'),
  _Slot(partId: PartId.respondWithInfo, label: 'Q8-10'),
  _Slot(partId: PartId.expressOpinion, label: 'Q11'),
];

/// 나만의 모의고사 회차를 만드는 화면.
/// 자리마다 문항을 골라 넣으면 실제 시험 순서대로 회차가 만들어진다.
class ExamSetEditorScreen extends StatefulWidget {
  const ExamSetEditorScreen({super.key, this.existing});

  /// 고칠 회차. null 이면 새로 만든다.
  final ExamSet? existing;

  @override
  State<ExamSetEditorScreen> createState() => _ExamSetEditorScreenState();
}

class _ExamSetEditorScreenState extends State<ExamSetEditorScreen> {
  final TextEditingController _title = TextEditingController();

  /// 자리별로 고른 문항 id. 비워 두면 null.
  late final List<String?> _picked;

  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _title.text = widget.existing?.title ?? _defaultTitle();
    _picked = _slotsFrom(widget.existing);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String _defaultTitle() {
    final int count = ExamSetStore.instance.customSets.length + 1;
    return '나만의 모의고사 $count회';
  }

  /// 저장돼 있던 문항 id 목록을 자리별로 나눠 담는다.
  /// 파트가 맞는 자리에 앞에서부터 채운다.
  static List<String?> _slotsFrom(ExamSet? set) {
    final List<String?> result =
        List<String?>.filled(_kSlots.length, null, growable: false);
    if (set == null) return result;

    for (final String id in set.questionIds) {
      final Question? question = QuestionStore.instance.byId(id);
      if (question == null) continue;
      for (int i = 0; i < _kSlots.length; i++) {
        if (result[i] == null && _kSlots[i].partId == question.partId) {
          result[i] = id;
          break;
        }
      }
    }
    return result;
  }

  int get _filledCount => _picked.whereType<String>().length;

  /// 지금 고른 문항으로 만들어질 답변 단계 수(11이면 실제 시험과 같다).
  int get _stepCount {
    int total = 0;
    for (final String? id in _picked) {
      if (id == null) continue;
      final Question? q = QuestionStore.instance.byId(id);
      if (q != null) total += q.steps.length;
    }
    return total;
  }

  Future<void> _save() async {
    final String title = _title.text.trim();
    if (title.isEmpty) {
      _toast('회차 이름을 입력해 주세요.');
      return;
    }
    final List<String> ids = _picked.whereType<String>().toList();
    if (ids.isEmpty) {
      _toast('문항을 하나 이상 골라 주세요.');
      return;
    }

    setState(() => _saving = true);
    final ExamSet set = ExamSet(
      id: widget.existing?.id ?? ExamSetStore.instance.newId(),
      title: title,
      subtitle: _subtitleOf(ids),
      questionIds: ids,
      isCustom: true,
    );
    final bool ok = await ExamSetStore.instance.save(set);
    if (!mounted) return;
    setState(() => _saving = false);

    if (!ok) {
      _toast('회차를 저장하지 못했습니다. 브라우저 저장소를 쓸 수 없는 상태일 수 있습니다.');
      return;
    }
    Navigator.of(context).pop(true);
  }

  /// 목록에서 보여 줄 한 줄 설명을 문항 제목으로 만든다.
  static String _subtitleOf(List<String> ids) {
    final List<String> titles = <String>[];
    for (final String id in ids) {
      final Question? q = QuestionStore.instance.byId(id);
      if (q != null) titles.add(q.title);
    }
    return titles.join(' · ');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '회차 고치기' : '회차 만들기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: '회차 이름',
              hintText: '예) 나만의 모의고사 1회',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 18),
          Text(
            '실제 시험과 같은 순서로 자리마다 문항을 고릅니다. '
            'Q5-7 과 Q8-10 은 문항 하나가 질문 3개를 담고 있어 자리도 하나입니다.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < _kSlots.length; i++)
            _SlotPicker(
              slot: _kSlots[i],
              selectedId: _picked[i],
              // 같은 파트의 다른 자리에서 이미 고른 문항은 빼고 보여 준다.
              excludedIds: <String>{
                for (int j = 0; j < _picked.length; j++)
                  if (j != i && _picked[j] != null) _picked[j]!,
              },
              onChanged: (String? id) => setState(() => _picked[i] = id),
            ),
          const SizedBox(height: 8),
          _summary(scheme),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_saving ? '저장 중' : '회차 저장'),
          ),
        ],
      ),
    );
  }

  Widget _summary(ColorScheme scheme) {
    final bool full = _stepCount == 11;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: (full ? AppTheme.seed : scheme.outline).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            full ? Icons.check_circle_outline : Icons.info_outline,
            size: 18,
            color: full ? AppTheme.seed : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              full
                  ? '문항 $_filledCount개 · 11문항으로 실제 시험과 같은 구성입니다.'
                  : '문항 $_filledCount개 · 답변 $_stepCount문항 '
                      '(실제 시험은 11문항입니다).',
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// 자리 하나에 들어갈 문항을 고르는 카드.
class _SlotPicker extends StatelessWidget {
  const _SlotPicker({
    required this.slot,
    required this.selectedId,
    required this.excludedIds,
    required this.onChanged,
  });

  final _Slot slot;
  final String? selectedId;

  /// 다른 자리에서 이미 고른 문항.
  final Set<String> excludedIds;

  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = AppTheme.partColor(slot.partId);
    final List<Question> options = QuestionStore.instance
        .ofPart(slot.partId)
        .where(
            (Question q) => q.id == selectedId || !excludedIds.contains(q.id))
        .toList();

    return SectionCard(
      title: '${slot.label} · ${partById(slot.partId).shortTitle}',
      color: color,
      child: options.isEmpty
          ? Text(
              '이 파트에 고를 문항이 없습니다. 파트 탭에서 문항을 먼저 등록해 주세요.',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            )
          : DropdownButtonFormField<String?>(
              initialValue: selectedId,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              hint: const Text('비워 둠'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  child: Text('비워 둠'),
                ),
                for (final Question q in options)
                  DropdownMenuItem<String?>(
                    value: q.id,
                    child: Text(
                      q.isCustom ? '${q.title} (직접 등록)' : q.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
    );
  }
}
