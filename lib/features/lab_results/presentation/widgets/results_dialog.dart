import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/presentation/widgets/result_format.dart';

void showResultsDialog(
  BuildContext context, {
  required LabOrder order,
  required String patientName,
  required Future<void> Function() onOpenPdf,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusMd)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(order: order, patientName: patientName),
              const SizedBox(height: 20),
              _Summary(order: order),
              for (final detail in order.details) ...[
                const SizedBox(height: 16),
                _TestCard(detail: detail),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => onOpenPdf(),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Ver PDF'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.order, required this.patientName});

  final LabOrder order;
  final String patientName;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      patientName,
      if (order.doctorName != null) 'por ${order.doctorName}',
    ].join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(color: Tokens.blueTint, shape: BoxShape.circle),
          child: const Icon(Icons.science_outlined, color: Tokens.blueText),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resultados · ${orderTitle(order)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Tokens.slate900,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Tokens.slate600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Counts of each reading across the order, so the patient sees the picture before the detail.
class _Summary extends StatelessWidget {
  const _Summary({required this.order});

  final LabOrder order;

  @override
  Widget build(BuildContext context) {
    final results = [for (final d in order.details) ...d.validatedResults];
    if (results.isEmpty) return const SizedBox.shrink();
    final normal = results.where((r) => r.interpretation == Interpretation.withinReference).length;
    final outside = results
        .where((r) => r.interpretation == Interpretation.low || r.interpretation == Interpretation.high)
        .length;
    final unevaluated = results.where((r) => r.interpretation == Interpretation.notEvaluable).length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (normal > 0) _CountChip('$normal en rango', Tokens.success, Icons.check_circle_outline),
        if (outside > 0) _CountChip('$outside fuera de rango', Tokens.warning, Icons.priority_high),
        if (unevaluated > 0)
          _CountChip('$unevaluated sin interpretar', Tokens.slate600, Icons.help_outline),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.detail});

  final OrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final results = detail.validatedResults;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Tokens.slate200),
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.testName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Tokens.orangeDeep,
              ),
            ),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: _PendingNotice(),
              )
            else ...[
              const SizedBox(height: 8),
              for (var i = 0; i < results.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: Tokens.slate200),
                _ResultRow(results[i]),
              ],
              const SizedBox(height: 10),
              Text(
                _provenance(results.first),
                style: const TextStyle(color: Tokens.slate600, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingNotice extends StatelessWidget {
  const _PendingNotice();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Tokens.blueTint,
      borderRadius: BorderRadius.circular(Tokens.radiusSm),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty, size: 18, color: Tokens.blueText),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pendiente de validación del laboratorio.',
              style: TextStyle(color: Tokens.blueText, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.result);

  final AnalyteResult result;

  @override
  Widget build(BuildContext context) {
    final notEvaluable = result.interpretation == Interpretation.notEvaluable;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Tokens.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Referencia: ${referenceLabel(result)}',
                      style: const TextStyle(fontSize: 12, color: Tokens.slate600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    valueLabel(result),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Tokens.slate900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _VerdictChip(result.interpretation),
                ],
              ),
            ],
          ),
          if (result.corrected) ...[
            const SizedBox(height: 6),
            const Text(
              'Corregido por el laboratorio',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Tokens.slate600),
            ),
          ],
          if (notEvaluable) ...[
            const SizedBox(height: 6),
            const Text(
              'No pudimos interpretar este valor con los datos disponibles. Consúltalo con tu médico.',
              style: TextStyle(fontSize: 12, color: Tokens.slate600),
            ),
          ],
        ],
      ),
    );
  }
}

class _VerdictChip extends StatelessWidget {
  const _VerdictChip(this.value);

  final Interpretation? value;

  @override
  Widget build(BuildContext context) {
    final current = value;
    if (current == null) return const SizedBox.shrink();
    final (label, color, icon) = switch (current) {
      Interpretation.withinReference => ('En rango', Tokens.success, Icons.check_circle_outline),
      Interpretation.low => ('Bajo', Tokens.warning, Icons.arrow_downward),
      Interpretation.high => ('Alto', Tokens.warning, Icons.arrow_upward),
      Interpretation.notEvaluable => ('Sin interpretar', Tokens.slate600, Icons.help_outline),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

String _provenance(AnalyteResult result) {
  final validatedAt = result.validatedAt;
  return [
    if (result.sampleType != null) 'Muestra: ${result.sampleType}',
    if (result.method != null) 'Método: ${result.method}',
    if (validatedAt != null) 'Validado el ${dayLabel(branchTime(validatedAt))}',
  ].join(' · ');
}
