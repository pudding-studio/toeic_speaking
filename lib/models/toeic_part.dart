/// TOEIC Speaking 시험의 파트 구분 (2021년 개정 기준, 총 11문항)
enum PartId {
  readAloud, // Q1-2  문장 읽기
  describePicture, // Q3-4  사진 묘사
  respondQuestions, // Q5-7  듣고 질문에 답하기
  respondWithInfo, // Q8-10 제공된 정보를 사용해 답하기
  expressOpinion, // Q11   의견 제시하기
}

class ToeicPart {
  const ToeicPart({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.questionRange,
    required this.englishTitle,
    required this.description,
    required this.defaultPrepSeconds,
    required this.defaultAnswerSeconds,
    required this.tips,
    required this.templates,
  });

  final PartId id;

  /// 탭에 표시되는 이름. 예) "Q1-2 문장 읽기"
  final String title;

  /// 좁은 공간(카드 배지 등)에서 쓰는 이름. 예) "문장 읽기"
  final String shortTitle;

  /// 예) "Q1-2"
  final String questionRange;

  final String englishTitle;
  final String description;

  /// 문항이 자체 값을 지정하지 않을 때 쓰는 기본 준비 시간(초).
  final int defaultPrepSeconds;

  /// 문항이 자체 값을 지정하지 않을 때 쓰는 기본 답변 시간(초).
  final int defaultAnswerSeconds;

  /// 채점 포인트 / 공략법.
  final List<String> tips;

  /// 바로 써먹는 답변 템플릿 문장.
  final List<String> templates;

  /// 탭 헤더에 쓰는 라벨.
  String get tabLabel => '$questionRange $shortTitle';
}

