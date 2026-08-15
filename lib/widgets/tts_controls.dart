import 'package:flutter/material.dart';

import '../services/tts_service.dart';

/// 지문을 브라우저 음성으로 들어 보는 컨트롤.
/// 녹음 중에는 소리가 마이크로 들어가므로 [enabled] 를 false 로 넘겨 막는다.
class TtsControls extends StatelessWidget {
  const TtsControls({
    super.key,
    required this.text,
    required this.color,
    this.enabled = true,
  });

  final String text;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: TtsService.instance,
      builder: (BuildContext context, Widget? _) {
        final TtsService tts = TtsService.instance;
        if (!tts.isAvailable) {
          return Row(
            children: <Widget>[
              Icon(Icons.volume_off_outlined, size: 16, color: scheme.outline),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '이 브라우저에서는 읽어주기를 쓸 수 없습니다.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        }

        final bool speaking = tts.isSpeakingText(text);
        return Row(
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: enabled ? () => tts.toggle(text) : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: Icon(
                speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                size: 20,
              ),
              label: Text(speaking ? '정지' : '들어보기'),
            ),
            const SizedBox(width: 10),
            _SpeedToggle(
              slow: tts.isSlow,
              color: color,
              onChanged: enabled ? (bool slow) => tts.setSlow(slow) : null,
            ),
            const Spacer(),
            if (!enabled)
              Text(
                '녹음 중에는 멈춤',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
          ],
        );
      },
    );
  }
}

class _SpeedToggle extends StatelessWidget {
  const _SpeedToggle({
    required this.slow,
    required this.color,
    required this.onChanged,
  });

  final bool slow;
  final Color color;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _speedButton(context, label: '보통', selected: !slow, value: false),
          _speedButton(context, label: '느리게', selected: slow, value: true),
        ],
      ),
    );
  }

  Widget _speedButton(
    BuildContext context, {
    required String label,
    required bool selected,
    required bool value,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(value),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : null,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? color : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
