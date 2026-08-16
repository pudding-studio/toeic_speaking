# TOEIC Speaking 연습 (웹앱)

TOEIC Speaking 시험(2021 개정, 11문항)을 파트별로 연습하는 Flutter 웹앱입니다.
실제 시험과 동일한 **준비 시간 → 답변 시간** 흐름으로 진행되며, 브라우저 마이크로
답변이 자동 녹음되어 바로 다시 들어볼 수 있습니다. Firebase Hosting 배포용 설정이
들어 있습니다.

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

탭이 화면 너비를 넘기 때문에 좌우로 밀어서 이동할 수 있고, 본문을 스와이프해도 탭이
함께 움직입니다. 탭 색상은 파트별로 다릅니다. PC 브라우저에서는 화면이 과도하게
늘어나지 않도록 가운데 정렬됩니다.

## 주요 기능

- **실전 타이머** — 파트·문항별로 정해진 준비/답변 시간을 원형 카운트다운으로 표시합니다.
  준비 중 "바로 답변 시작", 답변 중 "답변 끝내기"로 건너뛸 수 있습니다.
- **자동 녹음** — 답변 시간이 시작되면 녹음이 자동으로 시작되고 끝나면 자동 저장됩니다.
  Q5-7 / Q8-10 처럼 하위 문항이 여러 개면 문항마다 따로 저장됩니다.
  마이크 권한은 준비 시간이 시작되기 전에 미리 확인하므로 권한 창 때문에 시간을 까먹지 않습니다.
- **바로 듣기** — 연습이 끝나면 그 자리에서 재생하고, "녹음 기록" 탭에 모두 모입니다.
- **지문 읽어주기 (Q1-2)** — 낭독 지문을 브라우저 음성으로 들어 보며 발음을 확인할 수 있습니다.
  보통 / 느리게 두 속도를 제공하고, 녹음 중에는 소리가 마이크에 섞이지 않도록 자동으로 멈춥니다.
- **파트별 공략법** — 채점 포인트와 바로 쓰는 답변 템플릿을 바텀시트로 제공합니다.
- **문항 자료** — 낭독 지문, 사진 상황 설명, 일정표 자료, 핵심 표현, 일부 문항의 모범 답안.
- **학습 통계** — 총 녹음 수 / 총 발화 시간 / 연습한 날짜 수.
- **문항 직접 등록** — 코드를 고치지 않고 앱 화면에서 문항을 추가·수정·삭제할 수 있습니다.
  사진 묘사 문항은 사진을 직접 올릴 수 있습니다. 등록한 문항은 이 브라우저에만 저장됩니다.

### 녹음 저장 방식

브라우저에는 파일 시스템이 없으므로, 녹음은 **브라우저 안(IndexedDB)** 에만 저장됩니다.

- 서버로 전송되지 않습니다. 다른 기기·다른 브라우저에서는 보이지 않습니다.
- `record` 가 MediaRecorder(WebM/Opus)로 녹음 → blob URL → base64 data URL 로 바꿔 저장합니다.
- 목록에는 메타데이터만 읽고, 실제 오디오는 재생할 때만 꺼내옵니다.
- 시크릿 모드 등으로 IndexedDB 를 쓸 수 없으면 그 세션 동안만 유지되며, 안내 문구가 표시됩니다.

### 지문 읽어주기

두 가지 엔진을 쓸 수 있고, 설정(오른쪽 위 톱니바퀴)에서 고릅니다.

| | 브라우저 내장 음성 | Google Cloud TTS |
| --- | --- | --- |
| 자연스러움 | 기계적인 편 | 사람 목소리에 가까움 (Neural2) |
| 준비 | 없음 (기본값) | 본인 API 키 입력 |
| 요금 | 없음 | 월 100만 자까지 무료 |

**API 키는 앱에 포함되어 있지 않습니다.** 각자 자기 키를 넣고, 그 키는 그 사람의
브라우저에만 저장됩니다. 설정 화면에 키 만드는 절차와 제한 거는 법이 정리되어 있습니다.

- **한 번 만든 음성은 저장됩니다.** 같은 지문·음성·속도면 API 를 다시 부르지 않으므로
  요금은 처음 한 번만 발생합니다. 설정에서 저장된 개수를 보고 비울 수 있습니다.
