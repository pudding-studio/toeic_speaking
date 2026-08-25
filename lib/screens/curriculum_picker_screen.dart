import 'package:flutter/material.dart';

import '../data/curricula.dart';
import '../models/curriculum.dart';
import '../services/curriculum_store.dart';
import '../theme.dart';
import '../widgets/question_content.dart';

/// 학습 계획을 고르는 화면. 1주 / 2주 / 3주 / 한 달 중 하나를 시작한다.
class CurriculumPickerScreen extends StatelessWidget {
  const CurriculumPickerScreen({super.key, this.currentId});

  /// 지금 진행 중인 계획 id. 목록에서 표시해 준다.
  final String? currentId;

  Future<void> _start(BuildContext context, Curriculum curriculum) async {
    // 진행 중인 계획이 있으면 진행 상태가 사라진다는 것을 먼저 알려 준다.
    if (currentId != null) {
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('계획을 바꿀까요?'),
          content: Text(
            '"${curriculum.title}" 을 1일째부터 새로 시작합니다.\n'
            '지금까지 체크해 둔 진행 상태는 사라집니다(녹음은 그대로 남습니다).',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('새로 시작'),
            ),
          ],
        ),
      );
      if (!(ok ?? false)) return;
    }

    await CurriculumStore.instance.start(curriculum);
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('학습 계획 고르기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Text(
            '시험까지 남은 기간에 맞춰 고르세요. 하루 분량과 실전 응시 횟수가 다릅니다.\n'
            '중간에 언제든 다른 계획으로 바꿀 수 있습니다.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          for (final Curriculum c in kCurricula)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CurriculumCard(
                curriculum: c,
                isCurrent: c.id == currentId,
                onStart: () => _start(context, c),
              ),
            ),
        ],
      ),
    );
  }
}

class _CurriculumCard extends StatelessWidget {
  const _CurriculumCard({
    required this.curriculum,
    required this.isCurrent,
    required this.onStart,
  });

  final Curriculum curriculum;
  final bool isCurrent;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent
              ? AppTheme.seed.withValues(alpha: 0.55)
              : scheme.outlineVariant,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                curriculum.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              if (isCurrent)
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
                    '진행 중',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.seed,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            curriculum.subtitle,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _Stat(value: '${curriculum.totalDays}일', label: '기간'),
              _Stat(value: '${curriculum.averageMinutes}분', label: '하루 평균'),
              _Stat(value: '${curriculum.totalQuestions}문항', label: '전체 문항'),
              _Stat(value: '${curriculum.examCount}회', label: '실전'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.person_outline, size: 17, color: scheme.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    curriculum.forWhom,
                    style: const TextStyle(fontSize: 12.5, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showSchedule(context, curriculum),
                  child: const Text('일정 보기'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.seed,
                  ),
                  child: Text(isCurrent ? '1일째부터 다시 시작' : '이 계획 시작하기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSchedule(BuildContext context, Curriculum curriculum) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        builder: (BuildContext context, ScrollController controller) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: <Widget>[
              Text(
                '${curriculum.title} 전체 일정',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              for (final CurriculumDay day in curriculum.days)
                CurriculumDayTile(day: day),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 하루 일정을 읽기 전용으로 보여 주는 줄. 일정 미리보기에서 쓴다.
class CurriculumDayTile extends StatelessWidget {
  const CurriculumDayTile({super.key, required this.day});

  final CurriculumDay day;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return SectionCard(
      title: '${day.day}일째 · ${day.focus}',
      color: AppTheme.seed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final CurriculumTask task in day.tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(taskIcon(task.kind), size: 16, color: scheme.outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.label,
                      style: const TextStyle(fontSize: 14, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            '약 ${day.estimatedMinutes}분',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          if (day.note != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              day.note!,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 할 일 종류에 맞는 아이콘.
IconData taskIcon(TaskKind kind) => switch (kind) {
      TaskKind.part => Icons.mic_none_rounded,
      TaskKind.exam => Icons.assignment_outlined,
      TaskKind.review => Icons.headphones_outlined,
    };
