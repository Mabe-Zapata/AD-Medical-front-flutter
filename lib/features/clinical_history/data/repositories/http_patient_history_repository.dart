import 'package:medicalbooking_portal/core/domain/personal_data.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/entities/patient_history.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/repositories/patient_history_repository.dart';

/// Talks to `/me/historia`, `/patients/{id}/historia`, `/catalogos` and translates the Spanish fields.
class HttpPatientHistoryRepository implements PatientHistoryRepository {
  const HttpPatientHistoryRepository(this._api);

  final ApiClient _api;

  @override
  Future<PatientHistory> read(DateSpan span) async {
    final json = await _api.get('/me/historia', query: _rangeQuery(span)) as Map<String, dynamic>;
    final entries = <HistoryEntry>[
      for (final e in _list(json['alergias'])) _allergy(e),
      for (final e in _list(json['antecedentes'])) _antecedent(e),
      for (final e in _list(json['medicacion'])) _medication(e),
      for (final e in _list(json['problemas'])) _problem(e),
      for (final e in _list(json['vacunas'])) _vaccine(e),
    ];
    final vitals = [for (final v in _list(json['signos_vitales'])) _vitals(v)];
    return PatientHistory(
      patientId: json['paciente_id'] as String,
      entries: entries,
      vitals: vitals,
    );
  }

  @override
  Future<HistoryEventPage> events({
    required DateSpan span,
    required int limit,
    required int offset,
  }) async {
    final query = {..._rangeQuery(span), 'limit': '$limit', 'offset': '$offset'};
    final json = await _api.get('/me/historia/eventos', query: query) as Map<String, dynamic>;
    return HistoryEventPage(
      items: [for (final e in _list(json['items'])) _event(e)],
      total: json['total'] as int,
    );
  }

  @override
  Future<void> declare(String patientId, Declaration declaration) async {
    await _api.post(_declarePath(patientId, declaration), body: _declareBody(declaration));
  }

  @override
  Future<List<CatalogOption>> catalog(String catalog, {String? query}) async {
    final params = <String, String>{'limit': '20', if (query != null && query.isNotEmpty) 'q': query};
    final json = await _api.get('/catalogos/$catalog', query: params) as Map<String, dynamic>;
    return [
      for (final item in _list(json['items']))
        CatalogOption(
          code: item['codigo'] as String,
          name: item['nombre'] as String,
          category: item['categoria'] as String?,
        ),
    ];
  }

  Map<String, String> _rangeQuery(DateSpan span) => {
    if (span.from != null) 'desde': isoDate(span.from!),
    if (span.to != null) 'hasta': isoDate(span.to!),
  };

  List<Map<String, dynamic>> _list(Object? value) =>
      (value as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  HistoryEntry _allergy(Map<String, dynamic> e) => _entry(
    e,
    HistoryKind.allergy,
    title: e['sustancia'] as String,
    detail: 'Gravedad: ${_severity(e['severidad'] as String)}'
        '${(e['reaccion'] as String?) == null ? '' : ' · Reacción: ${e['reaccion']}'}',
  );

  HistoryEntry _antecedent(Map<String, dynamic> e) => _entry(
    e,
    HistoryKind.antecedent,
    title: e['descripcion'] as String,
    detail: [
      _antecedentType(e['tipo'] as String),
      if (e['parentesco'] != null) 'Familiar: ${e['parentesco']}',
      if (e['cie11'] != null) 'CIE-11 ${e['cie11']}',
    ].join(' · '),
  );

  HistoryEntry _medication(Map<String, dynamic> e) => _entry(
    e,
    HistoryKind.medication,
    title: e['medicamento'] as String,
    detail: [e['dosis'], e['frecuencia'], if (e['inicio'] != null) 'Desde ${e['inicio']}']
        .whereType<String>()
        .join(' · '),
  );

  HistoryEntry _problem(Map<String, dynamic> e) => _entry(
    e,
    HistoryKind.problem,
    title: e['descripcion'] as String,
    detail: [if (e['cie11'] != null) 'CIE-11 ${e['cie11']}', if (e['inicio'] != null) 'Desde ${e['inicio']}']
        .join(' · '),
  );

  HistoryEntry _vaccine(Map<String, dynamic> e) => _entry(
    e,
    HistoryKind.vaccine,
    title: e['vacuna'] as String,
    detail: 'Dosis ${e['dosis_numero']} · ${e['fecha']}${e['lote'] == null ? '' : ' · lote ${e['lote']}'}',
  );

  HistoryEntry _entry(
    Map<String, dynamic> e,
    HistoryKind kind, {
    required String title,
    required String detail,
  }) => HistoryEntry(
    id: e['id'] as String,
    kind: kind,
    title: title,
    detail: detail,
    state: e['estado'] as String?,
    declared: e['origen'] == 'DECLARADA_PACIENTE',
    verified: e['verificada'] as bool,
    recordedAt: parseIsoDate(e['registrada_en']),
  );

  VitalRecord _vitals(Map<String, dynamic> v) => VitalRecord(
    id: v['id'] as String,
    recordedAt: parseIsoDate(v['registrada_en']),
    isCorrection: v['corrige_a'] != null,
    weightKg: (v['peso_kg'] as num?)?.toDouble(),
    heightCm: (v['talla_cm'] as num?)?.toDouble(),
    systolic: v['pa_sistolica'] as int?,
    diastolic: v['pa_diastolica'] as int?,
    heartRate: v['frecuencia_cardiaca'] as int?,
    temperatureC: (v['temperatura_c'] as num?)?.toDouble(),
    oxygen: v['saturacion'] as int?,
  );

  HistoryEvent _event(Map<String, dynamic> e) => HistoryEvent(
    id: e['id'] as int,
    entity: e['entidad'] as String,
    action: e['accion'] as String,
    reason: e['motivo'] as String?,
    at: DateTime.parse(e['ocurrido_en'] as String),
  );

  static String _declarePath(String patientId, Declaration declaration) {
    final path = switch (declaration) {
      AllergyDeclaration() => 'alergias',
      AntecedentDeclaration() => 'antecedentes',
      MedicationDeclaration() => 'medicacion',
      VaccineDeclaration() => 'vacunas',
    };
    return '/patients/$patientId/historia/$path';
  }

  static Map<String, dynamic> _declareBody(Declaration declaration) => switch (declaration) {
    AllergyDeclaration(:final substanceCode, :final severity, :final reaction) => {
      'sustancia_codigo': substanceCode,
      'severidad': severity,
      'reaccion': reaction,
    },
    AntecedentDeclaration(:final type, :final description, :final relative, :final cie11) => {
      'tipo': type,
      'descripcion': description,
      'parentesco': relative,
      'cie11': cie11,
    },
    MedicationDeclaration(:final name, :final dose, :final frequency, :final startDate) => {
      'medicamento': name,
      'dosis': dose,
      'frecuencia': frequency,
      'inicio': startDate == null ? null : isoDate(startDate),
    },
    VaccineDeclaration(:final vaccineCode, :final doseNumber, :final date, :final lot) => {
      'vacuna_codigo': vaccineCode,
      'dosis_numero': doseNumber,
      'fecha': isoDate(date),
      'lote': lot,
    },
  };

  static String _severity(String code) => switch (code) {
    'LEVE' => 'Leve',
    'MODERADA' => 'Moderada',
    'GRAVE' => 'Grave',
    _ => 'Desconocida',
  };

  static String _antecedentType(String code) => switch (code) {
    'FAMILIAR' => 'Familiar',
    'QUIRURGICO' => 'Quirúrgico',
    _ => 'Personal',
  };
}
