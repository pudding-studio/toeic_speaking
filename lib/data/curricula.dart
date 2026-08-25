import '../models/curriculum.dart';
import '../models/toeic_part.dart';

// 계획을 짧게 쓰기 위한 별칭.
const PartId _ra = PartId.readAloud; // Q1-2  문장 읽기
const PartId _dp = PartId.describePicture; // Q3-4  사진 묘사
const PartId _rq = PartId.respondQuestions; // Q5-7  듣고 답하기
const PartId _ri = PartId.respondWithInfo; // Q8-10 정보 활용
const PartId _eo = PartId.expressOpinion; // Q11   의견 제시

/// 기본으로 들어 있는 학습 계획.
///
/// 문항 수는 문제 은행에 있는 문항 수보다 많을 수 있습니다. 일부러 그렇게 짰습니다.
/// 스피킹은 같은 문항을 다시 푸는 것이 낭비가 아니라, 두 번째부터 문장이 붙기
/// 시작하는 종목이기 때문입니다. 같은 문항이 다시 나오면 그대로 다시 푸세요.
const List<Curriculum> kCurricula = <Curriculum>[
  _oneWeek,
  _twoWeeks,
  _threeWeeks,
  _oneMonth,
];

// ─────────────────────────── 1주 완성 ───────────────────────────

const Curriculum _oneWeek = Curriculum(
  id: 'week1',
  title: '1주 완성',
  subtitle: '시험이 코앞일 때. 파트별 틀을 하루에 하나씩 만들고 실전 2회로 마무리합니다.',
  forWhom: '시험이 일주일 안으로 남았고, 하루 15분 안팎(실전 날은 25분)을 낼 수 있는 경우',
  days: <CurriculumDay>[
    CurriculumDay(
      day: 1,
      focus: 'Q1-2 낭독으로 입 풀기',
      note: '준비 시간에 눈으로만 읽지 마세요. 반드시 소리 내어 한 번 읽어야 본 답변에서 안 꼬입니다.',
      tasks: <CurriculumTask>[
        CurriculumTask.part(_ra, 3),
        CurriculumTask.part(_dp, 1),
      ],
    ),
    CurriculumDay(
      day: 2,
      focus: 'Q3-4 사진 묘사 틀 만들기',
      note: '장소 → 중심 인물 → 주변 인물 → 배경 → 분위기. 이 순서를 오늘 안에 외우세요.',
      tasks: <CurriculumTask>[
        CurriculumTask.part(_dp, 3),
        CurriculumTask.part(_ra, 1),
      ],
    ),
    CurriculumDay(
      day: 3,
      focus: 'Q5-7 즉답 훈련',
      note: '준비 시간이 3초뿐입니다. 틀린 문장이라도 말하는 편이 침묵보다 훨씬 낫습니다.',
      tasks: <CurriculumTask>[
        CurriculumTask.part(_rq, 3),
      ],
    ),
    CurriculumDay(
      day: 4,
      focus: 'Q8-10 표에서 답 찾기',
      note: '45초 동안 제목·날짜·장소·시간 열부터 보세요. 질문 대부분이 거기서 나옵니다.',
      tasks: <CurriculumTask>[
        CurriculumTask.part(_ri, 2),
        CurriculumTask.part(_rq, 1),
      ],
    ),
    CurriculumDay(
      day: 5,
      focus: 'Q11 의견 60초 채우기',
      note: '의견 → 이유1+예시 → 이유2+예시 → 마무리. 이 틀만 지켜도 60초가 채워집니다.',
      tasks: <CurriculumTask>[
        CurriculumTask.part(_eo, 3),
      ],
    ),
    CurriculumDay(
      day: 6,
      focus: '첫 실전',
      note: '중간에 멈추지 말고 끝까지 가 보세요. 오늘의 목표는 점수가 아니라 완주입니다.',
      tasks: <CurriculumTask>[
        CurriculumTask.exam(),
        CurriculumTask.review('녹음을 처음부터 들으며 가장 약한 파트 하나를 고르세요.'),
      ],
    ),
    CurriculumDay(
      day: 7,
      focus: '마무리 실전',
      note: '시험 전날에는 새 표현을 외우지 마세요. 쓰던 틀을 굳히는 것이 점수에 유리합니다.',
      tasks: <CurriculumTask>[
        CurriculumTask.exam(),
        CurriculumTask.part(_eo, 1),
      ],
    ),
  ],
);

