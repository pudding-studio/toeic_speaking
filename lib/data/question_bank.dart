import '../models/question.dart';
import '../models/toeic_part.dart';

/// 파트별 연습 문항 모음.
const List<Question> kQuestions = <Question>[
  // ─────────────────────────── Q1-2 문장 읽기 ───────────────────────────
  Question(
    id: 'ra_01',
    partId: PartId.readAloud,
    title: '공항 탑승 안내 방송',
    passage:
        'Attention, passengers. Flight seven-two-four to Vancouver will begin '
        'boarding in approximately fifteen minutes at gate twelve. Passengers '
        'traveling with small children, or those who need special assistance, '
        'may board at any time. Please have your boarding pass and '
        'identification ready, and make sure all carry-on items fit in the '
        'overhead compartment. Thank you for flying with us.',
    keyExpressions: <String>[
      'Attention, passengers. — 첫 문장은 또박또박, 끝을 내려서',
      'seven-two-four — 편명은 숫자를 하나씩',
      'approximately — /əˈprɑːksɪmətli/ 강세는 -prox-',
      'boarding pass and identification — and 앞에서 살짝 끊기',
    ],
  ),
  Question(
    id: 'ra_02',
    partId: PartId.readAloud,
    title: '지역 서점 광고',
    passage: 'Are you looking for the perfect gift? Visit Riverside Books this '
        'weekend for our annual autumn sale. You will find bestsellers, '
        'children\'s books, and rare collections, all at up to forty percent '
        'off. Our staff will be happy to help you find exactly what you need. '
        'Riverside Books is located on Maple Street, right across from the '
        'city library, and we are open until nine every evening.',
    keyExpressions: <String>[
      'Are you looking for ~? — 의문문이므로 끝을 올려서',
      'bestsellers, children\'s books, and rare collections — 나열은 ↗ ↗ ↘',
      'forty percent — forty(f-) 와 fourteen 구분해서 발음',
      'right across from — 연음 주의',
    ],
  ),
  Question(
    id: 'ra_03',
    partId: PartId.readAloud,
    title: '라디오 교통 정보',
    passage: 'Good morning, and thanks for tuning in to your morning traffic '
        'update. Due to ongoing construction, the northbound lanes of Highway '
        'nine are moving very slowly this morning. Drivers heading downtown '
        'should expect delays of up to thirty minutes. If possible, consider '
        'taking Fifth Avenue instead. We will bring you another update at the '
        'top of the hour.',
    keyExpressions: <String>[
      'thanks for tuning in — 연음으로 부드럽게',
      'Due to ongoing construction, — 콤마에서 확실히 끊기',
      'northbound / downtown — th 와 ow 발음 주의',
      'delays of up to thirty minutes — thirty 와 thirteen 구분',
    ],
  ),
  Question(
    id: 'ra_04',
    partId: PartId.readAloud,
    title: '사내 공지 (엘리베이터 점검)',
    passage:
        'Good afternoon, everyone. Please be advised that the elevators in the '
        'east wing will be inspected on Thursday, March third. During the '
        'inspection, which will last from nine A.M. to one P.M., only the '
        'stairways and the west elevators will be available. We apologize for '
        'any inconvenience, and we appreciate your cooperation.',
    keyExpressions: <String>[
      'Please be advised that ~ — 공지문의 대표 표현',
      'Thursday, March third — 날짜는 천천히',
      'from nine A.M. to one P.M. — from ~ to ~ 를 한 덩어리로',
      'inconvenience — 강세는 -ven-',
    ],
  ),

  // ─────────────────────────── Q3-4 사진 묘사 ───────────────────────────
  Question(
    id: 'dp_01',
    partId: PartId.describePicture,
    title: '야외 카페 테라스',
    scene: SceneHint(
      place: '건물 앞 야외 카페 테라스, 맑은 낮',
      details: <String>[
        '앞쪽 테이블에 두 사람이 마주 앉아 대화 중',
        '한 사람은 노트북을 보고 있고, 컵이 테이블 위에 놓여 있음',
        '왼쪽에서 점원이 쟁반을 들고 걸어오는 중',
        '테이블마다 파라솔이 펼쳐져 있음',
        '배경에는 자전거 몇 대와 가로수가 보임',
      ],
    ),
    keyExpressions: <String>[
      'This picture was taken at an outdoor cafe.',
      'A man and a woman are sitting across from each other.',
      'A server is carrying a tray toward the table.',
      'There are large umbrellas over the tables.',
      'In the background, I can see some bicycles parked along the street.',
    ],
    sampleAnswer:
        'This picture was taken at an outdoor cafe on a sunny day. There are '
        'about four or five people in this picture. The most noticeable thing '
        'is two people sitting across from each other at a table in the front. '
        'One of them is looking at a laptop, and there are some cups on the '
        'table. On the left side, a server is carrying a tray toward them. '
        'Large umbrellas are set up over each table. In the background, I can '
        'see several bicycles and some trees along the street. Overall, it '
        'looks like a relaxing afternoon.',
  ),
  Question(
    id: 'dp_02',
    partId: PartId.describePicture,
    title: '회의실 발표 장면',
    scene: SceneHint(
      place: '실내 회의실',
      details: <String>[
        '한 여성이 화면 앞에 서서 발표하고 있음',
        '긴 테이블에 네다섯 명이 앉아 있음',
        '몇몇은 노트에 필기 중, 한 명은 손을 들고 있음',
        '테이블 위에 서류와 물컵이 놓여 있음',
        '벽면에 큰 창문이 있고 밖이 밝음',
      ],
    ),
    keyExpressions: <String>[
      'This picture was taken in a meeting room.',
      'A woman is giving a presentation in front of a screen.',
      'Some of them are taking notes.',
      'One man is raising his hand to ask a question.',
      'There are documents and glasses of water on the table.',
    ],
    sampleAnswer:
        'This picture was taken in a meeting room at an office. I can see about '
        'six people in this picture. In the center, a woman is standing in '
        'front of a large screen, and she seems to be giving a presentation. '
        'Around the long table, five people are sitting and listening to her. '
        'Some of them are taking notes, and one man is raising his hand, '
        'probably to ask a question. On the table, there are documents and '
        'glasses of water. Through the windows on the wall, I can see it is '
        'bright outside. Overall, the atmosphere looks serious but friendly.',
  ),
  Question(
    id: 'dp_03',
    partId: PartId.describePicture,
    title: '공원 산책로',
    scene: SceneHint(
      place: '도심 공원의 산책로, 늦은 오후',
      details: <String>[
        '가운데 길에서 두 사람이 조깅하고 있음',
        '오른쪽 벤치에 노인이 앉아 신문을 읽는 중',
        '왼쪽 잔디밭에서 아이가 개와 놀고 있음',
        '길 양쪽에 큰 나무들이 늘어서 있음',
        '멀리 고층 건물들이 보임',
      ],
    ),
    keyExpressions: <String>[
      'This picture was taken at a park.',
      'Two people are jogging along the path.',
      'An elderly man is sitting on a bench, reading a newspaper.',
      'A child is playing with a dog on the grass.',
      'I can see tall buildings in the distance.',
    ],
  ),
  Question(
    id: 'dp_04',
    partId: PartId.describePicture,
    title: '슈퍼마켓 계산대',
    scene: SceneHint(
      place: '대형 마트 계산대 구역',
      details: <String>[
        '계산원이 물건을 스캔하고 있음',
        '손님이 카트를 밀며 기다리고 있음',
        '뒤로 두세 명이 줄을 서 있음',
        '선반에 물건이 가득 진열되어 있음',
        '천장에 안내 표지판이 걸려 있음',
      ],
    ),
    keyExpressions: <String>[
      'This picture was taken at a supermarket.',
      'A cashier is scanning items at the counter.',
      'A customer is waiting with a shopping cart.',
      'A few people are standing in line behind her.',
      'The shelves are full of products.',
    ],
  ),

  // ─────────────────────── Q5-7 듣고 질문에 답하기 ───────────────────────
  Question(
    id: 'rq_01',
    partId: PartId.respondQuestions,
    title: '독서 습관에 대한 전화 인터뷰',
    prompts: <Prompt>[
      Prompt(
        label: 'Question 5',
        text: 'When was the last time you read a book, and what was it about?',
        prepSeconds: 3,
        answerSeconds: 15,
        hint: '시점 + 책 주제 한 문장. "The last time I read a book was ~"',
      ),
      Prompt(
        label: 'Question 6',
        text: 'Do you prefer paper books or e-books? Why?',
        prepSeconds: 3,
        answerSeconds: 15,
        hint: '선택 + 이유 하나면 충분합니다.',
      ),
      Prompt(
        label: 'Question 7',
        text: 'What are some advantages of reading books instead of watching '
            'videos? Give two reasons.',
        prepSeconds: 3,
        answerSeconds: 30,
        hint: '이유 두 개 + 각각 짧은 부연. First of all ~ / On top of that ~',
      ),
    ],
    keyExpressions: <String>[
      'The last time I read a book was about two weeks ago.',
      'I prefer e-books because they are easier to carry.',
      'First of all, reading helps me focus better.',
      'On top of that, I can read at my own pace.',
    ],
  ),
  Question(
    id: 'rq_02',
    partId: PartId.respondQuestions,
    title: '대중교통 이용에 대한 설문',
    prompts: <Prompt>[
      Prompt(
        label: 'Question 5',
        text: 'How do you usually get to work or school?',
        prepSeconds: 3,
        answerSeconds: 15,
      ),
      Prompt(
        label: 'Question 6',
        text: 'How long does it take you to get there?',
        prepSeconds: 3,
        answerSeconds: 15,
      ),
      Prompt(
        label: 'Question 7',
        text: 'What would make public transportation in your city better? '
            'Explain with two suggestions.',
        prepSeconds: 3,
        answerSeconds: 30,
      ),
    ],
    keyExpressions: <String>[
      'I usually take the subway to work.',
      'It takes me about forty minutes each way.',
      'They should run buses more frequently during rush hour.',
      'It would also help if the fares were a little cheaper.',
    ],
  ),
  Question(
    id: 'rq_03',
    partId: PartId.respondQuestions,
    title: '음식 배달 서비스에 대한 조사',
    prompts: <Prompt>[
      Prompt(
        label: 'Question 5',
        text: 'How often do you order food for delivery?',
        prepSeconds: 3,
        answerSeconds: 15,
      ),
      Prompt(
        label: 'Question 6',
        text: 'What kind of food do you usually order, and who do you eat it '
            'with?',
        prepSeconds: 3,
        answerSeconds: 15,
      ),
      Prompt(
        label: 'Question 7',
        text: 'Would you recommend your favorite delivery restaurant to a '
            'friend? Why or why not?',
        prepSeconds: 3,
        answerSeconds: 30,
      ),
    ],
    keyExpressions: <String>[
      'I order delivery once or twice a week.',
      'I usually order chicken or pizza, and I eat with my family.',
      'Definitely. The food always arrives hot, and the portions are generous.',
    ],
  ),
  Question(
    id: 'rq_04',
    partId: PartId.respondQuestions,
    title: '운동 습관에 대한 인터뷰',
    prompts: <Prompt>[
      Prompt(
        label: 'Question 5',
        text: 'What kind of exercise do you enjoy the most?',
        prepSeconds: 3,
        answerSeconds: 15,
      ),
      Prompt(
        label: 'Question 6',
        text: 'Where and when do you usually exercise?',
        prepSeconds: 3,
        answerSeconds: 15,
      ),
      Prompt(
        label: 'Question 7',
        text: 'Some people say exercising alone is better than exercising in a '
            'group. What do you think?',
        prepSeconds: 3,
        answerSeconds: 30,
      ),
    ],
    keyExpressions: <String>[
      'I enjoy swimming the most.',
      'I usually work out at a gym near my house, early in the morning.',
      'Personally, I think exercising in a group is better because ~',
    ],
  ),

  // ─────────────────── Q8-10 제공된 정보를 사용해 답하기 ───────────────────
  Question(
    id: 'ri_01',
    partId: PartId.respondWithInfo,
    title: '마케팅 워크숍 일정표',
    table: InfoTable(
      title: 'Digital Marketing Workshop',
      subtitle: 'Saturday, June 14 · Grand Hall, Milton Convention Center',
      rows: <List<String>>[
        <String>['9:00 A.M.', 'Registration & Coffee', 'Lobby'],
        <String>[
          '9:30 A.M.',
          'Opening Remarks — Ms. Karen Bishop',
          'Grand Hall'
        ],
        <String>[
          '10:00 A.M.',
          'Social Media Strategy — Mr. Alan Reed',
          'Room A'
        ],
        <String>['12:00 P.M.', 'Lunch (provided)', 'Cafeteria'],
        <String>['1:30 P.M.', 'Email Campaigns — Ms. Julia Kim', 'Room A'],
        <String>['3:00 P.M.', 'Panel Discussion', 'Grand Hall'],
        <String>['4:30 P.M.', 'Closing & Networking', 'Lobby'],
      ],
    ),
    prompts: <Prompt>[
      Prompt(
        label: 'Question 8',
        text: 'Hi, this is Daniel Cho. I registered for the workshop. Where is '
            'it being held, and what time does it start?',
        prepSeconds: 3,
        answerSeconds: 15,
      ),
      Prompt(
        label: 'Question 9',
        text: 'I heard that lunch is not included, so I should bring my own '
            'food. Is that right?',
        prepSeconds: 3,
        answerSeconds: 15,
        hint: '틀린 정보 정정: "Actually, that\'s not correct. ~"',
      ),
      Prompt(
        label: 'Question 10',
        text: 'I am mainly interested in the sessions in the afternoon. Could '
            'you tell me all the details of what happens after lunch?',
        prepSeconds: 3,
        answerSeconds: 30,
        hint: '오후 항목을 시간 → 제목 → 발표자 → 장소 순으로 모두 읽어 주세요.',
      ),
    ],
    keyExpressions: <String>[
      'The workshop will be held at the Milton Convention Center.',
      'Registration starts at 9 A.M., and the opening remarks begin at 9:30.',
      'Actually, that is not correct. Lunch is provided at the cafeteria.',
      'After lunch, there are two sessions. First, ~ Second, ~',
    ],
  ),
  Question(
    id: 'ri_02',
    partId: PartId.respondWithInfo,
    title: '면접 일정표',
    table: InfoTable(
      title: 'Interview Schedule — Sales Manager Position',
      subtitle: 'Tuesday, October 8 · Conference Room 3',
      rows: <List<String>>[
        <String>['10:00 A.M.', 'Brian Foster (5 years, Retail)', 'Room 3'],
        <String>['10:45 A.M.', 'Monica Shaw (7 years, Wholesale)', 'Room 3'],
        <String>['11:30 A.M.', 'Break', '—'],
        <String>['1:00 P.M.', 'Peter Nguyen (3 years, Online Sales)', 'Room 3'],
        <String>['1:45 P.M.', 'Sandra Lopez (6 years, Retail)', 'Room 3'],
        <String>['2:30 P.M.', 'Review Meeting with HR', 'Room 5'],
      ],
    ),
    prompts: <Prompt>[
      Prompt(
        label: 'Question 8',
        text: 'What time is the first interview, and where will it take place?',
        prepSeconds: 3,
        answerSeconds: 15,
      ),
      Prompt(
        label: 'Question 9',
        text: 'I believe all of the candidates have more than five years of '
            'experience. Is that correct?',
        prepSeconds: 3,
        answerSeconds: 15,
      ),
      Prompt(
        label: 'Question 10',
        text: 'I will only be available in the afternoon. Can you tell me '
            'everything scheduled after lunch?',
        prepSeconds: 3,
        answerSeconds: 30,
      ),
    ],
    keyExpressions: <String>[
      'The first interview is at 10 A.M. in Conference Room 3.',
      'Actually, that is not quite right. Peter Nguyen has three years ~',
      'In the afternoon, you have two interviews and one meeting.',
    ],
  ),
  Question(
    id: 'ri_03',
    partId: PartId.respondWithInfo,
    title: '출장 일정 (하루 여정)',
    table: InfoTable(
      title: 'Business Trip Itinerary — Ms. Helen Park',
      subtitle: 'Thursday, May 22 · Seattle',
      rows: <List<String>>[
        <String>[
          '7:20 A.M.',
          'Flight KE073 departs (Incheon → Seattle)',
          'Gate 24'
        ],
        <String>['11:00 A.M.', 'Hotel check-in', 'Bayview Hotel'],
        <String>[
          '1:00 P.M.',
          'Lunch with client — Mr. Steven Ross',
          'Harbor Grill'
        ],
        <String>['3:00 P.M.', 'Factory tour', 'Northline Plant'],
        <String>['6:30 P.M.', 'Company dinner', 'Bayview Hotel'],
      ],
    ),
    prompts: <Prompt>[
      Prompt(
        label: 'Question 8',
        text: 'What time does my flight leave, and which gate should I go to?',
        prepSeconds: 3,
        answerSeconds: 15,
      ),
      Prompt(
        label: 'Question 9',
        text:
            'I remember I am having lunch with Ms. Diane Cole. Is that right?',
        prepSeconds: 3,
        answerSeconds: 15,
      ),
      Prompt(
        label: 'Question 10',
        text: 'Could you go over everything I have scheduled after lunch?',
        prepSeconds: 3,
        answerSeconds: 30,
      ),
    ],
    keyExpressions: <String>[
      'Your flight, KE zero-seven-three, departs at 7:20 A.M. from gate 24.',
      'Actually, you will be having lunch with Mr. Steven Ross.',
      'After lunch, you have a factory tour at 3 P.M. and then ~',
    ],
  ),

  // ─────────────────────────── Q11 의견 제시 ───────────────────────────
  Question(
    id: 'eo_01',
    partId: PartId.expressOpinion,
    title: '재택근무에 대한 의견',
    prompts: <Prompt>[
      Prompt(
        label: 'Question 11',
        text: 'Do you agree or disagree with the following statement? Working '
            'from home is more productive than working in an office. Give '
            'reasons or examples to support your opinion.',
        prepSeconds: 45,
        answerSeconds: 60,
        hint: '의견 → 이유1 + 예시 → 이유2 + 예시 → 마무리. 60초를 꽉 채우세요.',
      ),
    ],
    keyExpressions: <String>[
      'I strongly agree with the statement for two main reasons.',
      'First of all, I can save a lot of commuting time.',
      'For example, when I worked from home last year, ~',
      'For these reasons, I believe working from home is more productive.',
    ],
    sampleAnswer:
        'I agree with the statement that working from home is more productive, '
        'for a couple of reasons. First of all, working from home saves a lot '
        'of commuting time. For example, I used to spend almost two hours a '
        'day on the subway, and I was already tired before I started working. '
        'Now I can use that time to prepare for the day, so I get more done. '
        'On top of that, there are fewer interruptions at home. In an office, '
        'people stop by my desk all the time, and it is hard to concentrate on '
        'one task. At home, I can turn off notifications and focus for a few '
        'hours straight. Of course, some jobs require teamwork in person, but '
        'for most office tasks, I believe working from home is more '
        'productive.',
  ),
  Question(
    id: 'eo_02',
    partId: PartId.expressOpinion,
    title: '온라인 강의 vs 오프라인 강의',
    prompts: <Prompt>[
      Prompt(
        label: 'Question 11',
        text: 'Some people prefer taking classes online, while others prefer '
            'attending classes in person. Which do you prefer, and why?',
        prepSeconds: 45,
        answerSeconds: 60,
      ),
    ],
    keyExpressions: <String>[
      'Personally, I prefer taking classes online.',
      'The main reason is that I can learn at my own pace.',
      'Another reason is that it is much more affordable.',
      'That is why I would choose online classes.',
    ],
  ),
  Question(
    id: 'eo_03',
    partId: PartId.expressOpinion,
    title: '기업의 직원 교육 투자',
    prompts: <Prompt>[
      Prompt(
        label: 'Question 11',
        text: 'Do you agree or disagree? Companies should spend more money on '
            'training their employees than on advertising. Support your '
            'opinion with reasons or examples.',
        prepSeconds: 45,
        answerSeconds: 60,
      ),
    ],
    keyExpressions: <String>[
      'I agree that companies should invest more in training.',
      'Well-trained employees provide better service to customers.',
      'In the long run, this builds a stronger reputation than any ad.',
    ],
  ),
  Question(
    id: 'eo_04',
    partId: PartId.expressOpinion,
    title: '대도시 거주 vs 소도시 거주',
    prompts: <Prompt>[
      Prompt(
        label: 'Question 11',
        text:
            'Which is better for young people: living in a large city or in a '
            'small town? Choose one and explain why.',
        prepSeconds: 45,
        answerSeconds: 60,
      ),
    ],
    keyExpressions: <String>[
      'In my opinion, living in a large city is better for young people.',
      'There are simply more job opportunities.',
      'Also, public transportation makes it easy to get around.',
    ],
  ),
];

List<Question> questionsOfPart(PartId id) =>
    kQuestions.where((Question q) => q.partId == id).toList(growable: false);

Question? questionById(String id) {
  for (final Question q in kQuestions) {
    if (q.id == id) return q;
  }
  return null;
}
