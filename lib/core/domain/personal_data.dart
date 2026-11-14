/// Sex registered at birth. The backend only accepts `M` or `F`, because the clinical reference ranges
/// (hemoglobin, ferritin, MCV) are defined for those two groups.
enum BiologicalSex {
  female('F', 'Femenino'),
  male('M', 'Masculino');

  const BiologicalSex(this.code, this.label);

  /// What the API sends and returns.
  final String code;

  /// What the patient reads.
  final String label;

  static BiologicalSex? fromCode(Object? code) => values.where((s) => s.code == code).firstOrNull;
}

/// Same limit as the backend: an age above this is a typing mistake.
const maxAgeYears = 120;

/// True when [birth] is a plausible birth date on [today]: not in the future and at most [maxAgeYears] ago.
/// Only the calendar day matters, so the time of day never decides it.
bool isValidBirthDate(DateTime birth, DateTime today) {
  final day = DateTime(birth.year, birth.month, birth.day);
  final now = DateTime(today.year, today.month, today.day);
  final oldest = DateTime(now.year - maxAgeYears, now.month, now.day);
  return !day.isAfter(now) && !day.isBefore(oldest);
}

/// `2026-11-14`, the format of the API (a date, never a date-time, so no time zone can move it).
String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// The date of a `YYYY-MM-DD` value, or null when it is missing or malformed.
DateTime? parseIsoDate(Object? value) {
  if (value is! String) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
  if (match == null) return null;
  return DateTime(int.parse(match[1]!), int.parse(match[2]!), int.parse(match[3]!));
}

/// `14/11/1992`, how the patient reads a date.
String birthDateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