// ─────────────────────────── 2주 완성 ───────────────────────────

const Curriculum _twoWeeks = Curriculum(
  id: 'week2',
  title: '2주 완성',
  subtitle: '1주차에 파트별 기본기, 2주차에 반복과 실전 3회로 감을 올립니다.',
  forWhom: '처음 응시하거나, 파트별로 무엇을 해야 할지부터 정리하고 싶은 경우',
  days: <CurriculumDay>[
    CurriculumDay(
      day: 1,
      focus: 'Q1-2 발음·끊어 읽기',
      note: '쉼표와 마침표에서 확실히 끊고, 나열은 A↗ B↗ C↘ 로 처리하세요.',
      tasks: <CurriculumTask>[CurriculumTask.part(_ra, 2)],
    ),
    CurriculumDay(
      day: 2,
      focus: 'Q3-4 사진 묘사 시작',
      note: '첫 문장은 무조건 장소로: "This picture was taken at ~".',
      tasks: <CurriculumTask>[CurriculumTask.part(_dp, 2)],
    ),
    CurriculumDay(
      day: 3,
      focus: 'Q5-7 즉답 패턴 익히기',
      note: '질문을 그대로 가져와 첫 문장을 만드는 연습을 하세요.',
      tasks: <CurriculumTask>[CurriculumTask.part(_rq, 2)],
    ),
    CurriculumDay(
      day: 4,
      focus: 'Q8-10 표 읽기',
      note:
          '표의 조각을 완전한 문장으로 바꾸세요. "9 A.M. Registration" → "Registration starts at 9 A.M."',
      tasks: <CurriculumTask>[CurriculumTask.part(_ri, 2)],
    ),
    CurriculumDay(
      day: 5,
      focus: 'Q11 의견 구조 잡기',
      note: '준비 45초에 문장을 다 쓰려 하지 말고 키워드만 잡으세요.',
      tasks: <CurriculumTask>[CurriculumTask.part(_eo, 2)],
    ),
    CurriculumDay(
      day: 6,
      focus: '1주차 실전 점검',
      note: '아직 시간이 남았습니다. 못 해도 실망하지 말고 어디서 막히는지만 보세요.',
      tasks: <CurriculumTask>[CurriculumTask.exam()],
    ),
    CurriculumDay(
      day: 7,
      focus: '약한 파트 보강',
      note: '어제 모의고사에서 가장 답답했던 파트를 고르세요. 오늘은 그 파트만 합니다.',
      tasks: <CurriculumTask>[
        CurriculumTask.review('어제 모의고사 녹음을 들으며 3초 이상 멈춘 지점을 세어 보세요.'),
        CurriculumTask.part(_dp, 2),
      ],
    ),
    CurriculumDay(
      day: 8,
      focus: 'Q1-2 속도 조절',
      note: '빨리 읽지 마세요. 시간이 남는 편이 발음이 뭉개지는 것보다 낫습니다.',
      tasks: <CurriculumTask>[
        CurriculumTask.part(_ra, 2),
        CurriculumTask.part(_dp, 1),
      ],
    ),
    CurriculumDay(
      day: 9,
      focus: 'Q3-4 30초 채우기',
      note: '5~7문장이 목표입니다. 모르면 단정하지 말고 "It seems like ~" 로 넘기세요.',
      tasks: <CurriculumTask>[CurriculumTask.part(_dp, 3)],
    ),
    CurriculumDay(
      day: 10,
      focus: 'Q5-7 Q7 집중',
      note: 'Q7은 30초입니다. 이유를 반드시 두 개 붙이세요.',
      tasks: <CurriculumTask>[CurriculumTask.part(_rq, 2)],
    ),
    CurriculumDay(
      day: 11,
      focus: 'Q8-10 정정 표현',
      note: '틀린 정보를 바로잡는 문항은 "Actually, ~" 로 시작합니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_ri, 2)],
    ),
    CurriculumDay(
      day: 12,
      focus: '두 번째 실전',
      note: '1주차보다 나아졌는지 확인하세요. 녹음을 나란히 들어 보면 확실합니다.',
      tasks: <CurriculumTask>[CurriculumTask.exam()],
    ),
    CurriculumDay(
      day: 13,
      focus: '취약 파트 마지막 보강',
      note: '오늘까지만 새로 고칩니다. 내일은 굳히기만 하세요.',
      tasks: <CurriculumTask>[
        CurriculumTask.part(_eo, 2),
        CurriculumTask.part(_rq, 1),
      ],
    ),
    CurriculumDay(
      day: 14,
      focus: '마무리 실전',
      note: '실제 시험 시간대에 맞춰 응시해 보면 더 좋습니다.',
      tasks: <CurriculumTask>[
        CurriculumTask.exam(),
        CurriculumTask.review('잘 나온 답변 하나를 골라 그대로 외워 두세요. 시험장에서 기준점이 됩니다.'),
      ],
    ),
  ],
);

