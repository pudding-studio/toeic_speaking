# 문항 이미지

Q3-4(사진 묘사) 문항에서 쓰는 사진을 여기에 둡니다.

## 파일 이름

문항 id 와 같게 지으면 관리가 쉽습니다.

```
assets/images/questions/dp_01.jpg
assets/images/questions/dp_02.jpg
```

`lib/data/question_bank.dart` 에서 다음처럼 연결합니다.

```dart
Question(
  id: 'dp_01',
  partId: PartId.describePicture,
  title: '야외 카페 테라스',
  imagePath: 'assets/images/questions/dp_01.jpg',
  sampleAnswer: '...',
),
```

## 권장 사양

- 가로 세로 비율 4:3 또는 16:9 (앱에서 4:3 으로 표시)
- 가로 1200px 내외, JPG 80% 품질 — 웹앱이라 용량이 곧 로딩 시간입니다
- 파일당 300KB 이하 권장

## 저작권

배포되는 웹앱에 그대로 포함됩니다. 직접 촬영했거나 상업적 이용이 허용된
사진(Unsplash, Pexels 등)만 사용하세요.

## 이미지가 없을 때

`imagePath` 를 생략하면 `scene` 의 텍스트 장면 설명이 대신 표시됩니다.
둘 다 넣으면 사진이 우선하고, 장면 설명은 표시되지 않습니다.
