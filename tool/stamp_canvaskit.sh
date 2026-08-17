#!/usr/bin/env bash
#
# 빌드된 CanvasKit 폴더 이름 뒤에 엔진 리비전을 붙인다.
#   build/web/canvaskit  ->  build/web/canvaskit-<리비전>
#
# web/flutter_bootstrap.js 가 리비전이 붙은 경로에서 CanvasKit 을 찾으므로,
# 배포하기 전에 반드시 한 번 실행해야 한다.
# 리비전이 주소에 들어가면 엔진이 바뀔 때 주소도 바뀌기 때문에,
# firebase.json 에서 1년짜리 캐시를 안전하게 걸 수 있다.
#
# 사용법: tool/stamp_canvaskit.sh [빌드 폴더]   (기본값 build/web)
set -euo pipefail

out="${1:-build/web}"
bootstrap="$out/flutter_bootstrap.js"

if [ ! -f "$bootstrap" ]; then
  echo "$bootstrap 이 없습니다. 먼저 flutter build web --release 를 실행하세요." >&2
  exit 1
fi

revision="$(grep -o '"engineRevision":"[0-9a-f]*"' "$bootstrap" |
  head -n 1 | sed 's/.*:"//; s/"$//')"

if [ -z "$revision" ]; then
  echo "flutter_bootstrap.js 에서 engineRevision 을 찾지 못했습니다." >&2
  exit 1
fi

target="$out/canvaskit-$revision"

if [ ! -d "$out/canvaskit" ]; then
  # 다시 빌드하지 않고 한 번 더 실행한 경우.
  if [ -d "$target" ]; then
    echo "이미 되어 있습니다: canvaskit-$revision"
    exit 0
  fi
  echo "$out/canvaskit 폴더가 없습니다." >&2
  exit 1
fi

# 다시 빌드하면 canvaskit 폴더가 새로 생긴다. 옛 결과물이 남지 않도록 지우고 옮긴다.
rm -rf "$target"
mv "$out/canvaskit" "$target"
echo "canvaskit -> canvaskit-$revision"
