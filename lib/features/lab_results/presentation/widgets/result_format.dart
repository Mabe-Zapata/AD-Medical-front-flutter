import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';

/// Human title for an order; the technical id never reaches the screen.
String orderTitle(LabOrder order) => order.orderedAt == null
    ? 'Orden de laboratorio'
    : 'Orden del ${dayLabel(branchTime(order.orderedAt!))}';

String _trim(double? v) => v == null
    ? '—'
    : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString());

String valueLabel(AnalyteResult r) {
  final value = r.valueText ?? _trim(r.valueNumeric);
  final unit = r.unit;
  return unit == null || unit.isEmpty ? value : '$value $unit';
}

String referenceLabel(AnalyteResult r) {
  final min = r.referenceMin;
  final max = r.referenceMax;
  if (min == null && max == null) return '—';
  if (min == null) return '< ${_trim(max)}';
  if (max == null) return '> ${_trim(min)}';
  return '${_trim(min)} – ${_trim(max)}';
}
