import 'package:flutter/material.dart';

import '../data/question_bank.dart';
import '../models/question.dart';
import '../models/toeic_part.dart';
import '../services/attempt_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'practice_screen.dart';

/// 파트 하나에 해당하는 탭 화면.
class PartTab extends StatelessWidget {
  const PartTab({super.key, required this.part});

  final ToeicPart part;

  @override
  Widget build(BuildContext context) {
    final List<Question> questions = questionsOfPart(part.id);
    final Color color = AppTheme.partColor(part.id);

    return AnimatedBuilder(
      animation: AttemptStore.instance,
      builder: (BuildContext context, Widget? _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            _PartHeader(part: part, color: color),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Text(
                  '연습 문항 ${questions.length}개',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '녹음 ${AttemptStore.instance.countOfPart(part.id)}회',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final Question q in questions)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: QuestionCard(
                  question: q,
                  attemptCount: AttemptStore.instance.ofQuestion(q.id).length,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          PracticeScreen(question: q),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PartHeader extends StatelessWidget {
  const _PartHeader({required this.part, required this.color});

  final ToeicPart part;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AppTheme.partIcon(part.id),
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      part.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      part.englishTitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            part.description,
            style: const TextStyle(fontSize: 14.5, height: 1.55),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _MiniStat(
                icon: Icons.timer_outlined,
                label: '준비',
                value: part.defaultPrepSeconds >= 60
                    ? formatSeconds(part.defaultPrepSeconds)
                    : '${part.defaultPrepSeconds}초',
                color: color,
              ),
              const SizedBox(width: 8),
              _MiniStat(
                icon: Icons.mic_none,
                label: '답변',
                value: part.defaultAnswerSeconds >= 60
                    ? formatSeconds(part.defaultAnswerSeconds)
                    : '${part.defaultAnswerSeconds}초',
                color: color,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => showPartTipsSheet(context, part),
                style: TextButton.styleFrom(foregroundColor: color),
                icon: const Icon(Icons.lightbulb_outline, size: 18),
                label: const Text('공략법'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
