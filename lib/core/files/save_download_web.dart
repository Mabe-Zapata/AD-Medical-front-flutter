import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Hands the bytes to the browser as a download named [fileName].
Future<void> saveDownload(List<int> bytes, String fileName) async {
  final parts = <web.BlobPart>[Uint8List.fromList(bytes).toJS].toJS;
  final blob = web.Blob(parts, web.BlobPropertyBag(type: 'application/pdf'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
