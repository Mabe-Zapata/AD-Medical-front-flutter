import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

/// Outside the browser there is no PDF viewer: the patient downloads the file instead.
Widget pdfFrame(List<int> bytes) => const Padding(
  padding: EdgeInsets.all(24),
  child: Text(
    'La vista previa se muestra en el navegador. Descarga el archivo para verlo.',
    style: TextStyle(color: Tokens.muted),
  ),
);
