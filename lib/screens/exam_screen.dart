import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/attempt.dart';
import '../models/exam_set.dart';
import '../models/question.dart';
import '../models/toeic_part.dart';
import '../services/attempt_store.dart';
import '../services/playback_service.dart';
import '../services/recorder_service.dart';
import '../services/sample_audio_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/countdown_ring.dart';
import '../widgets/question_content.dart';
import 'recording_list.dart';

/// 시험 진행 상태.
///
/// 실제 시험처럼 한 번 시작하면 [directions] → [prep] → [answering] → [gap] 이
/// 11문항이 끝날 때까지 저절로 굴러간다. 중간에 누를 버튼은 "그만두기" 뿐이다.
enum _Phase {
  /// 시작 전 안내 화면.
  intro,

  /// 파트가 바뀔 때 나오는 파트 안내.
  directions,

  /// 준비 시간.
  prep,

  /// 답변(녹음) 시간.
  answering,

  /// 다음 문항으로 넘어가기 전 잠깐 쉬는 구간.
  gap,

  /// 11문항을 다 마친 뒤 결과 화면.
  finished,
}

/// 파트 안내를 보여 주는 시간(초). 실제 시험의 디렉션 낭독을 대신한다.
const int _kDirectionsSeconds = 12;

/// 문항 사이의 짧은 간격(초).
/// 마이크를 정리할 시간을 주는 역할도 한다.
const int _kGapSeconds = 2;

