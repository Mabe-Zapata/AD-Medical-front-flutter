import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/entities/patient_history.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/policies/history_policy.dart';

void main() {
  final today = DateTime(2026, 11, 24);

  group('date ranges', () {
    test('an open range is always valid', () {
      expect(validateRange(DateSpan.all, today), isEmpty);
    });

    test('the final day cannot come before the first one', () {
      final span = DateSpan(from: DateTime(2026, 3, 1), to: DateTime(2026, 2, 1));
      expect(validateRange(span, today), ['order']);
    });

    test('366 days is the longest range; 367 is refused', () {
      final from = DateTime(2025, 1, 1);
      expect(validateRange(DateSpan(from: from, to: from.add(const Duration(days: 365))), today), isEmpty);
      expect(validateRange(DateSpan(from: from, to: from.add(const Duration(days: 366))), today), isEmpty);
      expect(validateRange(DateSpan(from: from, to: from.add(const Duration(days: 367))), today), ['span']);
    });

    test('a range may not start in the future', () {
      expect(validateRange(DateSpan(from: DateTime(2026, 12, 1)), today), ['future']);
    });

    test('a day that exists is parsed; an impossible or differently written one is not', () {
      expect(parseDay(' 2026-03-10 '), DateTime(2026, 3, 10));
      expect(parseDay('2026-02-31'), isNull);
      expect(parseDay('10/03/2026'), isNull);
      expect(parseDay(''), isNull);
    });
  });

  group('CIE-11 codes', () {
    test('a blank code is optional', () {
      expect(validateCie11(null), isEmpty);
      expect(validateCie11('  '), isEmpty);
    });

    test('codes are checked in upper case, with optional dotted parts', () {
      expect(validateCie11('ba00'), isEmpty);
      expect(validateCie11('BA00.1'), isEmpty);
      expect(validateCie11('BA 00'), ['cie11']);
      expect(validateCie11('BA00-'), ['cie11']);
    });
  });

  group('declarations', () {
    test('an allergy needs a substance and a known severity; the reaction has a limit', () {
      expect(
        validateDeclaration(const AllergyDeclaration(substanceCode: '', severity: 'XX'), today),
        containsAll(['substanceCode', 'severity']),
      );
      expect(
        validateDeclaration(
          AllergyDeclaration(substanceCode: 'HUEVO', severity: 'LEVE', reaction: 'x' * 301),
          today,
        ),
        ['reaction'],
      );
    });

    test('a family antecedent needs the relative; a personal one does not', () {
      expect(
        validateDeclaration(
          const AntecedentDeclaration(type: 'FAMILIAR', description: 'Asma'),
          today,
        ),
        ['relative'],
      );
      expect(
        validateDeclaration(
          const AntecedentDeclaration(type: 'PERSONAL', description: 'Asma'),
          today,
        ),
        isEmpty,
      );
    });

    test('a description is required and limited to 500 characters', () {
      expect(
        validateDeclaration(const AntecedentDeclaration(type: 'PERSONAL', description: '  '), today),
        ['description'],
      );
      expect(
        validateDeclaration(
          AntecedentDeclaration(type: 'PERSONAL', description: 'x' * 501),
          today,
        ),
        ['description'],
      );
    });

    test('a medication needs a name', () {
      expect(validateDeclaration(const MedicationDeclaration(name: ' '), today), ['name']);
    });

    test('a vaccine dose goes from 1 to 10 and cannot be dated in the future', () {
      expect(
        validateDeclaration(
          VaccineDeclaration(vaccineCode: 'INFLUENZA', doseNumber: 11, date: DateTime(2026, 3, 10)),
          today,
        ),
        ['doseNumber'],
      );
      expect(
        validateDeclaration(
          VaccineDeclaration(vaccineCode: 'INFLUENZA', doseNumber: 1, date: DateTime(2026, 12, 1)),
          today,
        ),
        ['future'],
      );
    });
  });
}
