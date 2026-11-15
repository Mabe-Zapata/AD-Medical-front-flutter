import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/features/lab_results/presentation/widgets/results_pdf_preview.dart';

void main() {
  testWidgets('the PDF preview shows the file name and a download button inside the modal', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showResultsPdfPreview(context, bytes: const [37, 80, 68, 70], fileName: 'resultados-abc.pdf'),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('resultados-abc.pdf'), findsOneWidget);
    expect(find.text('Descargar PDF'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
