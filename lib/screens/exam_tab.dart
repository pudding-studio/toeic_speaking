import 'package:flutter/material.dart';

import '../models/attempt.dart';
import '../models/exam_set.dart';
import '../services/attempt_store.dart';
import '../services/exam_set_store.dart';
import '../services/question_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'exam_screen.dart';
import 'exam_set_editor_screen.dart';

/// 실전 모의고사 탭. 회차를 골라 11문항을 한 번에 응시한다.
class ExamTab extends StatelessWidget {
  const ExamTab({super.key});

  Future<void> _openEditor(BuildContext context, {ExamSet? existing}) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            ExamSetEditorScreen(existing: existing),
      ),
    );
    if ((saved ?? false) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회차를 저장했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        ExamSetStore.instance,
        QuestionStore.instance,
        AttemptStore.instance,
      ]),
      builder: (BuildContext context, Widget? _) {
        final List<ExamSet> sets = ExamSetStore.instance.all;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            const _ExamHeader(),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Text(
                  '회차 ${sets.length}개',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openEditor(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('회차 만들기'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final ExamSet set in sets)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ExamSetCard(
                  set: set,
                  onEdit: set.isCustom
                      ? () => _openEditor(context, existing: set)
                      : null,
                ),
              ),
            if (!ExamSetStore.instance.isPersistent) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '이 브라우저에서는 만든 회차를 저장할 수 없습니다(시크릿 모드 등). '
                '새로고침하면 사라집니다.',
                style:
                    TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ExamHeader extends StatelessWidget {
  const _ExamHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF13324F), Color(0xFF2F5BEA)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '실전 모의고사',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Q1부터 Q11까지 실제 시험 순서와 시간 그대로 한 번에 응시합니다. '
            '준비·답변 시간이 저절로 넘어가고, 모범 답안은 끝난 뒤에 볼 수 있습니다.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamSetCard extends StatelessWidget {
  const _ExamSetCard({required this.set, this.onEdit});

  final ExamSet set;

  /// 직접 만든 회차만 고칠 수 있다.
  final VoidCallback? onEdit;

  Future<void> _start(BuildContext context, ExamPlan plan) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ExamScreen(plan: plan),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('회차를 삭제할까요?'),
        content: Text('"${set.title}" 을 목록에서 지웁니다. 문항 자체는 그대로 남습니다.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ExamSetStore.instance.remove(set);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ExamPlan plan = ExamSetStore.instance.planOf(set);
    final int attempts = AttemptStore.instance.attempts
        .where((Attempt a) => a.examSetId == set.id)
        .length;

    return AppCard(
      onTap: plan.isEmpty ? null : () => _start(context, plan),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    set.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (set.isCustom)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.seed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '직접 만듦',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.seed,
                      ),
                    ),
                  ),
                if (onEdit != null) ...<Widget>[
                  IconButton(
                    tooltip: '고치기',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    tooltip: '삭제',
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline, size: 19),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            if (set.subtitle.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                set.subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(Icons.assignment_outlined,
                    size: 15, color: scheme.outline),
                const SizedBox(width: 5),
                Text(
                  '${plan.steps.length}문항',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.schedule, size: 15, color: scheme.outline),
                const SizedBox(width: 5),
                Text(
                  '약 ${plan.totalDuration.inMinutes + 1}분',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (attempts > 0) ...<Widget>[
                  const SizedBox(width: 12),
                  Icon(Icons.mic_none, size: 15, color: scheme.outline),
                  const SizedBox(width: 5),
                  Text(
                    '녹음 $attempts개',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (!plan.isComplete) ...<Widget>[
              const SizedBox(height: 10),
              _SetWarning(plan: plan),
            ],
          ],
        ),
      ),
    );
  }
}

/// 회차가 11문항을 채우지 못했을 때의 안내.
class _SetWarning extends StatelessWidget {
  const _SetWarning({required this.plan});

  final ExamPlan plan;

  @override
  Widget build(BuildContext context) {
    const Color amber = Color(0xFFB26A00);
    final String message;
    if (plan.isEmpty) {
      message = '문항이 없어 응시할 수 없습니다. 회차를 고쳐 문항을 넣어 주세요.';
    } else if (plan.missingIds.isNotEmpty) {
      message = '문항 ${plan.missingIds.length}개를 찾지 못했습니다(삭제된 문항). '
          '${plan.steps.length}문항으로 응시합니다.';
    } else {
      message = '실제 시험은 11문항입니다. 지금은 ${plan.steps.length}문항으로 응시합니다.';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.info_outline, size: 16, color: amber),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 12, height: 1.45, color: amber),
          ),
        ),
      ],
    );
  }
}
