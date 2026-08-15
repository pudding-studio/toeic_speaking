import 'dart:convert';

import 'toeic_part.dart';

/// 녹음 1건 = 한 문항의 한 단계에 대한 답변.
///
/// 실제 오디오는 [id] 를 키로 IndexedDB 의 별도 스토어에 저장되고,
/// 이 객체에는 목록에 필요한 메타데이터만 담는다.
class Attempt {
  const Attempt({
    required this.id,
    required this.questionId,
    required this.partId,
    required this.stepIndex,
    required this.promptLabel,
    required this.durationSeconds,
    required this.createdAt,
  });

  final String id;
  final String questionId;
  final PartId partId;
  final int stepIndex;
  final String promptLabel;
  final int durationSeconds;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'questionId': questionId,
        'partId': partId.name,
        'stepIndex': stepIndex,
        'promptLabel': promptLabel,
        'durationSeconds': durationSeconds,
        'createdAt': createdAt.toIso8601String(),
      };

  static Attempt? fromMap(Map<String, dynamic> map) {
    final String? id = map['id'] as String?;
    final String? createdAt = map['createdAt'] as String?;
    if (id == null || createdAt == null) return null;

    final String? partName = map['partId'] as String?;
    final PartId partId = PartId.values.firstWhere(
      (PartId p) => p.name == partName,
      orElse: () => PartId.readAloud,
    );

    return Attempt(
      id: id,
      questionId: (map['questionId'] as String?) ?? '',
      partId: partId,
      stepIndex: (map['stepIndex'] as num?)?.toInt() ?? 0,
      promptLabel: (map['promptLabel'] as String?) ?? '',
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  static Attempt? fromJson(String source) {
    try {
      final Object? decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) return null;
      return fromMap(decoded);
    } on FormatException {
      return null;
    }
  }
}
