import 'package:flutter_test/flutter_test.dart';
import 'package:toeic_speaking/data/curricula.dart';
import 'package:toeic_speaking/models/curriculum.dart';
import 'package:toeic_speaking/models/toeic_part.dart';

void main() {
  group('기본 학습 계획', () {
    test('1주·2주·3주·한 달 네 가지가 있다', () {
      expect(
        kCurricula.map((Curriculum c) => c.totalDays).toList(),
        <int>[7, 14, 21, 28],
      );
    });

    test('계획 id 가 겹치지 않는다', () {
      final Set<String> ids = kCurricula.map((Curriculum c) => c.id).toSet();
      expect(ids.length, kCurricula.length);
    });

    test('날짜가 1부터 빠짐없이 이어진다', () {
      for (final Curriculum c in kCurricula) {
        expect(
          c.days.map((CurriculumDay d) => d.day).toList(),
          List<int>.generate(c.totalDays, (int i) => i + 1),
          reason: '${c.title} 의 날짜가 이어지지 않습니다.',
        );
      }
    });

    test('하루도 빠짐없이 할 일이 있다', () {
      for (final Curriculum c in kCurricula) {
        for (final CurriculumDay d in c.days) {
          expect(
            d.tasks,
            isNotEmpty,
            reason: '${c.title} ${d.day}일째에 할 일이 없습니다.',
          );
          expect(d.focus, isNotEmpty);
        }
      }
    });

    test('계획이 길수록 실전 응시 횟수가 늘어난다', () {
      final List<int> exams =
          kCurricula.map((Curriculum c) => c.examCount).toList();
      for (int i = 1; i < exams.length; i++) {
        expect(
          exams[i],
          greaterThan(exams[i - 1]),
          reason: '${kCurricula[i].title} 의 실전 횟수가 더 적습니다.',
        );
      }
    });

    test('모든 계획이 다섯 파트를 빠짐없이 다룬다', () {
      for (final Curriculum c in kCurricula) {
        final Set<PartId> covered = <PartId>{};
        for (final CurriculumDay d in c.days) {
          for (final CurriculumTask t in d.tasks) {
            if (t.partId != null) covered.add(t.partId!);
          }
        }
        expect(
          covered.length,
          PartId.values.length,
          reason: '${c.title} 이 다루지 않는 파트가 있습니다.',
        );
      }
    });

    test('계획이 길수록 하루 부담이 가벼워진다', () {
      final Curriculum week1 = kCurricula.first;
      final Curriculum month = kCurricula.last;
      expect(week1.averageMinutes, greaterThan(month.averageMinutes));
    });

    test('마지막 날에는 실전 모의고사가 들어 있다', () {
      for (final Curriculum c in kCurricula) {
        final CurriculumDay last = c.days.last;
        expect(
          last.tasks.any((CurriculumTask t) => t.kind == TaskKind.exam),
          isTrue,
          reason: '${c.title} 의 마지막 날에 실전이 없습니다.',
        );
      }
    });
  });

  group('할 일 계산', () {
    test('파트 연습 시간은 실제 시험 시간의 두 배로 잡는다', () {
      // Q1-2 는 준비 45초 + 답변 45초 = 90초.
      const CurriculumTask task = CurriculumTask.part(PartId.readAloud, 2);
      expect(task.estimatedSeconds, 90 * 2 * 2);
    });

    test('Q5-7 은 질문 세 개를 모두 센다', () {
      const CurriculumTask task =
          CurriculumTask.part(PartId.respondQuestions, 1);
      // (3+15) + (3+15) + (3+30) = 69
      expect(task.estimatedSeconds, 69 * 2);
    });

    test('모의고사 한 회는 20분으로 센다', () {
      const CurriculumTask task = CurriculumTask.exam();
      expect(task.estimatedSeconds, 20 * 60);
    });

    test('할 일 종류마다 라벨이 다르다', () {
      expect(
        const CurriculumTask.part(PartId.readAloud, 2).label,
        'Q1-2 문장 읽기 2문항',
      );
      expect(const CurriculumTask.exam().label, '실전 모의고사 1회');
      expect(const CurriculumTask.review('녹음 듣기').label, '녹음 듣기');
    });

    test('하루 문항 수는 모의고사를 11문항으로 센다', () {
      const CurriculumDay day = CurriculumDay(
        day: 1,
        focus: '테스트',
        tasks: <CurriculumTask>[
          CurriculumTask.part(PartId.readAloud, 2),
          CurriculumTask.exam(),
          CurriculumTask.review('복습은 문항 수에 안 들어간다'),
        ],
      );
      expect(day.questionCount, 2 + 11);
    });
  });

  group('진행 상태', () {
    final DateTime start = DateTime(2026, 8, 25);

    CurriculumProgress freshProgress() => CurriculumProgress(
          curriculumId: 'week1',
          startedAt: start,
        );

    test('시작한 날이 1일째다', () {
      expect(freshProgress().dayNumberOn(start), 1);
    });

    test('사흘 뒤는 4일째다', () {
      expect(
        freshProgress().dayNumberOn(DateTime(2026, 8, 28)),
        4,
      );
    });

    test('같은 날 시각이 달라도 날짜 수는 같다', () {
      final CurriculumProgress progress = CurriculumProgress(
        curriculumId: 'week1',
        startedAt: DateTime(2026, 8, 25, 23, 59),
      );
      expect(progress.dayNumberOn(DateTime(2026, 8, 26, 0, 1)), 2);
    });

    test('체크했다 다시 누르면 풀린다', () {
      CurriculumProgress progress = freshProgress();
      expect(progress.isDone('d1t0'), isFalse);

      progress = progress.toggle('d1t0');
      expect(progress.isDone('d1t0'), isTrue);

      progress = progress.toggle('d1t0');
      expect(progress.isDone('d1t0'), isFalse);
    });

    test('하루의 할 일을 모두 체크해야 그날이 끝난 것이다', () {
      const CurriculumDay day = CurriculumDay(
        day: 1,
        focus: '테스트',
        tasks: <CurriculumTask>[
          CurriculumTask.part(PartId.readAloud, 1),
          CurriculumTask.exam(),
        ],
      );

      CurriculumProgress progress = freshProgress();
      expect(progress.isDayDone(day), isFalse);

      progress = progress.toggle(day.taskKey(0));
      expect(progress.isDayDone(day), isFalse);

      progress = progress.toggle(day.taskKey(1));
      expect(progress.isDayDone(day), isTrue);
    });

    test('JSON 왕복 후 진행 상태가 보존된다', () {
      final CurriculumProgress original =
          freshProgress().toggle('d1t0').toggle('d2t1');

      final CurriculumProgress? restored =
          CurriculumProgress.fromJson(original.toJson());

      expect(restored, isNotNull);
      expect(restored!.curriculumId, 'week1');
      expect(restored.startedAt, start);
      expect(restored.doneTaskKeys, <String>{'d1t0', 'd2t1'});
    });

    test('필수 값이 없거나 깨진 JSON 은 null 을 돌려준다', () {
      expect(
        CurriculumProgress.fromMap(<String, dynamic>{'curriculumId': 'week1'}),
        isNull,
      );
      expect(
        CurriculumProgress.fromMap(<String, dynamic>{
          'curriculumId': 'week1',
          'startedAt': '날짜아님',
        }),
        isNull,
      );
      expect(CurriculumProgress.fromJson('{깨짐'), isNull);
    });
  });
}
