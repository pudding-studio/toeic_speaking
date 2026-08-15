import 'package:flutter/material.dart';

import '../data/question_bank.dart';
import '../models/attempt.dart';
import '../models/toeic_part.dart';
import '../services/attempt_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'recording_list.dart';

/// 첫 번째 탭. 시험 구조 요약 + 학습 통계 + 최근 녹음.
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.onSelectPart});

  /// 파트 카드를 누르면 해당 탭으로 이동시키는 콜백.
  final void Function(PartId partId) onSelectPart;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: AttemptStore.instance,
      builder: (BuildContext context, Widget? _) {
        final AttemptStore store = AttemptStore.instance;
        final List<Attempt> recent = store.attempts.take(3).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            _StatsCard(store: store),
            const SizedBox(height: 22),
            const Text(
              '파트별 연습',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '총 11문항 · 약 20분. 파트를 골라 실제 시험과 같은 시간으로 연습하세요.',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            for (final ToeicPart part in kToeicParts)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PartTile(
                  part: part,
                  questionCount: questionsOfPart(part.id).length,
                  attemptCount: store.countOfPart(part.id),
                  onTap: () => onSelectPart(part.id),
                ),
              ),
            if (recent.isNotEmpty) ...<Widget>[
              const SizedBox(height: 18),
              const Text(
                '최근 녹음',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              for (final Attempt a in recent)
                AttemptTile(attempt: a, showQuestionTitle: true),
            ],
          ],
        );
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.store});

  final AttemptStore store;

  @override
  Widget build(BuildContext context) {
    final Duration total = store.totalDuration;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF2F5BEA), Color(0xFF6A3FE4)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'TOEIC Speaking 연습',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '실제 시험과 동일한 준비/답변 시간으로 녹음하고 바로 들어 보세요.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              _StatItem(value: '${store.attempts.length}', label: '녹음 수'),
              const _StatDivider(),
              _StatItem(
                value: total.inMinutes >= 1
                    ? '${total.inMinutes}분'
                    : '${total.inSeconds}초',
                label: '총 발화 시간',
              ),
              const _StatDivider(),
              _StatItem(value: '${store.practicedDayCount}', label: '연습한 날'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }
}

class _PartTile extends StatelessWidget {
  const _PartTile({
    required this.part,
    required this.questionCount,
    required this.attemptCount,
    required this.onTap,
  });

  final ToeicPart part;
  final int questionCount;
  final int attemptCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = AppTheme.partColor(part.id);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(AppTheme.partIcon(part.id), color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      part.title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '문항 $questionCount개'
                      '${attemptCount > 0 ? ' · 녹음 $attemptCount회' : ''}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.outline),
            ],
          ),
      ),
    );
  }
}