/// 모의고사 한 회를 실제 시험처럼 연속으로 응시하는 화면.
class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key, required this.plan});

  final ExamPlan plan;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  Timer? _timer;
  DateTime? _deadline;
  int _phaseTotalMs = 1;
  int _remainingMs = 0;

  int _index = 0;
  _Phase _phase = _Phase.intro;
  bool _busy = false;

  /// 문항 번호 → 그 문항에서 저장된 녹음.
  final Map<int, Attempt> _recorded = <int, Attempt>{};

  ExamPlan get _plan => widget.plan;
  List<ExamStep> get _steps => _plan.steps;
  ExamStep get _step => _steps[_index];
  Color get _color => AppTheme.partColor(_step.partId);

  bool get _isLastStep => _index >= _steps.length - 1;

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(TtsService.instance.stop());
    unawaited(SampleAudioService.instance.stop());
    if (_phase == _Phase.answering) {
      unawaited(RecorderService.instance.cancel());
    }
    super.dispose();
  }

  // ─────────────────────────── 타이머 ───────────────────────────

  void _startCountdown(int seconds, VoidCallback onDone) {
    _timer?.cancel();
    _phaseTotalMs = seconds * 1000;
    _remainingMs = _phaseTotalMs;
    _deadline = DateTime.now().add(Duration(milliseconds: _phaseTotalMs));
    _timer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
      final DateTime? deadline = _deadline;
      if (deadline == null) return;
      final int left = deadline.difference(DateTime.now()).inMilliseconds;
      if (left <= 0) {
        t.cancel();
        if (!mounted) return;
        setState(() => _remainingMs = 0);
        onDone();
      } else {
        if (!mounted) return;
        setState(() => _remainingMs = left);
      }
    });
  }

  void _stopCountdown() {
    _timer?.cancel();
    _timer = null;
    _deadline = null;
  }

  double get _progress =>
      _phaseTotalMs == 0 ? 0 : (_remainingMs / _phaseTotalMs).clamp(0.0, 1.0);

  int get _remainingSeconds => (_remainingMs / 1000).ceil();

  // ─────────────────────────── 흐름 ───────────────────────────

  /// 시험 시작. 도중에 권한 창이 뜨면 시간을 까먹으므로 먼저 물어본다.
  Future<void> _start() async {
    final bool granted = await RecorderService.instance.hasPermission();
    if (!mounted) return;
    if (!granted) {
      _showPermissionDialog();
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    _enterStep();
  }

  /// 현재 문항을 시작한다. 파트가 바뀌면 안내부터 보여 준다.
  void _enterStep() {
    if (_step.isPartStart) {
      setState(() => _phase = _Phase.directions);
      _startCountdown(_kDirectionsSeconds, _beginPrep);
    } else {
      _beginPrep();
    }
  }

  void _beginPrep() {
    if (!mounted) return;
    if (_step.prompt.prepSeconds <= 0) {
      unawaited(_startAnswering());
      return;
    }
    setState(() => _phase = _Phase.prep);
    _startCountdown(_step.prompt.prepSeconds, () {
      unawaited(_startAnswering());
    });
  }

  Future<void> _startAnswering() async {
    if (_busy) return;
    _busy = true;
    _stopCountdown();
    // 스피커 소리가 녹음에 섞이지 않도록 먼저 멈춘다.
    await TtsService.instance.stop();
    await SampleAudioService.instance.stop();
    final bool started = await RecorderService.instance.start();
    _busy = false;
    if (!mounted) return;
    if (!started) {
      _stopCountdown();
      setState(() => _phase = _Phase.intro);
      _showPermissionDialog();
      return;
    }
    unawaited(HapticFeedback.heavyImpact());
    unawaited(SystemSound.play(SystemSoundType.click));
    setState(() => _phase = _Phase.answering);
    _startCountdown(_step.prompt.answerSeconds, () {
      unawaited(_finishAnswering(auto: true));
    });
  }

  Future<void> _finishAnswering({required bool auto}) async {
    if (_busy) return;
    _busy = true;
    _stopCountdown();
    final ExamStep step = _step;
    final int spoken = auto
        ? step.prompt.answerSeconds
        : (_phaseTotalMs - _remainingMs) ~/ 1000;
    final String? audioDataUrl = await RecorderService.instance.stopAndRead();
    _busy = false;
    if (!mounted) return;

    unawaited(HapticFeedback.mediumImpact());

    if (audioDataUrl != null) {
      final Attempt attempt = Attempt(
        id: '${_plan.set.id}_${step.number}_'
            '${DateTime.now().microsecondsSinceEpoch}',
        questionId: step.question.id,
        partId: step.partId,
        stepIndex: step.promptIndex,
        promptLabel:
            'Q${step.number} · ${step.prompt.label ?? step.question.title}',
        durationSeconds: spoken < 1 ? 1 : spoken,
        createdAt: DateTime.now(),
        examSetId: _plan.set.id,
        questionNumber: step.number,
      );
      // 저장이 끝나기 전에도 바로 들을 수 있게 캐시에 넣어 둔다.
      PlaybackService.instance.cache(attempt.id, audioDataUrl);
      _recorded[step.number] = attempt;
      await AttemptStore.instance.add(attempt, audioDataUrl);
    }

    if (!mounted) return;
    if (_isLastStep) {
      setState(() => _phase = _Phase.finished);
      return;
    }
    // 실제 시험처럼 곧바로 다음 문항으로 넘어간다.
    setState(() => _phase = _Phase.gap);
    _startCountdown(_kGapSeconds, () {
      if (!mounted) return;
      setState(() => _index += 1);
      _enterStep();
    });
  }

  /// 안내·준비 시간을 건너뛰고 바로 다음 단계로.
  void _skipPhase() {
    switch (_phase) {
      case _Phase.directions:
        _stopCountdown();
        _beginPrep();
      case _Phase.prep:
        unawaited(_startAnswering());
      case _Phase.gap:
        _stopCountdown();
        if (!mounted) return;
        setState(() => _index += 1);
        _enterStep();
      case _Phase.intro:
      case _Phase.answering:
      case _Phase.finished:
        break;
    }
  }

  Future<void> _abort() async {
    if (!await _confirmExit()) return;
    _stopCountdown();
    if (_phase == _Phase.answering) {
      await RecorderService.instance.cancel();
    }
    if (!mounted) return;
    // 지금까지 녹음한 것은 남겨 두고 결과 화면으로 보낸다.
    setState(() => _phase = _recorded.isEmpty ? _Phase.intro : _Phase.finished);
  }

  void _restart() {
    _stopCountdown();
    setState(() {
      _index = 0;
      _phase = _Phase.intro;
      _remainingMs = 0;
      _recorded.clear();
    });
  }

  void _showPermissionDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('마이크 권한이 필요합니다'),
        content: const Text(
          '모의고사를 응시하려면 브라우저에서 마이크 사용을 허용해 주세요.\n'
          '거부한 경우 주소창 왼쪽의 자물쇠 아이콘에서 다시 허용할 수 있습니다.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmExit() async {
    if (_phase == _Phase.intro || _phase == _Phase.finished) return true;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('모의고사를 중단할까요?'),
        content: const Text(
          '실제 시험은 중간에 멈출 수 없습니다.\n'
          '지금까지 저장된 녹음은 그대로 남고, 진행 중인 녹음만 사라집니다.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('계속 응시'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('중단'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  // ─────────────────────────── UI ───────────────────────────

  bool get _running =>
      _phase == _Phase.directions ||
      _phase == _Phase.prep ||
      _phase == _Phase.answering ||
      _phase == _Phase.gap;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_running,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final NavigatorState navigator = Navigator.of(context);
        if (await _confirmExit()) {
          _stopCountdown();
          if (_phase == _Phase.answering) {
            await RecorderService.instance.cancel();
          }
          if (mounted) navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_plan.set.title),
          bottom: _running
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(44),
                  child: _ProgressBar(
                    plan: _plan,
                    index: _index,
                    color: _color,
                    phase: _phase,
                  ),
                )
              : null,
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _body(),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _controls(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.intro:
        return _IntroPanel(plan: _plan);
      case _Phase.directions:
        return _DirectionsPanel(
          part: _step.part,
          number: _step.number,
          color: _color,
          remainingSeconds: _remainingSeconds,
        );
      case _Phase.gap:
        return _GapPanel(
          nextStep: _steps[_index + 1],
          remainingSeconds: _remainingSeconds,
        );
      case _Phase.prep:
      case _Phase.answering:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _timerPanel(),
            const SizedBox(height: 20),
            QuestionContent(
              question: _step.question,
              step: _step.prompt,
              color: _color,
              audioEnabled: false,
              // 실제 시험과 같은 조건이어야 하므로 모범 답안과
              // 읽어주기·예시 음성은 시험이 끝날 때까지 보여 주지 않는다.
              showAnswers: false,
              showSampleAudio: false,
              showTts: false,
            ),
          ],
        );
      case _Phase.finished:
        return _ResultPanel(
          plan: _plan,
          recorded: _recorded,
          onDeleted: (int number) => setState(() => _recorded.remove(number)),
        );
    }
  }

  Widget _timerPanel() {
    final bool answering = _phase == _Phase.answering;
    return Column(
      children: <Widget>[
        CountdownRing(
          progress: _progress,
          label: formatSeconds(_remainingSeconds),
          caption: answering ? '● 녹음 중' : '준비 시간',
          color: answering ? const Color(0xFFD1425A) : _color,
          size: 200,
        ),
        if (_step.prompt.hint != null) ...<Widget>[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.tips_and_updates_outlined, size: 18, color: _color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _step.prompt.hint!,
                    style: const TextStyle(fontSize: 13.5, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _controls() {
    switch (_phase) {
      case _Phase.intro:
        return FilledButton.icon(
          onPressed: _plan.isEmpty ? null : () => unawaited(_start()),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.seed),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('모의고사 시작 (${_steps.length}문항)'),
        );

      case _Phase.directions:
      case _Phase.gap:
        return Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () => unawaited(_abort()),
                child: const Text('그만두기'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _skipPhase,
                style: FilledButton.styleFrom(backgroundColor: _color),
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('바로 넘어가기'),
              ),
            ),
          ],
        );

      case _Phase.prep:
        return Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () => unawaited(_abort()),
                child: const Text('그만두기'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _skipPhase,
                style: FilledButton.styleFrom(backgroundColor: _color),
                icon: const Icon(Icons.mic),
                label: const Text('바로 답변 시작'),
              ),
            ),
          ],
        );

      case _Phase.answering:
        return FilledButton.icon(
          onPressed: () => unawaited(_finishAnswering(auto: false)),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD1425A),
          ),
          icon: const Icon(Icons.stop_rounded),
          label: const Text('답변 끝내기'),
        );

      case _Phase.finished:
        return Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.list_alt),
                label: const Text('목록으로'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _restart,
                style: FilledButton.styleFrom(backgroundColor: AppTheme.seed),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다시 응시하기'),
              ),
            ),
          ],
        );
    }
  }
}

