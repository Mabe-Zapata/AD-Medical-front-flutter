import 'package:medicalbooking_portal/features/clinical_history/domain/entities/patient_history.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/repositories/patient_history_repository.dart';

/// In-memory history for the demo mode. A declaration waits unconfirmed, as it would for the API.
class DemoPatientHistoryRepository implements PatientHistoryRepository {
  DemoPatientHistoryRepository({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const patientId = 'demo-patient';

  final DateTime Function() _now;
  final _entries = <HistoryEntry>[
    HistoryEntry(
      id: 'demo-allergy-1',
      kind: HistoryKind.allergy,
      title: 'Penicilina',
      detail: 'Gravedad: Grave · Reacción: Urticaria',
      state: 'ACTIVA',
      declared: false,
      verified: true,
      recordedAt: DateTime.utc(2026, 9, 14),
    ),
    HistoryEntry(
      id: 'demo-antecedent-1',
      kind: HistoryKind.antecedent,
      title: 'Hipertensión esencial',
      detail: 'Familiar: Madre · CIE-11 BA00',
      state: 'ACTIVO',
      declared: true,
      verified: false,
      recordedAt: DateTime.utc(2026, 10, 2),
    ),
    HistoryEntry(
      id: 'demo-vaccine-1',
      kind: HistoryKind.vaccine,
      title: 'Influenza estacional',
      detail: 'Dosis 1 · 2026-03-10',
      state: 'ACTIVA',
      declared: false,
      verified: true,
      recordedAt: DateTime.utc(2026, 3, 10),
    ),
  ];
  final _events = <HistoryEvent>[];
  var _nextEventId = 1;

  @override
  Future<PatientHistory> read(DateSpan span) async {
    final inRange = _entries.where((entry) => _inSpan(entry.recordedAt, span)).toList();
    return PatientHistory(patientId: patientId, entries: inRange, vitals: const []);
  }

  @override
  Future<HistoryEventPage> events({
    required DateSpan span,
    required int limit,
    required int offset,
  }) async {
    final inRange = _events.where((event) => _inSpan(event.at, span)).toList().reversed.toList();
    final page = inRange.skip(offset).take(limit).toList();
    return HistoryEventPage(items: page, total: inRange.length);
  }

  @override
  Future<void> declare(String patientId, Declaration declaration) async {
    final kind = _kindOf(declaration);
    final now = _now().toUtc();
    final id = 'demo-declared-${_nextEventId++}';
    _entries.add(
      HistoryEntry(
        id: id,
        kind: kind,
        title: _titleOf(declaration),
        detail: _detailOf(declaration),
        state: kind == HistoryKind.antecedent ? 'ACTIVO' : 'ACTIVA',
        declared: true,
        verified: false,
        recordedAt: now,
      ),
    );
    _events.add(
      HistoryEvent(
        id: _nextEventId++,
        entity: _entityOf(kind),
        action: 'CREAR',
        reason: null,
        at: now,
      ),
    );
  }

  @override
  Future<List<CatalogOption>> catalog(String catalog, {String? query}) async {
    final items = switch (catalog) {
      'sustancias-alergia' => _allergens,
      'vacunas' => _vaccines,
      _ => _cie11,
    };
    final text = (query ?? '').trim().toLowerCase();
    return text.isEmpty ? items : items.where((item) => item.name.toLowerCase().contains(text)).toList();
  }

  static bool _inSpan(DateTime? moment, DateSpan span) {
    if (moment == null) return span.from == null && span.to == null;
    final day = DateTime.utc(moment.year, moment.month, moment.day);
    if (span.from != null && day.isBefore(span.from!)) return false;
    if (span.to != null && day.isAfter(span.to!)) return false;
    return true;
  }

  static HistoryKind _kindOf(Declaration declaration) => switch (declaration) {
    AllergyDeclaration() => HistoryKind.allergy,
    AntecedentDeclaration() => HistoryKind.antecedent,
    MedicationDeclaration() => HistoryKind.medication,
    VaccineDeclaration() => HistoryKind.vaccine,
  };

  static String _entityOf(HistoryKind kind) => switch (kind) {
    HistoryKind.allergy => 'alergia',
    HistoryKind.antecedent => 'antecedente',
    HistoryKind.medication => 'medicacion',
    HistoryKind.problem => 'problema',
    HistoryKind.vaccine => 'vacuna',
  };

  static String _titleOf(Declaration declaration) => switch (declaration) {
    AllergyDeclaration(:final substanceCode) => _allergens.firstWhere((a) => a.code == substanceCode).name,
    AntecedentDeclaration(:final description) => description,
    MedicationDeclaration(:final name) => name,
    VaccineDeclaration(:final vaccineCode) => _vaccines.firstWhere((v) => v.code == vaccineCode).name,
  };

  static String _detailOf(Declaration declaration) => switch (declaration) {
    AllergyDeclaration(:final severity) => 'Gravedad: $severity',
    AntecedentDeclaration(:final type) => type,
    MedicationDeclaration(:final dose) => dose ?? 'Sin dosis registrada',
    VaccineDeclaration(:final doseNumber, :final date) => 'Dosis $doseNumber · ${date.toIso8601String().substring(0, 10)}',
  };

  static const _allergens = [
    CatalogOption(code: 'PENICILINA', name: 'Penicilina', category: 'MEDICAMENTO'),
    CatalogOption(code: 'AMOXICILINA', name: 'Amoxicilina', category: 'MEDICAMENTO'),
    CatalogOption(code: 'CACAHUATE', name: 'Maní (cacahuate)', category: 'ALIMENTO'),
    CatalogOption(code: 'HUEVO', name: 'Huevo', category: 'ALIMENTO'),
    CatalogOption(code: 'LATEX', name: 'Látex', category: 'LATEX'),
    CatalogOption(code: 'POLEN', name: 'Polen', category: 'AMBIENTAL'),
  ];

  static const _vaccines = [
    CatalogOption(code: 'INFLUENZA', name: 'Influenza estacional'),
    CatalogOption(code: 'COVID19', name: 'COVID-19'),
    CatalogOption(code: 'HEPATITIS_B', name: 'Hepatitis B'),
    CatalogOption(code: 'TDAP', name: 'Tétanos, difteria y tos ferina (Tdap)'),
  ];

  static const _cie11 = [
    CatalogOption(code: 'BA00', name: 'Hipertensión esencial (primaria)'),
    CatalogOption(code: '5A10', name: 'Diabetes mellitus tipo 1'),
    CatalogOption(code: '5A11', name: 'Diabetes mellitus tipo 2'),
    CatalogOption(code: 'CA23', name: 'Asma'),
  ];
}
