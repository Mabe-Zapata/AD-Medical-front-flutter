/// Rules for the patient's declarations and date ranges, mirrored from the backend so a form can
/// explain a problem before a round trip. The backend decides. Every function returns the fields with a
/// problem as stable keys; the screen turns them into Spanish.
library;

import 'package:medicalbooking_portal/core/domain/personal_data.dart';

import '../entities/patient_history.dart';

const int descriptionMax = 500;
const int reactionMax = 300;
const int relativeMax = 50;
const int nameMax = 150;
const int doseMax = 80;
const int lotMax = 40;
const int maxRangeDays = 366;

final _cie11 = RegExp(r'^[0-9A-Z]{1,4}(\.[0-9A-Z]{1,4})*$');
const _severities = {'LEVE', 'MODERADA', 'GRAVE', 'DESCONOCIDA'};
const _antecedentTypes = {'PERSONAL', 'FAMILIAR', 'QUIRURGICO'};

String _trimmed(String? value) => (value ?? '').trim();

List<String> validateRange(DateSpan span, DateTime today) {
  final problems = <String>[];
  final from = span.from;
  final to = span.to;
  if (from != null && to != null) {
    if (to.isBefore(from)) {
      problems.add('order');
    } else if (to.difference(from).inDays > maxRangeDays) {
      problems.add('span');
    }
  }
  if (from != null && from.isAfter(_day(today))) problems.add('future');
  return problems;
}

List<String> validateCie11(String? code) {
  final text = _trimmed(code);
  if (text.isEmpty) return const [];
  return _cie11.hasMatch(text.toUpperCase()) ? const [] : const ['cie11'];
}

List<String> validateDeclaration(Declaration declaration, DateTime today) {
  switch (declaration) {
    case AllergyDeclaration():
      return [
        if (_trimmed(declaration.substanceCode).isEmpty) 'substanceCode',
        if (!_severities.contains(declaration.severity)) 'severity',
        if (_trimmed(declaration.reaction).length > reactionMax) 'reaction',
      ];
    case AntecedentDeclaration():
      final description = _trimmed(declaration.description);
      final relative = _trimmed(declaration.relative);
      return [
        if (!_antecedentTypes.contains(declaration.type)) 'type',
        if (description.isEmpty || description.length > descriptionMax) 'description',
        if (declaration.type == 'FAMILIAR' && relative.isEmpty) 'relative',
        if (relative.length > relativeMax) 'relative',
        ...validateCie11(declaration.cie11),
      ];
    case MedicationDeclaration():
      final name = _trimmed(declaration.name);
      return [
        if (name.isEmpty || name.length > nameMax) 'name',
        if (_trimmed(declaration.dose).length > doseMax) 'dose',
        if (_trimmed(declaration.frequency).length > doseMax) 'frequency',
      ];
    case VaccineDeclaration():
      return [
        if (_trimmed(declaration.vaccineCode).isEmpty) 'vaccineCode',
        if (declaration.doseNumber < 1 || declaration.doseNumber > 10) 'doseNumber',
        if (_day(declaration.date).isAfter(_day(today))) 'future',
        if (_trimmed(declaration.lot).length > lotMax) 'lot',
      ];
  }
}

DateTime _day(DateTime value) => DateTime.utc(value.year, value.month, value.day);

/// A `YYYY-MM-DD` day that exists, or null for a blank, malformed or impossible one (2026-02-31).
DateTime? parseDay(String text) {
  final trimmed = text.trim();
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) return null;
  final parsed = parseIsoDate(trimmed);
  return parsed != null && isoDate(parsed) == trimmed ? parsed : null;
}
