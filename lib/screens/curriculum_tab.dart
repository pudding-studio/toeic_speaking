import 'package:flutter/material.dart';

import '../data/curricula.dart';
import '../models/curriculum.dart';
import '../models/toeic_part.dart';
import '../services/curriculum_store.dart';
import '../theme.dart';
import '../widgets/question_content.dart';
import 'curriculum_picker_screen.dart';

/// 학습 계획 탭.
///
/// 계획을 고르기 전에는 안내를, 고른 뒤에는 오늘 할 일과 전체 일정을 보여 준다.
class CurriculumTab extends StatelessWidget {
  const CurriculumTab({
    super.key,
    required this.onSelectPart,
    required this.onSelectExam,
  });

  /// 파트 연습 할 일을 누르면 해당 파트 탭으로 보낸다.
  final void Function(PartId partId) onSelectPart;

  /// 모의고사 할 일을 누르면 실전 모의고사 탭으로 보낸다.
  final VoidCallback onSelectExam;

  Future<void> _openPicker(BuildContext context, String? currentId) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            CurriculumPickerScreen(currentId: currentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurriculumStore.instance,
      builder: (BuildContext context, Widget? _) {
        final CurriculumStore store = CurriculumStore.instance;
        final Curriculum? active = store.active;

        if (active == null) {
          return _EmptyState(onPick: () => _openPicker(context, null));
        }
        return _ActivePlan(
          curriculum: active,
          onSelectPart: onSelectPart,
          onSelectExam: onSelectExam,
          onChangePlan: () => _openPicker(context, active.id),
        );
      },
    );
  }
}

/// 아직 계획을 고르지 않았을 때.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF0F6B4F), Color(0xFF2F5BEA)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '학습 계획',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '시험까지 남은 기간을 고르면 매일 무엇을 몇 문항 풀고 실전을 몇 번 볼지 '
                '날짜별로 짜 드립니다.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          '고를 수 있는 계획',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        // 계획 데이터에서 바로 만들어, 계획을 고쳐도 소개가 어긋나지 않게 한다.
        for (final Curriculum c in kCurricula)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.seed,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${c.title} · 하루 평균 ${c.averageMinutes}분 · '
                        '실전 ${c.examCount}회',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onPick,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.seed),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('계획 고르기'),
        ),
        if (!CurriculumStore.instance.isPersistent) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            '이 브라우저에서는 진행 상태를 저장할 수 없습니다(시크릿 모드 등). '
            '새로고침하면 사라집니다.',
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// 계획을 진행 중일 때. 오늘 할 일이 맨 위에 온다.
class _ActivePlan extends StatelessWidget {
  const _ActivePlan({
    required this.curriculum,
    required this.onSelectPart,
    required this.onSelectExam,
    required this.onChangePlan,
  });

  final Curriculum curriculum;
  final void Function(PartId partId) onSelectPart;
  final VoidCallback onSelectExam;
  final VoidCallback onChangePlan;

