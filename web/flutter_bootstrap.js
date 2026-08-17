{{flutter_js}}
{{flutter_build_config}}

// CanvasKit(렌더링 엔진, 압축해도 2MB 남짓)을 Google CDN(gstatic) 대신
// 배포된 사이트에서 직접 받는다. CDN 이 막힌 망에서도 앱이 뜬다.
//
// 폴더 이름에 엔진 리비전을 붙이는 이유:
// CanvasKit 은 파일 이름이 늘 같아서, 주소를 그대로 둔 채 오래 캐시하면 나중에
// Flutter 를 올렸을 때 새 main.dart.js 가 캐시에 남은 옛 CanvasKit 을 잡아 깨질 수
// 있다. 그래서 지금까지는 캐시를 하루로 짧게 걸 수밖에 없었고, 재방문자가 매일
// 2MB 를 다시 받아야 했다. 리비전을 경로에 넣으면 엔진이 바뀔 때 주소도 같이
// 바뀌므로 안심하고 1년짜리 캐시를 걸 수 있다.
// (Flutter 가 gstatic CDN 을 쓸 때 하는 방식과 같다.)
//
// 빌드 결과물의 폴더 이름은 tool/stamp_canvaskit.sh 가 맞춰 준다.
// 리비전을 못 읽으면 예전 경로로 돌아가 최소한 앱은 뜨게 한다.
var engineRevision = _flutter.buildConfig && _flutter.buildConfig.engineRevision;

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: engineRevision ? "canvaskit-" + engineRevision + "/" : "canvaskit/",
  },
});
