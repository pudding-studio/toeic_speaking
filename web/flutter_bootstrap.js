{{flutter_js}}
{{flutter_build_config}}

// CanvasKit 을 Google CDN(gstatic) 대신 배포된 사이트에서 직접 받는다.
// 사내망 등에서 CDN 이 막혀 있어도 앱이 뜨고, 오프라인 캐시에도 유리하다.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
