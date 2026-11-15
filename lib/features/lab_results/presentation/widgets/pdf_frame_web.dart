import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:web/web.dart' as web;

var _next = 0;

/// The PDF drawn by the browser's own viewer inside the modal.
Widget pdfFrame(List<int> bytes) {
  final parts = <web.BlobPart>[Uint8List.fromList(bytes).toJS].toJS;
  final url = web.URL.createObjectURL(web.Blob(parts, web.BlobPropertyBag(type: 'application/pdf')));
  final viewType = 'lab-results-pdf-${_next++}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
    final frame = web.document.createElement('iframe') as web.HTMLIFrameElement
      ..src = url
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';
    return frame;
  });
  return SizedBox(
    height: 560,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Tokens.slate200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: HtmlElementView(viewType: viewType),
    ),
  );
}
