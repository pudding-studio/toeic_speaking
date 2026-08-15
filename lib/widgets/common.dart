import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/question.dart';
import '../models/toeic_part.dart';
import '../services/question_store.dart';
import '../theme.dart';

/// 파트 색을 쓰는 작은 배지.
class PartBadge extends StatelessWidget {
  const PartBadge({super.key, required this.part, this.dense = false});

  final ToeicPart part;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final Color color = AppTheme.partColor(part.id);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        part.questionRange,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: dense ? 11 : 12,
        ),
      ),
    );
  }
}

/// 앱 전반에서 쓰는 카드 컨테이너. 탭 가능한 경우 잉크 효과가 붙는다.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: onTap == null ? child : InkWell(onTap: onTap, child: child),
    );
  }
}

/// 문항 목록에 쓰는 카드.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.attemptCount,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Question question;
  final int attemptCount;
  final VoidCallback onTap;

  /// 앱에서 등록한 문항일 때만 넘어온다.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ToeicPart part = question.part;
    final Color color = AppTheme.partColor(part.id);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(AppTheme.partIcon(part.id), color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          question.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (question.isCustom) ...<Widget>[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '내 문항',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '약 ${formatSeconds(question.totalSeconds)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.mic_none,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${question.steps.length}문항',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (attemptCount > 0) ...<Widget>[
                        const SizedBox(width: 12),
                        Icon(Icons.check_circle, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          '$attemptCount회 녹음',
                          style: TextStyle(
                            fontSize: 13,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (onEdit == null && onDelete == null)
              Icon(Icons.chevron_right, color: scheme.outline)
            else
              PopupMenuButton<String>(
                tooltip: '문항 관리',
                icon: Icon(Icons.more_vert, color: scheme.outline),
                onSelected: (String value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  if (onEdit != null)
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('수정'),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('삭제'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Q8-10 자료 표.
class InfoTableView extends StatelessWidget {
  const InfoTableView({super.key, required this.table, required this.color});

  final InfoTable table;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            color: color.withValues(alpha: 0.10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  table.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  table.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < table.rows.length; i++)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 82,
                    child: Text(
                      table.rows[i][0],
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      table.rows[i][1],
                      style: const TextStyle(fontSize: 14, height: 1.35),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 84,
                    child: Text(
                      table.rows[i].length > 2 ? table.rows[i][2] : '',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 파트 공략법 / 템플릿을 보여 주는 바텀시트.
void showPartTipsSheet(BuildContext context, ToeicPart part) {
  final Color color = AppTheme.partColor(part.id);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext context) {
      final ColorScheme scheme = Theme.of(context).colorScheme;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        builder: (BuildContext context, ScrollController controller) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: <Widget>[
              Text(
                part.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                part.englishTitle,
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Text(
                part.description,
                style: const TextStyle(fontSize: 15, height: 1.55),
              ),
              const SizedBox(height: 24),
              _SheetSectionTitle(title: '공략 포인트', color: color),
              const SizedBox(height: 10),
              for (final String tip in part.tips)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(fontSize: 14.5, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              _SheetSectionTitle(title: '바로 쓰는 템플릿', color: color),
              const SizedBox(height: 10),
              for (final String t in part.templates)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    t,
                    style: const TextStyle(fontSize: 14.5, height: 1.45),
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}

class _SheetSectionTitle extends StatelessWidget {
  const _SheetSectionTitle({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(width: 4, height: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

/// 문항 사진. 기본 문항은 에셋에서, 앱에서 등록한 문항은 브라우저 저장소에서 읽는다.
/// 사진이 없거나 읽지 못하면 안내 문구를 대신 보여 주고 연습은 그대로 진행된다.
class QuestionImage extends StatelessWidget {
  const QuestionImage({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: question.isCustom
            ? FutureBuilder<Uint8List?>(
                future: QuestionStore.instance.imageOf(question.id),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<Uint8List?> snapshot,
                ) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _ImageLoading();
                  }
                  final Uint8List? bytes = snapshot.data;
                  if (bytes == null) return const _ImageUnavailable();
                  return Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (BuildContext context, Object _, StackTrace? __) =>
                            const _ImageUnavailable(),
                  );
                },
              )
            : Image.asset(
                question.imagePath!,
                fit: BoxFit.cover,
                errorBuilder:
                    (BuildContext context, Object _, StackTrace? __) =>
                        const _ImageUnavailable(),
              ),
      ),
    );
  }
}

class _ImageLoading extends StatelessWidget {
  const _ImageLoading();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ImageUnavailable extends StatelessWidget {
  const _ImageUnavailable();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.image_not_supported_outlined,
              size: 32,
              color: scheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              '사진을 불러오지 못했습니다',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