/// 상단의 진행 표시. 지금 몇 번 문항인지, 어떤 파트인지 보여 준다.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.plan,
    required this.index,
    required this.color,
    required this.phase,
  });

  final ExamPlan plan;
  final int index;
  final Color color;
  final _Phase phase;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ExamStep step = plan.steps[index];
    final String status = switch (phase) {
      _Phase.directions => '파트 안내',
      _Phase.prep => '준비 시간',
      _Phase.answering => '녹음 중',
      _Phase.gap => '다음 문항 준비',
      _ => '',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              PartBadge(part: step.part, dense: true),
              const SizedBox(width: 8),
              Text(
                'Question ${step.number} / ${plan.steps.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (index + 1) / plan.steps.length,
              minHeight: 4,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// 시작 전 안내.
class _IntroPanel extends StatelessWidget {
  const _IntroPanel({required this.plan});

  final ExamPlan plan;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Duration total = plan.totalDuration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
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
              Text(
                plan.set.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${plan.steps.length}문항 · 약 ${total.inMinutes + 1}분',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (plan.missingIds.isNotEmpty) ...<Widget>[
          _WarningCard(
            text: '문항 ${plan.missingIds.length}개를 찾지 못해 건너뜁니다. '
                '회차에 넣어 둔 문항을 지우면 이렇게 됩니다.',
          ),
          const SizedBox(height: 14),
        ],
        const SectionCard(
          title: '시작하기 전에',
          color: AppTheme.seed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Bullet('한 번 시작하면 준비 시간과 답변 시간이 실제 시험처럼 저절로 흘러갑니다.'),
              _Bullet('모범 답안과 읽어주기는 시험이 끝난 뒤에 볼 수 있습니다.'),
              _Bullet('조용한 곳에서 마이크를 켜고, 중간에 자리를 뜨지 마세요.'),
              _Bullet('중단하더라도 그때까지 녹음한 답변은 남습니다.'),
            ],
          ),
        ),
        SectionCard(
          title: '문항 구성',
          color: AppTheme.seed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final ExamStep step in _partStarts(plan))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: <Widget>[
                      PartBadge(part: step.part, dense: true),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          step.part.englishTitle,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 파트가 시작되는 단계만 골라 온다(문항 구성 미리보기용).
  static List<ExamStep> _partStarts(ExamPlan plan) =>
      plan.steps.where((ExamStep s) => s.isPartStart).toList();
}

/// 파트가 바뀔 때 나오는 안내. 실제 시험의 디렉션에 해당한다.
class _DirectionsPanel extends StatelessWidget {
  const _DirectionsPanel({
    required this.part,
    required this.number,
    required this.color,
    required this.remainingSeconds,
  });

  final ToeicPart part;
  final int number;
  final Color color;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(AppTheme.partIcon(part.id), color: color, size: 30),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Questions ${part.questionRange.replaceAll('Q', '')}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          part.englishTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          part.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.6,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            '$remainingSeconds초 후 시작',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: '이 파트에서 점수를 지키는 법',
          color: color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final String tip in part.tips.take(3)) _Bullet(tip),
            ],
          ),
        ),
      ],
    );
  }
}

