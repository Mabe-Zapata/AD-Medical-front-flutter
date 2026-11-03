import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/presentation/widgets/result_format.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/status_chip.dart';

void showResultsDialog(BuildContext context, {required LabOrder order, required String patientName}) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resultados · ${order.id}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Tokens.slate900)),
              const SizedBox(height: 4),
              Text(
                [
                  patientName,
                  if (order.orderedAt != null) 'ordenada el ${dayLabel(branchTime(order.orderedAt!))}',
                  if (order.doctorName != null) 'por ${order.doctorName}',
                ].join(' · '),
                style: const TextStyle(color: Tokens.muted, fontSize: 12),
              ),
              for (final detail in order.details) ...[
                const SizedBox(height: 24),
                Text(detail.testName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Tokens.orangeDeep)),
                const SizedBox(height: 8),
                if (detail.validatedResults.isEmpty)
                  const Text('Pendiente de validación del laboratorio.', style: TextStyle(color: Tokens.muted))
                else ...[
                  _ResultsTable(detail.validatedResults),
                  const SizedBox(height: 8),
                  Text(_provenance(detail.validatedResults.first), style: const TextStyle(color: Tokens.muted, fontSize: 12)),
                ],
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Versión demo: el PDF lo generará la API de reportes.')),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Descargar PDF'),
                  ),
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _provenance(AnalyteResult result) {
  final validatedAt = result.validatedAt;
  return [
    if (result.sampleType != null) 'Muestra: ${result.sampleType}',
    if (result.method != null) 'Método: ${result.method}',
    if (validatedAt != null) 'Validado el ${dayLabel(branchTime(validatedAt))}',
  ].join(' · ');
}

class _ResultsTable extends StatelessWidget {
  const _ResultsTable(this.results);

  final List<AnalyteResult> results;

  @override
  Widget build(BuildContext context) => Table(
    columnWidths: const {
      0: FlexColumnWidth(3),
      1: FlexColumnWidth(2),
      2: FlexColumnWidth(2),
      3: FixedColumnWidth(104),
    },
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    children: [
      _row(const ['Analito', 'Resultado', 'Referencia'], const SizedBox.shrink(), header: true),
      for (final r in results) _row([r.name, valueLabel(r), referenceLabel(r)], _interpretation(r.interpretation)),
    ],
  );

  TableRow _row(List<String> cells, Widget last, {bool header = false}) => TableRow(
    children: [
      for (final cell in cells)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            cell,
            style: TextStyle(
              fontSize: 12,
              fontWeight: header ? FontWeight.w800 : FontWeight.w600,
              color: header ? Tokens.muted : Tokens.slate900,
            ),
          ),
        ),
      Align(alignment: Alignment.centerLeft, child: last),
    ],
  );

  Widget _interpretation(Interpretation? value) => switch (value) {
    null => const SizedBox.shrink(),
    Interpretation.withinReference => const StatusChip('En rango', Tokens.success),
    Interpretation.low => const StatusChip('Bajo', Tokens.warning),
    Interpretation.high => const StatusChip('Alto', Tokens.warning),
    Interpretation.notEvaluable => const StatusChip('No evaluable', Tokens.muted),
  };
}