- Google 호출이 실패하면 브라우저 내장 음성으로 대신 읽고, 실패 이유를 안내합니다.
- 녹음이 시작되면 자동으로 멈춥니다. 읽어주기 소리가 답변 녹음에 섞이면 안 되기 때문입니다.

### 앱에서 등록한 문항

파트 탭 맨 아래 "○○ 문항 직접 등록" 버튼으로 문항을 만들 수 있습니다.

- 파트에 따라 필요한 입력만 나옵니다 (낭독 지문 / 사진·장면 설명 / 질문·시간 / 자료 표).
- **예시 음성**을 파일로 올릴 수 있습니다(mp3·m4a·wav). 직접 녹음했거나 다른 도구로
  만든 음성을 붙여 두면, 연습 화면 맨 위 "예시 음성" 카드에서 모범 낭독으로 들을 수
  있습니다. 읽어주기와 마찬가지로 답변 녹음이 시작되면 자동으로 멈춥니다.
- 등록한 문항은 목록에서 "내 문항" 배지가 붙고, 오른쪽 메뉴로 수정·삭제할 수 있습니다.
- 기본 제공 문항은 코드에 있으므로 앱에서 수정·삭제되지 않습니다.
- **녹음과 마찬가지로 이 브라우저에만 저장됩니다.** 다른 기기나 다른 사람에게는 보이지
  않고, 브라우저 데이터를 지우면 사라집니다. 모두에게 보여야 하는 문항은
  `lib/data/question_bank.dart` 에 넣고 배포하세요.

#### 내보내기 · 가져오기

설정 화면의 "내가 등록한 문항"에서 **파일 하나로 내보내고 다시 가져올 수** 있습니다.
사진과 예시 음성도 base64 로 같은 파일에 담기므로, 그 파일만 옮기면 그대로 복원됩니다.

- 백업, 다른 기기·브라우저로 이동, 저장소에 커밋해 두기 등에 쓸 수 있습니다.
- 가져오기는 같은 id 의 문항이 있으면 덮어씁니다. 기본 제공 문항은 영향을 받지 않습니다.
- 형식이 맞지 않거나 다른 앱에서 만든 파일이면 이유를 알려 주고 아무 것도 바꾸지 않습니다.
  일부 항목만 깨진 경우 나머지는 살리고 건너뛴 개수를 알려 줍니다.

### 브라우저 요구사항

- 마이크 사용에는 **HTTPS 가 필요합니다**(`localhost` 는 예외). Firebase Hosting 은 HTTPS 를 기본 제공합니다.
- Chrome / Edge / Firefox 최신 버전에서 동작합니다. iOS Safari 는 MediaRecorder 지원이
  버전에 따라 제한적일 수 있습니다.

## 실행 방법

Flutter 3.27 이상이 필요합니다(개발·검증은 Flutter 3.47 / Dart 3.13 기준).

```bash
flutter pub get
flutter run -d chrome          # 개발
flutter build web --release    # 배포용 번들 → build/web
```

## 배포

### 자동 배포 (GitHub Actions)

기본 브랜치에 푸시되면 자동으로 검증 → 빌드 → Firebase Hosting 라이브 채널 배포까지
진행됩니다. 처음 한 번만 아래 설정이 필요합니다.

**1. Firebase 서비스 계정 만들기**

```bash
npm install -g firebase-tools
firebase login
firebase init hosting:github    # 저장소를 연결하면 서비스 계정과 시크릿을 자동 생성
```

`firebase init hosting:github` 는 서비스 계정을 만들고 GitHub 시크릿까지 넣어 주지만,
워크플로 파일도 새로 만들려고 합니다. **워크플로를 덮어쓰겠냐고 물으면 거절하세요**
(이 저장소에 이미 있습니다). 수동으로 하려면 Firebase 콘솔 → 프로젝트 설정 →
서비스 계정에서 키(JSON)를 만들고 `Firebase Hosting 관리자` 역할을 부여하세요.

**2. GitHub 저장소에 값 등록** (Settings → Secrets and variables → Actions)

| 종류 | 이름 | 값 |
| --- | --- | --- |
| Secret | `FIREBASE_SERVICE_ACCOUNT` | 서비스 계정 JSON **전체 내용** |
| Variable | `FIREBASE_PROJECT_ID` | Firebase 프로젝트 ID (예: `toeic-speaking-app`) |

둘 중 하나라도 없으면 배포를 **건너뛰고** 어떤 값이 빠졌는지 실행 요약에 남깁니다
(실패로 처리하지 않으므로, 설정 전에는 워크플로가 빨갛게 뜨지 않습니다).