/// 문항과 문항 사이의 짧은 간격.
class _GapPanel extends StatelessWidget {
  const _GapPanel({required this.nextStep, required this.remainingSeconds});

  final ExamStep nextStep;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: <Widget>[
          Icon(Icons.more_horiz_rounded, size: 40, color: scheme.outline),
          const SizedBox(height: 14),
          Text(
            'Question ${nextStep.number} 준비 중',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '$remainingSeconds초 후 시작',
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 응시가 끝난 뒤의 결과. 문항 순서대로 녹음을 다시 들어 볼 수 있다.
class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.plan,
    required this.recorded,
    required this.onDeleted,
  });

  final ExamPlan plan;
  final Map<int, Attempt> recorded;
  final void Function(int number) onDeleted;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int spoken = recorded.values
        .fold<int>(0, (int sum, Attempt a) => sum + a.durationSeconds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: AppTheme.seed.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.emoji_events_outlined,
                      color: AppTheme.seed, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    recorded.length >= plan.steps.length ? '응시 완료' : '중단됨',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${plan.steps.length}문항 중 ${recorded.length}문항 녹음 · '
                '총 발화 ${formatSeconds(spoken)}',
                style: TextStyle(
                  fontSize: 13.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (recorded.isEmpty)
          Text(
            '저장된 녹음이 없습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
        for (final ExamStep step in plan.steps)
          if (recorded.containsKey(step.number))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AttemptTile(
                attempt: recorded[step.number]!,
                showQuestionTitle: true,
                onDeleted: () => onDeleted(step.number),
              ),
            ),
        const SizedBox(height: 10),
        SectionCard(
          title: '모범 답안 보기',
          color: AppTheme.seed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '문항별 모범 답안과 핵심 표현은 파트 탭에서 같은 문항을 열면 볼 수 있습니다.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              for (final Question q in plan.questions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: scheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          q.title,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: scheme.outline,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    const Color amber = Color(0xFFB26A00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.warning_amber_rounded, size: 20, color: amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