// ─────────────────────────── 3주 완성 ───────────────────────────

const Curriculum _threeWeeks = Curriculum(
  id: 'week3',
  title: '3주 완성',
  subtitle: '파트별로 두 바퀴 돌고 실전 4회. 하루 10분 안팎으로 꾸준히 갑니다.',
  forWhom: '시간을 두고 차근차근 올리고 싶고, 하루 10분 정도씩 꾸준히 할 수 있는 경우',
  days: <CurriculumDay>[
    // 1주차 — 파트 한 바퀴
    CurriculumDay(
      day: 1,
      focus: 'Q1-2 첫 바퀴',
      note: '고유명사·숫자·요일은 읽기 전에 발음을 미리 정해 두세요.',
      tasks: <CurriculumTask>[CurriculumTask.part(_ra, 2)],
    ),
    CurriculumDay(
      day: 2,
      focus: 'Q1-2 억양 다듬기',
      note: '평서문은 끝을 내리고, Yes/No 의문문은 올립니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_ra, 2)],
    ),
    CurriculumDay(
      day: 3,
      focus: 'Q3-4 첫 바퀴',
      note: '사람 수를 먼저 밝히면 문장이 쉽게 이어집니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_dp, 2)],
    ),
    CurriculumDay(
      day: 4,
      focus: 'Q3-4 현재진행형 굳히기',
      note: '기본 시제는 is/are -ing 입니다. 여기서 흔들리면 감점이 큽니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_dp, 2)],
    ),
    CurriculumDay(
      day: 5,
      focus: 'Q5-7 첫 바퀴',
      note: '15초 문항은 2~3문장, 30초 문항은 4~5문장이 적당합니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_rq, 1)],
    ),
    CurriculumDay(
      day: 6,
      focus: 'Q8-10 첫 바퀴',
      note: '시간·요일·이름은 또박또박. 여기서 잘못 읽으면 바로 감점입니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_ri, 1)],
    ),
    CurriculumDay(
      day: 7,
      focus: 'Q11 첫 바퀴',
      note: '개인 경험을 예시로 넣으면 말이 자연스럽게 늘어납니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_eo, 2)],
    ),
    // 2주차 — 실전 한 번 보고 두 번째 바퀴
    CurriculumDay(
      day: 8,
      focus: '중간 점검 실전',
      note: '아직 절반입니다. 결과보다 어느 파트에서 시간이 남고 모자라는지를 보세요.',
      tasks: <CurriculumTask>[CurriculumTask.exam()],
    ),
    CurriculumDay(
      day: 9,
      focus: '실전 복기',
      note: '녹음을 들으며 반복해서 튀어나온 말버릇(um, you know)을 적어 두세요.',
      tasks: <CurriculumTask>[
        CurriculumTask.review('모의고사 11문항을 처음부터 다시 듣고 파트별 점수를 스스로 매겨 보세요.'),
        CurriculumTask.part(_ra, 1),
      ],
    ),
    CurriculumDay(
      day: 10,
      focus: 'Q1-2 두 번째 바퀴',
      note: '전에 녹음한 같은 지문과 비교해 보세요. 확실히 매끄러워졌을 겁니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_ra, 2)],
    ),
    CurriculumDay(
      day: 11,
      focus: 'Q3-4 두 번째 바퀴',
      note: '마무리 문장을 하나 정해 두세요. "Overall, it looks like a busy afternoon."',
      tasks: <CurriculumTask>[CurriculumTask.part(_dp, 2)],
    ),
    CurriculumDay(
      day: 12,
      focus: 'Q5-7 두 번째 바퀴',
      note: '구체적인 숫자와 요일을 넣으세요. 사실이 아니어도 괜찮습니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_rq, 2)],
    ),
    CurriculumDay(
      day: 13,
      focus: 'Q8-10 두 번째 바퀴',
      note: 'Q10은 표의 해당 행을 문장으로 바꿔 읽어 주면 됩니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_ri, 2)],
    ),
    CurriculumDay(
      day: 14,
      focus: 'Q11 두 번째 바퀴',
      note: '막히면 "Let me put it another way," 로 시간을 버는 연습도 해 두세요.',
      tasks: <CurriculumTask>[CurriculumTask.part(_eo, 2)],
    ),
    // 3주차 — 실전 감각
    CurriculumDay(
      day: 15,
      focus: '두 번째 실전',
      note: '이번에는 시간 안에 다 채우는 것을 목표로 하세요.',
      tasks: <CurriculumTask>[CurriculumTask.exam()],
    ),
    CurriculumDay(
      day: 16,
      focus: '약점 집중 (말하기 양)',
      note: '시간을 못 채운 파트를 골라 오늘 몰아서 하세요.',
      tasks: <CurriculumTask>[
        CurriculumTask.part(_dp, 2),
        CurriculumTask.part(_eo, 1),
      ],
    ),
    CurriculumDay(
      day: 17,
      focus: '약점 집중 (즉답 속도)',
      note: '준비 시간을 일부러 건너뛰고 바로 답해 보세요. 실전에서 여유가 생깁니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_rq, 2)],
    ),
    CurriculumDay(
      day: 18,
      focus: '세 번째 실전',
      note: '이제 완주가 아니라 내용으로 승부하세요.',
      tasks: <CurriculumTask>[CurriculumTask.exam()],
    ),
    CurriculumDay(
      day: 19,
      focus: '표현 굳히기',
      note: '파트별 공략법의 템플릿 문장을 소리 내어 읽어 두세요.',
      tasks: <CurriculumTask>[
        CurriculumTask.part(_ra, 1),
        CurriculumTask.part(_ri, 1),
      ],
    ),
    CurriculumDay(
      day: 20,
      focus: '마지막 점검',
      note: '오늘까지만 고칩니다. 내일은 새로 하지 말고 하던 대로 하세요.',
      tasks: <CurriculumTask>[
        CurriculumTask.part(_eo, 1),
        CurriculumTask.part(_dp, 1),
      ],
    ),
    CurriculumDay(
      day: 21,
      focus: '마무리 실전',
      note: '실제 시험처럼 조용한 곳에서 한 번에 끝까지.',
      tasks: <CurriculumTask>[
        CurriculumTask.exam(),
        CurriculumTask.review('3주 전 첫 녹음과 오늘 녹음을 나란히 들어 보세요.'),
      ],
    ),
  ],
);

