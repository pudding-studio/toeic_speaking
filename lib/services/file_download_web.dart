import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// 브라우저에서 파일을 내려받게 한다.
///
/// Blob 을 만들고 임시 링크를 눌러 다운로드를 띄우는, 웹에서 가장 널리 쓰이는 방식이다.
void downloadBytes({
  required Uint8List bytes,
  required String fileName,
  String mimeType = 'application/octet-stream',
}) {
  final web.Blob blob = web.Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final String url = web.URL.createObjectURL(blob);
  final web.HTMLAnchorElement anchor =
      web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = fileName
        ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
