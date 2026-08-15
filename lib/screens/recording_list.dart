import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/question_bank.dart';
import '../models/attempt.dart';
import '../models/question.dart';
import '../services/attempt_store.dart';
import '../services/playback_service.dart';
import '../theme.dart';

final DateFormat _dateFormat = DateFormat('yyyy.MM.dd HH:mm');

/// 녹음 1건을 재생/삭제할 수 있는 타일.
class AttemptTile extends StatelessWidget {
  const AttemptTile({
    super.key,
    required this.attempt,
    this.onDeleted,
    this.showQuestionTitle = false,
  });

  final Attempt attempt;
  final VoidCallback? onDeleted;
  final bool showQuestionTitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = AppTheme.partColor(attempt.partId);
    final Question? question = questionById(attempt.questionId);

    return AnimatedBuilder(
      animation: PlaybackService.instance,
      builder: (BuildContext context, Widget? _) {
        final bool playing = PlaybackService.instance.isPlaying(attempt.filePath);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: playing ? color.withValues(alpha: 0.08) : scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: playing
                  ? color.withValues(alpha: 0.5)
                  : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: <Widget>[
              IconButton(
                onPressed: () => PlaybackService.instance.toggle(attempt.filePath),
                style: IconButton.styleFrom(
                  backgroundColor: color.withValues(alpha: 0.12),
                  foregroundColor: color,
                ),
                icon: Icon(
                  playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      showQuestionTitle
                          ? (question?.title ?? attempt.promptLabel)
                          : attempt.promptLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_dateFormat.format(attempt.createdAt)} · '
                      '${formatSeconds(attempt.durationSeconds)}'
                      '${showQuestionTitle ? ' · ${attempt.promptLabel}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '삭제',
                onPressed: () async {
                  if (playing) await PlaybackService.instance.stop();
                  await AttemptStore.instance.remove(attempt);
                  onDeleted?.call();
                },
                icon: Icon(Icons.delete_outline, color: scheme.outline),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 전체 녹음 기록 탭.
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: AttemptStore.instance,
      builder: (BuildContext context, Widget? _) {
        final List<Attempt> attempts = AttemptStore.instance.attempts;
        if (attempts.isEmpty) {
          return _EmptyHistory(scheme: scheme);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '총 ${attempts.length}개 · '
                    '${formatSeconds(AttemptStore.instance.totalDuration.inSeconds)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final bool? ok = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('전체 삭제'),
                        content: const Text('저장된 모든 녹음을 삭제합니다. 되돌릴 수 없습니다.'),
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
                      await PlaybackService.instance.stop();
                      await AttemptStore.instance.clearAll();
                    }
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: const Text('전체 삭제'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final Attempt a in attempts)
              AttemptTile(attempt: a, showQuestionTitle: true),
          ],
        );
      },
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.mic_none, size: 56, color: scheme.outline),
            const SizedBox(height: 16),
            const Text(
              '아직 녹음한 답변이 없습니다',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '위쪽 탭에서 파트를 골라 연습을 시작해 보세요.\n'
              '녹음한 답변은 여기에 모두 모입니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