// ─────────────────────────── 한 달 완성 ───────────────────────────

const Curriculum _oneMonth = Curriculum(
  id: 'month1',
  title: '한 달 완성',
  subtitle: '기초 → 표현 → 실전 → 마무리 4주 사이클. 실전 5회로 가장 촘촘합니다.',
  forWhom:
      '점수를 확실히 올리고 싶고, 4주를 통째로 쓸 수 있는 경우. 하루 부담은 3주와 비슷하지만 전체 분량과 실전 횟수가 가장 많습니다',
  days: <CurriculumDay>[
    // 1주차 — 기초 다지기
    CurriculumDay(
      day: 1,
      focus: '시험 구조 파악',
      note: '전체 탭에서 파트별 시간을 먼저 훑어보세요. 무엇을 준비할지가 정해집니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_ra, 2)],
    ),
    CurriculumDay(
      day: 2,
      focus: 'Q1-2 발음 기초',
      note: '읽어주기 기능으로 원어민 발음을 먼저 들어 보고 따라 읽으세요.',
      tasks: <CurriculumTask>[CurriculumTask.part(_ra, 2)],
    ),
    CurriculumDay(
      day: 3,
      focus: 'Q3-4 기초',
      note: '가장 눈에 띄는 인물부터 묘사하세요.',
      tasks: <CurriculumTask>[CurriculumTask.part(_dp, 2)],
    ),
    CurriculumDay(
      day: 4,
      focus: 'Q3-4 어휘 늘리기',
      note: '자주 쓰는 장소 어휘(office, café, park)를 정리해 두세요.',
      tasks: <CurriculumTask>[CurriculumTask.part(_dp, 2)],
    ),
    CurriculumDay(
      day: 5,
      focus: 'Q5-7 기초',
      note: '문법보다 끊기지 않는 것이 우선입니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_rq, 1)],
    ),
    CurriculumDay(
      day: 6,
      focus: 'Q8-10 기초',
      note: '표를 읽는 45초를 재 보세요. 생각보다 짧습니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_ri, 1)],
    ),
    CurriculumDay(
      day: 7,
      focus: 'Q11 기초 + 1주차 마무리',
      note: '첫 주는 여기까지. 완벽하지 않아도 됩니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_eo, 2)],
    ),
    // 2주차 — 표현 굳히기
    CurriculumDay(
      day: 8,
      focus: '첫 실전 (현재 위치 확인)',
      note: '지금 실력을 기록해 두는 것이 목적입니다. 점수는 신경 쓰지 마세요.',
      tasks: <CurriculumTask>[CurriculumTask.exam()],
    ),
    CurriculumDay(
      day: 9,
      focus: '실전 복기',
      note: '파트별로 무엇이 부족했는지 한 줄씩 적어 두세요.',
      tasks: <CurriculumTask>[
        CurriculumTask.review('모의고사 녹음을 들으며 파트별로 부족한 점을 한 줄씩 적어 보세요.'),
        CurriculumTask.part(_ra, 1),
      ],
    ),
    CurriculumDay(
      day: 10,
      focus: 'Q1-2 템플릿 고정',
      note: '"Attention, passengers." 같은 도입부는 입에 붙을 때까지 반복하세요.',
      tasks: <CurriculumTask>[CurriculumTask.part(_ra, 2)],
    ),
    CurriculumDay(
      day: 11,
      focus: 'Q3-4 템플릿 고정',
      note: '다섯 문장 틀을 그대로 쓰면 30초가 채워집니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_dp, 2)],
    ),
    CurriculumDay(
      day: 12,
      focus: 'Q5-7 템플릿 고정',
      note: '"I usually ~ once or twice a week." 같은 문장을 통째로 외워 두세요.',
      tasks: <CurriculumTask>[CurriculumTask.part(_rq, 2)],
    ),
    CurriculumDay(
      day: 13,
      focus: 'Q8-10 템플릿 고정',
      note: '"Sure, I can help you with that." 로 시작하면 첫 3초를 벌 수 있습니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_ri, 2)],
    ),
    CurriculumDay(
      day: 14,
      focus: 'Q11 템플릿 고정',
      note: '찬성·반대 양쪽 도입 문장을 다 준비해 두세요.',
      tasks: <CurriculumTask>[CurriculumTask.part(_eo, 2)],
    ),
    // 3주차 — 실전 감각
    CurriculumDay(
      day: 15,
      focus: '두 번째 실전',
      note: '템플릿이 실제로 나오는지 확인하세요.',
      tasks: <CurriculumTask>[CurriculumTask.exam()],
    ),
    CurriculumDay(
      day: 16,
      focus: '시간 채우기 훈련',
      note: '남은 시간에 억지로라도 한 문장 더 붙이는 연습입니다.',
      tasks: <CurriculumTask>[
        CurriculumTask.part(_dp, 2),
        CurriculumTask.part(_eo, 1),
      ],
    ),
    CurriculumDay(
      day: 17,
      focus: '즉답 속도 훈련',
      note: '준비 시간을 건너뛰고 바로 답해 보세요.',
      tasks: <CurriculumTask>[CurriculumTask.part(_rq, 2)],
    ),
    CurriculumDay(
      day: 18,
      focus: '정확도 훈련',
      note: '오늘은 빠르게 말고 정확하게. 시제와 단수·복수를 신경 쓰세요.',
      tasks: <CurriculumTask>[
        CurriculumTask.part(_ri, 2),
        CurriculumTask.part(_ra, 1),
      ],
    ),
    CurriculumDay(
      day: 19,
      focus: '세 번째 실전',
      note: '이번에는 11문항 모두 시간을 채우는 것이 목표입니다.',
      tasks: <CurriculumTask>[CurriculumTask.exam()],
    ),
    CurriculumDay(
      day: 20,
      focus: '약점 몰아치기',
      note: '세 번의 모의고사에서 계속 걸린 파트를 고르세요.',
      tasks: <CurriculumTask>[
        CurriculumTask.part(_eo, 2),
        CurriculumTask.part(_dp, 1),
      ],
    ),
    CurriculumDay(
      day: 21,
      focus: '3주차 마무리',
      note: '이번 주 녹음 중 가장 잘 나온 것을 골라 다시 들어 보세요.',
      tasks: <CurriculumTask>[
        CurriculumTask.review('이번 주 녹음 중 가장 잘한 답변을 하나 골라 그대로 받아써 보세요.'),
        CurriculumTask.part(_rq, 1),
      ],
    ),
    // 4주차 — 마무리 점검
    CurriculumDay(
      day: 22,
      focus: 'Q1-2 마지막 점검',
      note: '이제 새 지문보다 이미 한 지문을 더 매끄럽게 만드는 편이 낫습니다.',
      tasks: <CurriculumTask>[CurriculumTask.part(_ra, 2)],
    ),
    CurriculumDay(
      day: 23,
      focus: 'Q3-4 마지막 점검',
      note: '어떤 사진이 나와도 같은 순서로 말할 수 있는지 확인하세요.',
      tasks: <CurriculumTask>[CurriculumTask.part(_dp, 2)],
    ),
    CurriculumDay(
      day: 24,
      focus: 'Q5-7·Q8-10 마지막 점검',
      note: '두 파트를 이어서 하면 실제 시험 흐름과 비슷해집니다.',
      tasks: <CurriculumTask>[
        CurriculumTask.part(_rq, 1),
        CurriculumTask.part(_ri, 1),
      ],
    ),
    CurriculumDay(
      day: 25,
      focus: '네 번째 실전',
      note: '실제 시험 시간대에 맞춰 응시해 보세요.',
      tasks: <CurriculumTask>[CurriculumTask.exam()],
    ),
    CurriculumDay(
      day: 26,
      focus: 'Q11 마지막 점검',
      note: '어떤 주제가 나와도 쓸 수 있는 이유 두 개를 준비해 두세요(시간·비용·경험).',
      tasks: <CurriculumTask>[CurriculumTask.part(_eo, 2)],
    ),
    CurriculumDay(
      day: 27,
      focus: '가볍게 몸풀기',
      note: '시험 전날입니다. 새로 외우지 말고 하던 것만 짧게 확인하세요.',
      tasks: <CurriculumTask>[
        CurriculumTask.part(_ra, 1),
        CurriculumTask.part(_dp, 1),
      ],
    ),
    CurriculumDay(
      day: 28,
      focus: '마무리 실전',
      note: '한 달 전 첫 녹음과 비교해 보세요. 차이가 확실할 겁니다.',
      tasks: <CurriculumTask>[
        CurriculumTask.exam(),
        CurriculumTask.review('첫날 녹음과 오늘 녹음을 나란히 들어 보세요.'),
      ],
    ),
  ],
);
