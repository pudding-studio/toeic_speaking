import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/attempt.dart';
import '../models/question.dart';
import '../models/toeic_part.dart';
import '../services/attempt_store.dart';
import '../services/recorder_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/countdown_ring.dart';
import 'recording_list.dart';

enum _Phase { ready, prep, answering, stepDone, finished }

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.question});

  final Question question;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  Timer? _timer;
  DateTime? _deadline;
  int _phaseTotalMs = 1;
  int _remainingMs = 0;

  int _stepIndex = 0;
  _Phase _phase = _Phase.ready;
  bool _busy = false;

  final List<Attempt> _sessionAttempts = <Attempt>[];

  Question get _q => widget.question;
  ToeicPart get _part => _q.part;
  List<Prompt> get _steps => _q.steps;
  Prompt get _step => _steps[_stepIndex];
  Color get _color => AppTheme.partColor(_part.id);

  @override
  void dispose() {
    _timer?.cancel();
    // 화면을 벗어날 때 진행 중인 녹음은 버린다.
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

  Future<void> _beginStep() async {
    unawaited(HapticFeedback.mediumImpact());
    if (_step.prepSeconds <= 0) {
      await _startAnswering();
      return;
    }
    setState(() => _phase = _Phase.prep);
    _startCountdown(_step.prepSeconds, () {
      unawaited(_startAnswering());
    });
  }

  Future<void> _startAnswering() async {
    if (_busy) return;
    _busy = true;
    _stopCountdown();
    final bool started = await RecorderService.instance.start(
      questionId: _q.id,
      stepIndex: _stepIndex,
    );
    _busy = false;
    if (!mounted) return;
    if (!started) {
      setState(() => _phase = _Phase.ready);
      _showPermissionDialog();
      return;
    }
    unawaited(HapticFeedback.heavyImpact());
    unawaited(SystemSound.play(SystemSoundType.click));
    setState(() => _phase = _Phase.answering);
    _startCountdown(_step.answerSeconds, () {
      unawaited(_finishAnswering(auto: true));
    });
  }

  Future<void> _finishAnswering({required bool auto}) async {
    if (_busy) return;
    _busy = true;
    _stopCountdown();
    final int spoken = auto
        ? _step.answerSeconds
        : (_phaseTotalMs - _remainingMs) ~/ 1000;
    final String? path = await RecorderService.instance.stop();
    _busy = false;
    if (!mounted) return;

    unawaited(HapticFeedback.mediumImpact());

    if (path != null) {
      final Attempt attempt = Attempt(
        id: '${_q.id}_${_stepIndex}_${DateTime.now().microsecondsSinceEpoch}',
        questionId: _q.id,
        partId: _q.partId,
        stepIndex: _stepIndex,
        promptLabel: _step.label ?? _q.title,
        filePath: path,
        durationSeconds: spoken < 1 ? 1 : spoken,
        createdAt: DateTime.now(),
      );
      _sessionAttempts.insert(0, attempt);
      await AttemptStore.instance.add(attempt);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('녹음이 저장되지 않았습니다. 마이크 상태를 확인해 주세요.')),
      );
    }

    if (!mounted) return;
    final bool isLast = _stepIndex >= _steps.length - 1;
    setState(() => _phase = isLast ? _Phase.finished : _Phase.stepDone);
  }

  void _nextStep() {
    setState(() {
      _stepIndex += 1;
      _phase = _Phase.ready;
    });
    unawaited(_beginStep());
  }

  void _restart() {
    setState(() {
      _stepIndex = 0;
      _phase = _Phase.ready;
      _remainingMs = 0;
    });
  }

  Future<void> _abort() async {
    _stopCountdown();
    if (_phase == _Phase.answering) {
      await RecorderService.instance.cancel();
    }
    if (!mounted) return;
    setState(() {
      _phase = _sessionAttempts.isEmpty ? _Phase.ready : _Phase.finished;
      _stepIndex = _phase == _Phase.ready ? 0 : _stepIndex;
    });
  }

  void _showPermissionDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('마이크 권한이 필요합니다'),
        content: const Text(
          '녹음을 하려면 마이크 권한을 허용해 주세요.\n'
          '설정 › 애플리케이션 › TOEIC Speaking › 권한에서 변경할 수 있습니다.',
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
    if (_phase != _Phase.prep && _phase != _Phase.answering) return true;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('연습을 중단할까요?'),
        content: const Text('진행 중인 녹음은 저장되지 않습니다.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('계속하기'),
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

  @override
  Widget build(BuildContext context) {
    final bool running = _phase == _Phase.prep || _phase == _Phase.answering;

    return PopScope(
      canPop: !running,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        // await 이후에는 context 를 쓸 수 없으므로 미리 확보해 둔다.
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
          title: Text(_q.title),
          actions: <Widget>[
            IconButton(
              tooltip: '공략법',
              onPressed: () => showPartTipsSheet(context, _part),
              icon: const Icon(Icons.lightbulb_outline),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: _StepIndicator(
              total: _steps.length,
              current: _stepIndex,
              color: _color,
              phase: _phase,
              part: _part,
            ),
          ),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (running || _phase == _Phase.stepDone) _timerPanel(),
                    if (running || _phase == _Phase.stepDone)
                      const SizedBox(height: 20),
                    ..._contentBlocks(),
                    if (_phase == _Phase.finished) ...<Widget>[
                      const SizedBox(height: 16),
                      _finishedPanel(),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
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

  Widget _timerPanel() {
    final bool answering = _phase == _Phase.answering;
    final Color ringColor = answering ? const Color(0xFFD1425A) : _color;
    final String caption = switch (_phase) {
      _Phase.prep => '준비 시간',
      _Phase.answering => '● 녹음 중',
      _ => '완료',
    };
    return Column(
      children: <Widget>[
        CountdownRing(
          progress: _phase == _Phase.stepDone ? 0 : _progress,
          label: _phase == _Phase.stepDone
              ? '0:00'
              : formatSeconds(_remainingSeconds),
          caption: caption,
          color: ringColor,
          size: 200,
        ),
        if (_step.hint != null && _phase != _Phase.stepDone) ...<Widget>[
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
                    _step.hint!,
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

  List<Widget> _contentBlocks() {
    final List<Widget> blocks = <Widget>[];
    final ColorScheme scheme = Theme.of(context).colorScheme;

    if (_q.passage != null) {
      blocks.add(_SectionCard(
        title: '읽을 지문',
        color: _color,
        child: SelectableText(
          _q.passage!,
          style: const TextStyle(fontSize: 17, height: 1.75),
        ),
      ));
    }

    if (_q.scene != null) {
      blocks.add(_SectionCard(
        title: '사진 상황',
        color: _color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.place_outlined, size: 18, color: _color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _q.scene!.place,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final String d in _q.scene!.details)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                        d,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ));
    }

    if (_q.table != null) {
      blocks.add(Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: InfoTableView(table: _q.table!, color: _color),
      ));
    }

    // 현재 단계의 질문 (낭독형은 질문이 곧 제목이라 생략)
    if (_q.prompts.isNotEmpty) {
      blocks.add(_SectionCard(
        title: _step.label ?? '질문',
        color: _color,
        highlighted: true,
        child: SelectableText(
          _step.text,
          style: const TextStyle(fontSize: 17, height: 1.6),
        ),
      ));
    }

    if (_phase == _Phase.finished || _phase == _Phase.ready) {
      if (_q.keyExpressions.isNotEmpty) {
        blocks.add(_SectionCard(
          title: '핵심 표현',
          color: _color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final String e in _q.keyExpressions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.chevron_right, size: 18, color: _color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          e,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ));
      }
      if (_q.sampleAnswer != null) {
        blocks.add(_SectionCard(
          title: '모범 답안',
          color: _color,
          child: SelectableText(
            _q.sampleAnswer!,
            style: const TextStyle(fontSize: 15.5, height: 1.7),
          ),
        ));
      }
    }

    return blocks;
  }

  Widget _finishedPanel() {
    if (_sessionAttempts.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      title: '이번 연습 녹음',
      color: _color,
      child: Column(
        children: <Widget>[
          for (final Attempt a in _sessionAttempts)
            AttemptTile(
              attempt: a,
              onDeleted: () => setState(
                () => _sessionAttempts.removeWhere((Attempt x) => x.id == a.id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _controls() {
    switch (_phase) {
      case _Phase.ready:
        return FilledButton.icon(
          onPressed: _beginStep,
          style: FilledButton.styleFrom(backgroundColor: _color),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(
            _steps.length > 1 ? '연습 시작 (${_steps.length}문항)' : '연습 시작',
          ),
        );

      case _Phase.prep:
        return Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: _abort,
                child: const Text('그만두기'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => unawaited(_startAnswering()),
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

      case _Phase.stepDone:
        return Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: _abort,
                child: const Text('그만두기'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _nextStep,
                style: FilledButton.styleFrom(backgroundColor: _color),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text('다음 문항 (${_stepIndex + 2}/${_steps.length})'),
              ),
            ),
          ],
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
                style: FilledButton.styleFrom(backgroundColor: _color),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다시 연습하기'),
              ),
            ),
          ],
        );
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.total,
    required this.current,
    required this.color,
    required this.phase,
    required this.part,
  });

  final int total;
  final int current;
  final Color color;
  final _Phase phase;
  final ToeicPart part;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String status = switch (phase) {
      _Phase.ready => '대기 중',
      _Phase.prep => '준비 시간',
      _Phase.answering => '녹음 중',
      _Phase.stepDone => '문항 완료',
      _Phase.finished => '연습 완료',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: <Widget>[
          PartBadge(part: part, dense: true),
          const SizedBox(width: 8),
          Text(
            '${current + 1} / $total',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.color,
    required this.child,
    this.highlighted = false,
  });

  final String title;
  final Color color;
  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? color.withValues(alpha: 0.55)
              : scheme.outlineVariant,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(width: 4, height: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
