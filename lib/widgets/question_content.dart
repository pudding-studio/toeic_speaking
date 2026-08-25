import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/question.dart';
import '../models/toeic_part.dart';
import '../services/question_store.dart';
import 'common.dart';
import 'tts_controls.dart';

/// 문항 화면에 들어가는 내용 블록(지문·사진·표·질문·모범 답안)을 그린다.
///
/// 낱개 연습([PracticeScreen])과 모의고사([ExamScreen])가 같은 화면을 보여 주도록
/// 한곳에 모아 두었다. 무엇을 보여 줄지는 플래그로 조절한다.
class QuestionContent extends StatelessWidget {
  const QuestionContent({
    super.key,
    required this.question,
    required this.step,
    required this.color,
    required this.audioEnabled,
    required this.showAnswers,
    this.showSampleAudio = true,
    this.showTts = true,
  });

  final Question question;

  /// 지금 답해야 하는 단계. 질문 카드에 이 내용이 들어간다.
  final Prompt step;

  final Color color;

  /// 읽어주기·예시 음성 버튼을 누를 수 있는지.
  /// 녹음 중에는 스피커 소리가 마이크로 들어가므로 false 를 넘긴다.
  final bool audioEnabled;

  /// 핵심 표현·모범 답안을 보여 줄지.
  /// 답변 도중에 보이면 읽어 버리게 되므로 시작 전과 끝난 뒤에만 true.
  final bool showAnswers;

  /// 문항에 붙여 둔 예시 음성 카드를 보여 줄지.
  /// 실전 모의고사에서는 답을 먼저 듣게 되므로 끈다.
  final bool showSampleAudio;

  /// 지문 읽어주기 버튼을 보여 줄지.
  /// 실전 모의고사에서는 실제 시험과 같은 조건이어야 하므로 끈다.
  final bool showTts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _blocks(context),
    );
  }

  List<Widget> _blocks(BuildContext context) {
    final List<Widget> blocks = <Widget>[];
    final ColorScheme scheme = Theme.of(context).colorScheme;

    if (showSampleAudio && question.hasSampleAudio) {
      blocks.add(SectionCard(
        title: '예시 음성',
        color: color,
        child: SampleAudioControls(
          questionId: question.id,
          color: color,
          enabled: audioEnabled,
        ),
      ));
    }

    if (question.passage != null) {
      blocks.add(SectionCard(
        title: '읽을 지문',
        color: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SelectableText(
              question.passage!,
              style: const TextStyle(fontSize: 17, height: 1.75),
            ),
            if (showTts) ...<Widget>[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              TtsControls(
                text: question.passage!,
                color: color,
                enabled: audioEnabled,
              ),
            ],
          ],
        ),
      ));
    }

    final Widget? image = _image();
    if (image != null) {
      blocks.add(SectionCard(title: '사진', color: color, child: image));
    }

    // 사진이 있으면 텍스트 장면 설명은 생략한다.
    if (question.scene != null && !_hasImage) {
      blocks.add(SectionCard(
        title: '사진 상황',
        color: color,
        child: _sceneBlock(scheme),
      ));
    }

    if (question.table != null) {
      blocks.add(Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: InfoTableView(table: question.table!, color: color),
      ));
    }

    // 현재 단계의 질문 (낭독형은 질문이 곧 제목이라 생략)
    if (question.prompts.isNotEmpty) {
      blocks.add(SectionCard(
        title: step.label ?? '질문',
        color: color,
        highlighted: true,
        child: SelectableText(
          step.text,
          style: const TextStyle(fontSize: 17, height: 1.6),
        ),
      ));
    }

    if (showAnswers) {
      if (question.keyExpressions.isNotEmpty) {
        blocks.add(SectionCard(
          title: '핵심 표현',
          color: color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final String e in question.keyExpressions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.chevron_right, size: 18, color: color),
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
      if (question.sampleAnswer != null) {
        blocks.add(SectionCard(
          title: '모범 답안',
          color: color,
          child: SelectableText(
            question.sampleAnswer!,
            style: const TextStyle(fontSize: 15.5, height: 1.7),
          ),
        ));
      }
    }

    return blocks;
  }

  /// 기본 문항은 에셋 경로가 있고, 등록한 문항은 브라우저 저장소에 사진이 들어 있다.
  bool get _hasImage =>
      question.imagePath != null ||
      (question.isCustom && question.partId == PartId.describePicture);

  Widget? _image() {
    if (question.imagePath != null) {
      return QuestionImage(question: question);
    }
    if (!_hasImage) return null;
    // 등록한 사진 묘사 문항. 사진을 안 올렸으면 블록 자체를 그리지 않는다.
    return FutureBuilder<Uint8List?>(
      future: QuestionStore.instance.imageOf(question.id),
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AspectRatio(
            aspectRatio: 4 / 3,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snapshot.data == null) return const SizedBox.shrink();
        return QuestionImage(question: question);
      },
    );
  }

  Widget _sceneBlock(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.place_outlined, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.scene!.place,
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
        for (final String d in question.scene!.details)
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
    );
  }
}

/// 제목 줄에 파트 색 막대가 붙은 카드. 문항 화면의 기본 블록이다.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.color,
    required this.child,
    this.highlighted = false,
  });

  final String title;
  final Color color;
  final Widget child;

  /// 지금 답해야 하는 질문처럼 눈에 띄어야 하는 카드.
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