**워크플로 구성**

| 파일 | 언제 | 하는 일 |
| --- | --- | --- |
| `.github/workflows/ci.yml` | 모든 푸시 / PR | 포맷 확인 · `flutter analyze` · `flutter test` · 웹 빌드, 빌드 결과 아티팩트 업로드 |
| `.github/workflows/deploy.yml` | 기본 브랜치 푸시 / 수동 실행 | 검증 후 빌드 → 라이브 채널 배포 |
| `.github/workflows/pr-preview.yml` | PR | 미리보기 채널(7일 만료) 배포 후 PR 에 URL 댓글 |

`deploy.yml` 은 브랜치 이름을 고정하지 않고 **저장소의 기본 브랜치**와 비교합니다.
지금은 이 작업 브랜치가 기본 브랜치이므로 여기에 푸시하면 배포되고, 나중에 기본
브랜치를 `main` 으로 바꿔도 파일 수정 없이 그대로 동작합니다.
포크에서 올라온 PR 은 시크릿에 접근할 수 없어 미리보기를 건너뜁니다.

Flutter 버전은 각 워크플로 상단의 `FLUTTER_VERSION` 에서 한 곳씩 바꿉니다.

### 수동 배포

```bash
firebase use --add                    # Firebase 프로젝트 선택 → .firebaserc 생성
flutter build web --release
firebase deploy --only hosting
```

빌드와 배포는 분리되어 있습니다(`firebase.json` 에 predeploy 훅 없음). 배포 전에
`flutter build web --release` 를 먼저 실행해야 최신 코드가 올라갑니다.

### Hosting 설정 요약

- `public: build/web`, SPA 라우팅(`rewrites`)
- `index.html` / `main.dart.js` / `flutter_bootstrap.js` 는 `no-cache` — 배포 즉시 새 버전이 반영됩니다.
- `canvaskit/` 1일, `assets/` 1시간 캐시.
- `web/flutter_bootstrap.js` 에서 CanvasKit 을 Google CDN(gstatic) 대신 **같은 도메인에서** 받도록 지정했습니다. 사내망에서 CDN 이 막혀 있어도 앱이 뜹니다.
- Flutter 의 서비스 워커는 쓰지 않습니다(항상 최신 버전 로드).

## 검증 상태

```bash
dart format --output=none --set-exit-if-changed .   # 포맷 통과
flutter analyze                                     # 이슈 없음
flutter test                                        # 39개 테스트 통과
flutter build web --release                         # 성공
```

같은 명령이 `.github/workflows/ci.yml` 에서 모든 푸시·PR 마다 실행됩니다.

> 브라우저에서의 실제 동작(녹음 → 저장 → 재생)은 이 저장소의 개발 환경에서 확인하지
> 못했습니다. 샌드박스의 헤드리스 Chromium 에서 Flutter 3.47 웹 엔진이 초기화를 끝내지
> 못하는데, 기본 `flutter create` 카운터 앱도 동일하게 멈추는 것으로 보아 환경 제약입니다.
> 배포 전에 실제 브라우저에서 한 번 확인해 주세요.

## 프로젝트 구조