const List<ToeicPart> kToeicParts = <ToeicPart>[
  ToeicPart(
    id: PartId.readAloud,
    title: 'Q1-2 문장 읽기',
    shortTitle: '문장 읽기',
    questionRange: 'Q1-2',
    englishTitle: 'Read a text aloud',
    description:
        '안내 방송, 광고, 뉴스 같은 짧은 지문을 소리 내어 읽습니다. 내용 이해보다 발음·강세·억양·끊어 읽기가 점수를 좌우합니다.',
    defaultPrepSeconds: 45,
    defaultAnswerSeconds: 45,
    tips: <String>[
      '준비 시간에 반드시 입으로 소리 내어 한 번 읽어 보세요. 눈으로만 읽으면 발음이 꼬입니다.',
      '쉼표·마침표에서 확실히 끊고, 의미 단위(주어 / 동사 / 목적어)로 호흡을 나눕니다.',
      '고유명사, 숫자, 요일, 시간 표현은 미리 발음을 정해 두세요.',
      '나열(A, B, and C)은 A↗ B↗ C↘ 로 억양을 처리합니다.',
      '평서문은 끝을 내리고, Yes/No 의문문은 끝을 올립니다.',
      '너무 빨리 읽지 마세요. 시간이 남는 편이 발음이 뭉개지는 것보다 낫습니다.',
    ],
    templates: <String>[
      'Attention, passengers. / Attention, shoppers. — 안내문의 전형적인 도입부',
      'Thank you for calling ~ / We are pleased to announce ~',
      'For more information, please visit our website at ~',
    ],
  ),
  ToeicPart(
    id: PartId.describePicture,
    title: 'Q3-4 사진 묘사',
    shortTitle: '사진 묘사',
    questionRange: 'Q3-4',
    englishTitle: 'Describe a picture',
    description:
        '한 장의 사진을 30초 동안 묘사합니다. 장소 → 중심 인물 → 주변 인물 → 배경 순서로 말하면 안정적입니다.',
    defaultPrepSeconds: 45,
    defaultAnswerSeconds: 30,
    tips: <String>[
      '첫 문장은 항상 장소로 시작: "This picture was taken at/in ~".',
      '가장 눈에 띄는 인물부터 묘사하고, 현재진행형(is/are -ing)을 기본으로 씁니다.',
      '사람 수를 먼저 밝히면 문장이 쉽게 이어집니다: "There are about four people."',
      '30초를 다 채우는 것이 중요합니다. 5~7문장을 목표로 하세요.',
      '확실하지 않으면 단정하지 말고 추측 표현을 쓰세요: "It seems like ~", "I think ~".',
      '마지막은 분위기로 마무리: "Overall, it looks like a busy afternoon."',
    ],
    templates: <String>[
      'This picture was taken at [장소].',
      'The most noticeable thing is [중심 대상].',
      'On the left/right side, [사람] is [동작]-ing.',
      'In the background, I can see [배경 사물].',
      'Overall, it looks like a [형용사] place.',
    ],
  ),
  ToeicPart(
    id: PartId.respondQuestions,
    title: 'Q5-7 듣고 답하기',
    shortTitle: '듣고 답하기',
    questionRange: 'Q5-7',
    englishTitle: 'Respond to questions',
    description:
        '전화 인터뷰 상황에서 세 개의 질문에 답합니다. 준비 시간이 3초뿐이므로 즉답 패턴을 외워 두는 것이 핵심입니다.',
    defaultPrepSeconds: 3,
    defaultAnswerSeconds: 15,
    tips: <String>[
      '문법 정확성보다 "끊기지 않고 답하기"가 우선입니다. 침묵이 가장 큰 감점입니다.',
      'Q5·Q6은 15초, Q7은 30초입니다. Q7은 반드시 이유 두 가지를 붙이세요.',
      '질문을 그대로 활용해 첫 문장을 만듭니다. (질문 재활용 전략)',
      '구체적인 숫자·요일·장소를 넣으면 내용 점수가 올라갑니다. 사실이 아니어도 괜찮습니다.',
      '15초 문항은 2~3문장, 30초 문항은 4~5문장이 적당합니다.',
    ],
    templates: <String>[
      'The last time I [동사]-ed was about two weeks ago.',
      'I usually [동사] once or twice a week.',
      'I would say [답] because [이유]. Also, [추가 이유].',
      'Actually, I have never [p.p.], but I would like to try it someday.',
    ],
  ),
  ToeicPart(
    id: PartId.respondWithInfo,
    title: 'Q8-10 정보 활용',
    shortTitle: '정보 활용',
    questionRange: 'Q8-10',
    englishTitle: 'Respond to questions using information provided',
    description: '일정표·이력서·행사 안내문 등 표를 45초 동안 읽고, 이를 근거로 세 개의 질문에 답합니다.',
    defaultPrepSeconds: 45,
    defaultAnswerSeconds: 15,
    tips: <String>[
      '45초 동안 제목, 날짜, 장소, 시간 열을 먼저 확인하세요. 질문 대부분이 여기서 나옵니다.',
      'Q10은 보통 "정보 두세 개를 나열해 달라"는 요청입니다. 표에서 해당 행을 그대로 읽어 주면 됩니다.',
      '표의 표현을 완전한 문장으로 바꿔 말하세요: "9 A.M. Registration" → "Registration starts at 9 A.M."',
      '틀린 정보를 정정해 주는 문항에서는 "Actually, ~" 로 시작합니다.',
      '시간·요일·이름은 또박또박 발음합니다. 여기서 잘못 읽으면 바로 감점입니다.',
    ],
    templates: <String>[
      'Sure, I can help you with that. / Let me check the schedule for you.',
      'The session will be held on [날짜] at [장소].',
      'Actually, that information is not correct. It has been changed to ~',
      'There are two sessions scheduled. First, ~ Second, ~',
    ],
  ),
  ToeicPart(
    id: PartId.expressOpinion,
    title: 'Q11 의견 제시',
    shortTitle: '의견 제시',
    questionRange: 'Q11',
    englishTitle: 'Express an opinion',
    description:
        '찬반 또는 선택형 주제에 대해 60초 동안 자신의 의견을 말합니다. 서론-본론-결론 구조가 그대로 점수입니다.',
    defaultPrepSeconds: 45,
    defaultAnswerSeconds: 60,
    tips: <String>[
      '구조를 고정하세요: 의견 → 이유 1 + 예시 → 이유 2 + 예시 → 마무리.',
      '준비 45초에는 문장을 다 쓰려 하지 말고 키워드만 잡으세요.',
      '개인 경험을 예시로 넣으면 말이 자연스럽게 늘어납니다: "For example, when I was in college, ~".',
      '60초를 채우지 못하면 감점입니다. 이유 하나당 3문장을 목표로 하세요.',
      '중간에 막히면 "Let me put it another way," 같은 연결어로 시간을 버세요.',
    ],
    templates: <String>[
      'I agree/disagree with the idea that ~ for a couple of reasons.',
      'First of all, [이유 1]. For example, [경험].',
      'On top of that, [이유 2]. That is why ~',
      'For these reasons, I believe that ~',
    ],
  ),
];

ToeicPart partById(PartId id) =>
    kToeicParts.firstWhere((ToeicPart p) => p.id == id);
