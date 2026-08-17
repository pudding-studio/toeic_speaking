import 'package:flutter/material.dart';

import '../services/sample_audio_service.dart';
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
    return AnimatedBuilder(
      animation: TtsService.instance,
      builder: (BuildContext context, Widget? _) {
        final TtsService tts = TtsService.instance;
        return TtsControlsView(
          color: color,
          enabled: enabled,
          available: tts.isAvailable,
          speaking: tts.isSpeakingText(text),
          loading: tts.isLoadingText(text),
          slow: tts.isSlow,
          statusLabel: _statusLabel(tts, enabled: enabled),
          onToggle: () => tts.toggle(text),
          onSlowChanged: (bool slow) => tts.setSlow(slow),
        );
      },
    );
  }
}

/// 읽어주기 컨트롤의 겉모습. 서비스를 직접 보지 않아 그대로 테스트할 수 있다.
class TtsControlsView extends StatelessWidget {
  const TtsControlsView({
    super.key,
    required this.color,
    required this.enabled,
    required this.available,
    required this.speaking,
    required this.loading,
    required this.slow,
    required this.statusLabel,
    required this.onToggle,
    required this.onSlowChanged,
  });

  final Color color;
  final bool enabled;
  final bool available;
  final bool speaking;
  final bool loading;
  final bool slow;
  final String statusLabel;
  final VoidCallback onToggle;
  final ValueChanged<bool> onSlowChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    if (!available) {
      return Row(
        children: <Widget>[
          Icon(Icons.volume_off_outlined, size: 16, color: scheme.outline),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '이 브라우저에서는 읽어주기를 쓸 수 없습니다.',
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: enabled && !loading ? onToggle : null,
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
          icon: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(
                  speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                  size: 20,
                ),
          label: Text(
            loading
                ? '만드는 중'
                : speaking
                    ? '정지'
                    : '들어보기',
          ),
        ),
        const SizedBox(width: 10),
        _SpeedToggle(
          slow: slow,
          color: color,
          onChanged: enabled ? onSlowChanged : null,
        ),
        const Spacer(),
        Flexible(
          child: Text(
            statusLabel,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// 지금 어떤 엔진·음성으로 읽는지 알려 준다.
/// 브라우저 음성은 시스템에 깔린 음성에 따라 달라지므로 이름까지 보여 준다.
String _statusLabel(TtsService tts, {required bool enabled}) {
  if (!enabled) return '녹음 중에는 멈춤';
  if (tts.engine == TtsEngine.google) return 'Google 음성';
  final String? voice = tts.browserVoiceName;
  return voice == null ? '브라우저 음성' : '브라우저 음성 · $voice';
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

/// 문항에 직접 올려 둔 예시 음성을 재생하는 컨트롤.
/// 녹음 중에는 소리가 마이크로 들어가므로 [enabled] 를 false 로 넘겨 막는다.
class SampleAudioControls extends StatelessWidget {
  const SampleAudioControls({
    super.key,
    required this.questionId,
    required this.color,
    this.enabled = true,
  });

  final String questionId;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: SampleAudioService.instance,
      builder: (BuildContext context, Widget? _) {
        final SampleAudioService audio = SampleAudioService.instance;
        final bool playing = audio.isPlaying(questionId);
        final bool loading = audio.isLoading(questionId);

        return Row(
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed:
                  enabled && !loading ? () => audio.toggle(questionId) : null,
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
              icon: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(
                      playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      size: 20,
                    ),
              label: Text(playing ? '정지' : '예시 음성 듣기'),
            ),
            const Spacer(),
            Text(
              enabled ? '직접 올린 음성' : '녹음 중에는 멈춤',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        );
      },
    );
  }
}