  Future<void> _confirmStop(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('계획을 그만둘까요?'),
        content: const Text('체크해 둔 진행 상태가 사라집니다. 녹음은 그대로 남습니다.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('그만두기'),
          ),
        ],
      ),
    );
    if (ok ?? false) await CurriculumStore.instance.stop();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final CurriculumStore store = CurriculumStore.instance;
    final CurriculumProgress progress = store.progress!;
    final int today = store.todayNumber();
    final CurriculumDay? todayPlan = curriculum.dayAt(today);
    final ({int done, int total}) counts = store.counts();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        _ProgressHeader(
          curriculum: curriculum,
          today: today,
          done: counts.done,
          total: counts.total,
          overdue: store.isOverdue(),
        ),
        const SizedBox(height: 20),
        if (todayPlan != null) ...<Widget>[
          Row(
            children: <Widget>[
              const Text(
                '오늘 할 일',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Text(
                '약 ${todayPlan.estimatedMinutes}분',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DayCard(
            day: todayPlan,
            progress: progress,
            highlighted: true,
            onSelectPart: onSelectPart,
            onSelectExam: onSelectExam,
          ),
          const SizedBox(height: 20),
        ],
        const Text(
          '전체 일정',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          '오늘이 아니어도 미리 하거나 밀린 날을 채울 수 있습니다.',
          style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        for (final CurriculumDay day in curriculum.days)
          _DayCard(
            day: day,
            progress: progress,
            isToday: day.day == today,
            onSelectPart: onSelectPart,
            onSelectExam: onSelectExam,
          ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _confirmStop(context),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('그만두기'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: onChangePlan,
                style: FilledButton.styleFrom(backgroundColor: AppTheme.seed),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('다른 계획으로 바꾸기'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 진행률 요약.
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.curriculum,
    required this.today,
    required this.done,
    required this.total,
    required this.overdue,
  });

  final Curriculum curriculum;
  final int today;
  final int done;
  final int total;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final double ratio = total == 0 ? 0 : done / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF0F6B4F), Color(0xFF2F5BEA)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            curriculum.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            overdue
                ? '계획 기간이 끝났습니다 · 남은 할 일을 채우거나 계획을 다시 시작하세요'
                : '$today일째 / ${curriculum.totalDays}일',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '할 일 $done / $total 완료',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 하루치 카드. 할 일을 눌러 체크하거나, 오른쪽 화살표로 해당 화면으로 간다.
class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.progress,
    required this.onSelectPart,
    required this.onSelectExam,
    this.highlighted = false,
    this.isToday = false,
  });

  final CurriculumDay day;
  final CurriculumProgress progress;
  final void Function(PartId partId) onSelectPart;
  final VoidCallback onSelectExam;
  final bool highlighted;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool dayDone = progress.isDayDone(day);

    return SectionCard(
      title: '${day.day}일째 · ${day.focus}',
      color: dayDone ? const Color(0xFF0F6B4F) : AppTheme.seed,
      highlighted: highlighted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (isToday && !highlighted) ...<Widget>[
            const _TodayBadge(),
            const SizedBox(height: 8),
          ],
          for (int i = 0; i < day.tasks.length; i++)
            _TaskRow(
              task: day.tasks[i],
              done: progress.isDone(day.taskKey(i)),
              onToggle: () =>
                  CurriculumStore.instance.toggleTask(day.taskKey(i)),
              onGo: switch (day.tasks[i].kind) {
                TaskKind.part => () => onSelectPart(day.tasks[i].partId!),
                TaskKind.exam => onSelectExam,
                TaskKind.review => null,
              },
            ),
          if (day.note != null) ...<Widget>[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.tips_and_updates_outlined,
                    size: 17,
                    color: scheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      day.note!,
                      style: const TextStyle(fontSize: 12.5, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayBadge extends StatelessWidget {
  const _TodayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.seed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '오늘',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.seed,
        ),
      ),
    );
  }
}

/// 할 일 한 줄. 체크박스는 진행 표시용이고, 오른쪽 버튼이 실제 연습 화면으로 보낸다.
class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.done,
    required this.onToggle,
    required this.onGo,
  });

  final CurriculumTask task;
  final bool done;
  final VoidCallback onToggle;

  /// 연습 화면으로 보내는 동작. 복습 항목처럼 갈 곳이 없으면 null.
  final VoidCallback? onGo;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              done ? Icons.check_circle : Icons.circle_outlined,
              size: 21,
              color: done ? const Color(0xFF0F6B4F) : scheme.outline,
            ),
            const SizedBox(width: 10),
            Icon(taskIcon(task.kind), size: 16, color: scheme.outline),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                task.label,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? scheme.onSurfaceVariant : null,
                ),
              ),
            ),
            if (onGo != null)
              IconButton(
                tooltip: '연습하러 가기',
                onPressed: onGo,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}
