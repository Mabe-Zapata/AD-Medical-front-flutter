import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';

String _trim(double? v) => v == null ? '—' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString());

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
