import 'dart:convert';
import 'dart:typed_data';

import '../models/question.dart';

/// 문항 하나와 거기 딸린 사진·예시 음성.
class QuestionBundle {
  const QuestionBundle({required this.question, this.image, this.audio});

  final Question question;
  final Uint8List? image;
  final Uint8List? audio;
}

/// 가져오기 결과. 읽지 못한 항목은 [skipped] 로 센다.
class ImportResult {
  const ImportResult({
    required this.bundles,
    this.skipped = 0,
    this.error,
  });

  const ImportResult.failure(String message)
      : bundles = const <QuestionBundle>[],
        skipped = 0,
        error = message;

  final List<QuestionBundle> bundles;
  final int skipped;

  /// 파일 자체를 읽지 못한 경우의 이유. 성공하면 null.
  final String? error;

  bool get isFailure => error != null;
  bool get isEmpty => bundles.isEmpty;
}

/// 등록한 문항을 파일 하나로 주고받기 위한 형식.
///
/// 사진과 예시 음성은 base64 로 같이 담아서, 파일 하나만 옮기면 그대로 복원된다.
class QuestionTransfer {
  const QuestionTransfer._();

  static const String appTag = 'toeic_speaking';
  static const int formatVersion = 1;

  /// 내보낼 JSON 문자열을 만든다.
  static String encode(
    List<QuestionBundle> bundles, {
    DateTime? exportedAt,
  }) {
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'app': appTag,
      'version': formatVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
      'questions': bundles.map((QuestionBundle b) {
        return <String, dynamic>{
          ...b.question.toMap(),
          if (b.image != null) 'imageBase64': base64Encode(b.image!),
          if (b.audio != null) 'audioBase64': base64Encode(b.audio!),
        };
      }).toList(),
    });
  }

  /// 가져온 JSON 을 해석한다. 형식이 아니면 [ImportResult.isFailure] 가 true.
  static ImportResult decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      return const ImportResult.failure(
          'JSON 형식이 아닙니다. 내보내기로 만든 파일인지 확인해 주세요.');
    }

    if (decoded is! Map<String, dynamic>) {
      return const ImportResult.failure('문항 파일 형식이 아닙니다.');
    }
    if (decoded['app'] != appTag) {
      return const ImportResult.failure('이 앱에서 내보낸 파일이 아닙니다.');
    }

    final int version = (decoded['version'] as num?)?.toInt() ?? 0;
    if (version > formatVersion) {
      return const ImportResult.failure(
        '더 새로운 버전에서 만든 파일입니다. 앱을 새로고침한 뒤 다시 시도해 주세요.',
      );
    }

    final Object? rawQuestions = decoded['questions'];
    if (rawQuestions is! List) {
      return const ImportResult.failure('문항 목록이 없습니다.');
    }

    final List<QuestionBundle> bundles = <QuestionBundle>[];
    int skipped = 0;

    for (final Object? raw in rawQuestions) {
      if (raw is! Map<String, dynamic>) {
        skipped++;
        continue;
      }
      // 가져온 문항은 언제나 "내 문항"으로 다룬다.
      final Question? question = Question.fromMap(<String, dynamic>{
        ...raw,
        'isCustom': true,
      });
      if (question == null) {
        skipped++;
        continue;
      }
      bundles.add(
        QuestionBundle(
          question: question,
          image: _decodeBytes(raw['imageBase64']),
          audio: _decodeBytes(raw['audioBase64']),
        ),
      );
    }

    return ImportResult(bundles: bundles, skipped: skipped);
  }

  static Uint8List? _decodeBytes(Object? value) {
    if (value is! String || value.isEmpty) return null;
    try {
      return base64Decode(value);
    } on FormatException {
      return null;
    }
  }

  /// 내보내기 파일 이름. 예) toeic-speaking-문항-2026-08-15.json
  static String fileName(DateTime now) {
    final String date = '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return 'toeic-speaking-questions-$date.json';
  }
}
