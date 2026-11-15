import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/files/save_download.dart';
import 'package:medicalbooking_portal/features/lab_results/presentation/widgets/pdf_frame.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';

/// Shows the results PDF inside a modal, with the download next to it.
Future<void> showResultsPdfPreview(
  BuildContext context, {
  required List<int> bytes,
  required String fileName,
}) => showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Tokens.slate900),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            pdfFrame(bytes),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 320,
                child: GradientButton(
                  label: 'Descargar PDF',
                  trailing: Icons.download_outlined,
                  onPressed: () => saveDownload(bytes, fileName),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