```
lib/
├── main.dart                      앱 진입점 (넓은 화면 가운데 정렬 포함)
├── theme.dart                     테마, 파트별 색상/아이콘
├── models/
│   ├── toeic_part.dart            파트 정의(시간, 공략법, 템플릿)
│   ├── question.dart              문항·질문·자료 모델
│   └── attempt.dart               녹음 메타데이터 + JSON 직렬화
├── data/
│   └── question_bank.dart         파트별 연습 문항 데이터
├── services/
│   ├── recorder_service.dart      마이크 녹음 → data URL 변환
│   ├── tts_service.dart           읽어주기(Google TTS / 브라우저) + 캐시
│   ├── settings_store.dart        API 키·음성 설정
│   ├── sample_audio_service.dart  문항에 올린 예시 음성 재생
│   ├── question_transfer.dart     문항 내보내기·가져오기 형식
│   ├── file_download.dart         파일 내려받기(웹 전용 구현 조건부 임포트)
│   ├── local_storage.dart         IndexedDB (녹음 / 등록한 문항)
│   ├── playback_service.dart      재생(재생 시점에 오디오 로드)
│   ├── attempt_store.dart         녹음 목록 상태
│   └── question_store.dart        기본 문항 + 등록한 문항 병합
├── screens/
│   ├── home_screen.dart           가로 스크롤 탭 + TabBarView
│   ├── overview_tab.dart          "전체" 탭
│   ├── part_tab.dart              파트별 문항 목록 + 등록 버튼
│   ├── practice_screen.dart       준비→녹음→저장 진행 화면
│   ├── question_editor_screen.dart  문항 등록·수정 폼
│   ├── settings_screen.dart       읽어주기 설정 · API 키
│   └── recording_list.dart        녹음 타일 / "녹음 기록" 탭
└── widgets/
    ├── common.dart                카드, 배지, 자료 표, 공략법 시트
    ├── tts_controls.dart          들어보기 · 속도 조절
    └── countdown_ring.dart        원형 카운트다운

assets/images/questions/           Q3-4 사진 (README 에 규칙 정리)

web/
├── index.html                     로딩 표시, 한국어 메타데이터
├── flutter_bootstrap.js           CanvasKit 자체 호스팅 설정
└── manifest.json                  PWA 매니페스트(홈 화면 추가용)

.github/workflows/
├── ci.yml                         포맷·분석·테스트·빌드
├── deploy.yml                     기본 브랜치 → 라이브 채널 배포
└── pr-preview.yml                 PR → 미리보기 채널 배포

firebase.json                      Hosting 설정(캐시 헤더, SPA 라우팅)
```

## 문항 추가하기

방법이 두 가지입니다.

| | 앱에서 등록 | 코드에 추가 |
| --- | --- | --- |
| 보이는 범위 | 등록한 브라우저에서만 | 배포하면 모든 사용자 |
| 방법 | 파트 탭 → "문항 직접 등록" | `lib/data/question_bank.dart` 편집 |
| 사진 | 앱에서 업로드 | `assets/images/questions/` 에 파일 추가 |
| 배포 필요 | 없음 | 커밋 → CI 배포 |

아래는 **코드에 추가**하는 방법입니다.

`lib/data/question_bank.dart` 의 `kQuestions` 에 `Question` 을 추가하면 해당 파트 탭에
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

### 파트별로 채우는 필드

| 파트 | 필수 | 선택 |
| --- | --- | --- |
| Q1-2 | `passage` | `keyExpressions` |
| Q3-4 | `imagePath` 또는 `scene` | `sampleAnswer`, `keyExpressions` |
| Q5-7 | `prompts` (3개) | `keyExpressions` |
| Q8-10 | `table`, `prompts` (3개) | `keyExpressions` |
| Q11 | `prompts` (1개) | `sampleAnswer` |

`kQuestions` 는 `const` 리스트이므로 문자열 리터럴만 넣을 수 있습니다. 긴 문장은
인접 리터럴로 이어 붙이세요.

`id` 중복, 시간 누락, 사진 묘사 문항의 자료 누락은 `test/question_bank_test.dart` 가
검사합니다. 추가 후 `flutter test` 로 확인하세요.

### 사진 묘사 문항에 사진 넣기

1. 이미지를 `assets/images/questions/` 에 넣습니다 (파일명은 문항 id 와 맞추면 편합니다).
2. 해당 `Question` 에 `imagePath` 를 지정합니다.

```dart
Question(
  id: 'dp_01',
  partId: PartId.describePicture,
  title: '야외 카페 테라스',
  imagePath: 'assets/images/questions/dp_01.jpg',
  sampleAnswer: 'This picture was taken at an outdoor cafe...',
),
```

`pubspec.yaml` 에 폴더가 통째로 등록되어 있어서 파일을 개별로 나열할 필요는 없습니다.
`imagePath` 를 생략하면 `scene` 의 텍스트 장면 설명이 대신 표시되고, 둘 다 있으면
사진이 우선합니다. 파일을 못 찾아도 화면이 깨지지 않고 안내 문구가 뜹니다.

권장 사양과 저작권 주의사항은 `assets/images/questions/README.md` 에 정리해 두었습니다.

## 사용 패키지

`record`(녹음) · `audioplayers`(재생·음성 출력) · `flutter_tts`(브라우저 읽어주기) ·
`idb_shim`(IndexedDB) · `image_picker`(사진 선택) · `file_picker`(음성 파일 선택) ·
`http`(HTTP 호출) · `crypto`(캐시 키) · `web`(파일 내려받기) · `intl`(날짜 표시)
