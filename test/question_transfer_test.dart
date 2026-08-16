import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:toeic_speaking/models/question.dart';
import 'package:toeic_speaking/models/toeic_part.dart';
import 'package:toeic_speaking/services/question_transfer.dart';

void main() {
  final Uint8List image = Uint8List.fromList(<int>[1, 2, 3, 4]);
  final Uint8List audio = Uint8List.fromList(<int>[9, 8, 7]);

  const Question question = Question(
    id: 'custom_describePicture_1',
    partId: PartId.describePicture,
    title: '내 사진 문항',
    scene: SceneHint(place: '공원', details: <String>['조깅하는 사람']),
    sampleAnswer: 'This picture was taken at a park.',
    keyExpressions: <String>['a park'],
    isCustom: true,
    hasSampleAudio: true,
  );

  group('문항 내보내기 · 가져오기', () {
    test('내보낸 파일을 다시 읽으면 문항과 첨부가 그대로 살아난다', () {
      final String json = QuestionTransfer.encode(
        <QuestionBundle>[
          QuestionBundle(question: question, image: image, audio: audio),
        ],
      );

      final ImportResult result = QuestionTransfer.decode(json);

      expect(result.isFailure, isFalse);
      expect(result.bundles.length, 1);

      final QuestionBundle restored = result.bundles.single;
      expect(restored.question.id, question.id);
      expect(restored.question.title, question.title);
      expect(restored.question.partId, PartId.describePicture);
      expect(restored.question.scene!.place, '공원');
      expect(restored.question.sampleAnswer, question.sampleAnswer);
      expect(restored.question.hasSampleAudio, isTrue);
      expect(restored.image, image);
      expect(restored.audio, audio);
    });

    test('첨부가 없는 문항도 그대로 오간다', () {
      final String json = QuestionTransfer.encode(
        const <QuestionBundle>[
          QuestionBundle(
            question: Question(
              id: 'custom_readAloud_1',
              partId: PartId.readAloud,
              title: '지문만 있는 문항',
              passage: 'Attention, passengers.',
              isCustom: true,
            ),
          ),
        ],
      );

      final ImportResult result = QuestionTransfer.decode(json);

      expect(result.bundles.length, 1);
      expect(result.bundles.single.image, isNull);
      expect(result.bundles.single.audio, isNull);
      expect(result.bundles.single.question.passage, 'Attention, passengers.');
    });

    test('가져온 문항은 항상 내 문항으로 표시된다', () {
      final String json = jsonEncode(<String, dynamic>{
        'app': QuestionTransfer.appTag,
        'version': 1,
        'questions': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'x',
            'partId': 'readAloud',
            'title': 't',
            'isCustom': false,
          },
        ],
      });

      final ImportResult result = QuestionTransfer.decode(json);
      expect(result.bundles.single.question.isCustom, isTrue);
    });

    test('망가진 항목은 건너뛰고 나머지는 살린다', () {
      final String json = jsonEncode(<String, dynamic>{
        'app': QuestionTransfer.appTag,
        'version': 1,
        'questions': <Object>[
          <String, dynamic>{'id': 'ok', 'partId': 'readAloud', 'title': '정상'},
          <String, dynamic>{'id': '파트없음', 'title': '깨짐'},
          '문자열',
        ],
      });

      final ImportResult result = QuestionTransfer.decode(json);
      expect(result.bundles.length, 1);
      expect(result.skipped, 2);
    });

    test('다른 파일이나 깨진 JSON 은 이유와 함께 거부한다', () {
      expect(QuestionTransfer.decode('{bad').isFailure, isTrue);
      expect(QuestionTransfer.decode('[]').isFailure, isTrue);
      expect(
        QuestionTransfer.decode('{"app":"other","questions":[]}').isFailure,
        isTrue,
      );
      expect(
        QuestionTransfer.decode(
          '{"app":"${QuestionTransfer.appTag}","version":99,"questions":[]}',
        ).isFailure,
        isTrue,
      );
    });

    test('파일 이름에 날짜가 들어간다', () {
      expect(
        QuestionTransfer.fileName(DateTime(2026, 8, 5)),
        'toeic-speaking-questions-2026-08-05.json',
      );
    });
  });
}
