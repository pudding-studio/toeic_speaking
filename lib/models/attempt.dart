import 'dart:convert';

import 'toeic_part.dart';

/// 녹음 1건 = 한 문항의 한 단계에 대한 답변.
class Attempt {
  const Attempt({
    required this.id,
    required this.questionId,
    required this.partId,
    required this.stepIndex,
    required this.promptLabel,
    required this.filePath,
    required this.durationSeconds,
    required this.createdAt,
  });

  final String id;
  final String questionId;
  final PartId partId;
  final int stepIndex;
  final String promptLabel;
  final String filePath;
  final int durationSeconds;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'questionId': questionId,
        'partId': partId.name,
        'stepIndex': stepIndex,
        'promptLabel': promptLabel,
        'filePath': filePath,
        'durationSeconds': durationSeconds,
        'createdAt': createdAt.toIso8601String(),
      };

  static Attempt? fromMap(Map<String, dynamic> map) {
    final String? partName = map['partId'] as String?;
    final PartId partId = PartId.values.firstWhere(
      (PartId p) => p.name == partName,
      orElse: () => PartId.readAloud,
    );
    final String? path = map['filePath'] as String?;
    final String? createdAt = map['createdAt'] as String?;
    if (path == null || createdAt == null) return null;
    return Attempt(
      id: (map['id'] as String?) ?? createdAt,
      questionId: (map['questionId'] as String?) ?? '',
      partId: partId,
      stepIndex: (map['stepIndex'] as num?)?.toInt() ?? 0,
      promptLabel: (map['promptLabel'] as String?) ?? '',
      filePath: path,
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
