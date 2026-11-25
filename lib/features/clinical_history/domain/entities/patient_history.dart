// The patient's own clinical history, as the portal reads it. Field names are English; the backend's
// Spanish fields are translated in the data layer.

/// What kind of entry a history line is.
enum HistoryKind { allergy, antecedent, medication, problem, vaccine }

/// One line of the history: an allergy, an antecedent, a medication, a problem or a vaccine.
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.state,
    required this.declared,
    required this.verified,
    required this.recordedAt,
  });

  final String id;
  final HistoryKind kind;
  final String title;
  final String detail;

  /// The state as the backend names it (ACTIVA, ACTIVO, SUSPENDIDA, ...). Null when the kind has none.
  final String? state;

  /// True when the patient declared it, false when a professional recorded it.
  final bool declared;

  /// False while a patient's declaration waits for a doctor's confirmation.
  final bool verified;
  final DateTime? recordedAt;
}

/// A set of vital signs taken at an appointment, or a correction of one.
class VitalRecord {
  const VitalRecord({
    required this.id,
    required this.recordedAt,
    required this.isCorrection,
    this.weightKg,
    this.heightCm,
    this.systolic,
    this.diastolic,
    this.heartRate,
    this.temperatureC,
    this.oxygen,
  });

  final String id;
  final DateTime? recordedAt;
  final bool isCorrection;
  final double? weightKg;
  final double? heightCm;
  final int? systolic;
  final int? diastolic;
  final int? heartRate;
  final double? temperatureC;
  final int? oxygen;
}

class PatientHistory {
  const PatientHistory({required this.patientId, required this.entries, required this.vitals});

  final String patientId;
  final List<HistoryEntry> entries;
  final List<VitalRecord> vitals;

  /// The entries of one kind, active first, as the backend orders them.
  List<HistoryEntry> of(HistoryKind kind) => entries.where((entry) => entry.kind == kind).toList();
}

/// One movement in the history's event log. The patient never sees who made it.
class HistoryEvent {
  const HistoryEvent({
    required this.id,
    required this.entity,
    required this.action,
    required this.reason,
    required this.at,
  });

  final int id;
  final String entity;
  final String action;
  final String? reason;
  final DateTime at;
}

class HistoryEventPage {
  const HistoryEventPage({required this.items, required this.total});

  final List<HistoryEvent> items;
  final int total;
}

/// An item of a catalog the patient can pick from (allergens, vaccines, CIE-11 codes).
class CatalogOption {
  const CatalogOption({required this.code, required this.name, this.category});

  final String code;
  final String name;
  final String? category;
}

/// Calendar days, inclusive on both sides. Either side may be open.
class DateSpan {
  const DateSpan({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  static const all = DateSpan();
}

/// What the patient can declare. Problems are a doctor's judgement, so they are not here.
sealed class Declaration {
  const Declaration();
}

class AllergyDeclaration extends Declaration {
  const AllergyDeclaration({required this.substanceCode, required this.severity, this.reaction});

  final String substanceCode;
  final String severity;
  final String? reaction;
}

class AntecedentDeclaration extends Declaration {
  const AntecedentDeclaration({required this.type, required this.description, this.relative, this.cie11});

  final String type;
  final String description;
  final String? relative;
  final String? cie11;
}

class MedicationDeclaration extends Declaration {
  const MedicationDeclaration({required this.name, this.dose, this.frequency, this.startDate});

  final String name;
  final String? dose;
  final String? frequency;
  final DateTime? startDate;
}

class VaccineDeclaration extends Declaration {
  const VaccineDeclaration({required this.vaccineCode, required this.doseNumber, required this.date, this.lot});

  final String vaccineCode;
  final int doseNumber;
  final DateTime date;
  final String? lot;
}
