# TOEIC Speaking 연습 앱

TOEIC Speaking 시험(2021 개정, 11문항)을 파트별로 연습하는 Flutter 안드로이드 앱입니다.
실제 시험과 동일한 **준비 시간 → 답변 시간** 흐름으로 진행되며, 답변은 자동으로 녹음되어
바로 다시 들어볼 수 있습니다.

## 화면 구성

상단에 **가로 스크롤이 가능한 탭**이 있고, 탭마다 해당 파트의 연습 문항이 들어 있습니다.

| 탭 | 내용 |
| --- | --- |
| 전체 | 학습 통계, 파트 바로가기, 최근 녹음 |
| Q1-2 문장 읽기 | 지문 낭독 (준비 45초 / 답변 45초) |
| Q3-4 사진 묘사 | 장면 묘사 (준비 45초 / 답변 30초) |
| Q5-7 듣고 답하기 | 전화 인터뷰 3문항 (준비 3초 / 답변 15·15·30초) |
| Q8-10 정보 활용 | 표 자료 기반 3문항 (자료 확인 45초 / 답변 15·15·30초) |
| Q11 의견 제시 | 찬반·선택형 (준비 45초 / 답변 60초) |
| 녹음 기록 | 저장된 모든 녹음 재생·삭제 |

탭이 화면 너비를 넘기 때문에 좌우로 밀어서 이동할 수 있고, 본문을 스와이프해도 탭이 함께
움직입니다. 탭 색상은 파트별로 다르게 표시됩니다.

## 주요 기능

- **실전 타이머** — 파트·문항별로 정해진 준비/답변 시간을 원형 카운트다운으로 표시합니다.
  준비 시간 중에 "바로 답변 시작"으로 건너뛰거나, 답변 도중 "답변 끝내기"로 조기 종료할 수 있습니다.
- **자동 녹음** — 답변 시간이 시작되면 녹음이 자동으로 시작되고, 시간이 끝나면 자동 저장됩니다.
  Q5-7 / Q8-10 처럼 하위 문항이 여러 개인 경우 문항마다 따로 저장됩니다.
- **바로 듣기** — 연습이 끝나면 그 자리에서 재생할 수 있고, "녹음 기록" 탭에 모두 모입니다.
- **파트별 공략법** — 각 파트의 채점 포인트와 바로 쓰는 답변 템플릿을 바텀시트로 제공합니다.
- **문항 자료** — 낭독 지문, 사진 상황 설명, 일정표 자료, 핵심 표현, 일부 문항의 모범 답안 포함.
- **학습 통계** — 총 녹음 수 / 총 발화 시간 / 연습한 날짜 수.

녹음 파일은 앱 내부 저장소(`앱 문서 디렉터리/recordings`)에만 저장되며 외부로 전송되지 않습니다.

## 실행 방법

Flutter 3.27 이상이 필요합니다(개발·검증은 Flutter 3.47 / Dart 3.13 기준).

```bash
flutter pub get
flutter run            # 안드로이드 기기 또는 에뮬레이터 연결 상태에서
```

APK 빌드:

```bash
flutter build apk --release
```

> 릴리스 빌드는 현재 디버그 키로 서명되어 있습니다. 배포하려면
> `android/app/build.gradle.kts` 의 `signingConfig` 를 본인 키스토어로 바꾸세요.

첫 연습을 시작하면 마이크 권한을 물어봅니다. 거부한 경우 시스템 설정에서 다시 허용해야
녹음이 동작합니다.

## 검증

```bash
flutter analyze     # 이슈 없음
flutter test        # 11개 테스트 통과
```

## 프로젝트 구조

```
lib/
├── main.dart                      앱 진입점
├── theme.dart                     테마, 파트별 색상/아이콘
├── models/
│   ├── toeic_part.dart            파트 정의(시간, 공략법, 템플릿)
│   ├── question.dart              문항·질문·자료 모델
│   └── attempt.dart               녹음 1건 모델 + JSON 직렬화
├── data/
│   └── question_bank.dart         파트별 연습 문항 데이터
├── services/
│   ├── recorder_service.dart      record 패키지 래퍼(권한/파일/녹음)
│   ├── playback_service.dart      audioplayers 기반 재생
│   └── attempt_store.dart         녹음 기록 저장(SharedPreferences)
├── screens/
│   ├── home_screen.dart           가로 스크롤 탭 + TabBarView
│   ├── overview_tab.dart          "전체" 탭
│   ├── part_tab.dart              파트별 문항 목록
│   ├── practice_screen.dart       준비→녹음→저장 진행 화면
│   └── recording_list.dart        녹음 타일 / "녹음 기록" 탭
└── widgets/
    ├── common.dart                카드, 배지, 자료 표, 공략법 시트
    └── countdown_ring.dart        원형 카운트다운
```

## 문항 추가하기

`lib/data/question_bank.dart` 의 `kQuestions` 리스트에 `Question` 을 추가하면 해당 파트 탭에
자동으로 나타납니다. 화면 코드는 손대지 않아도 됩니다.

```dart
Question(
  id: 'ra_05',                    // 고유 id
  partId: PartId.readAloud,       // 소속 파트
  title: '박물관 안내 방송',
  passage: 'Attention, visitors. ...',
  keyExpressions: <String>['...'],
),
```

준비/답변 시간은 파트 기본값을 따르며, 문항별로 다르게 하려면 `prompts` 에 `Prompt` 를
직접 넣고 `prepSeconds` / `answerSeconds` 를 지정하세요.

## 사용 패키지

`record`(녹음) · `audioplayers`(재생) · `path_provider`(저장 경로) ·
`shared_preferences`(기록 저장) · `intl`(날짜 표시)
