import 'package:medicalbooking_portal/features/clinical_history/domain/entities/patient_history.dart';

/// Spanish copy for the clinical history screens. Keys come from the domain policies and the backend's vocabulary.
String kindTitle(HistoryKind kind) => switch (kind) {
  HistoryKind.allergy => 'Alergias',
  HistoryKind.antecedent => 'Antecedentes',
  HistoryKind.medication => 'Medicación',
  HistoryKind.problem => 'Diagnósticos',
  HistoryKind.vaccine => 'Vacunas',
};

const severityOptions = [
  ('LEVE', 'Leve'),
  ('MODERADA', 'Moderada'),
  ('GRAVE', 'Grave'),
  ('DESCONOCIDA', 'No lo sé'),
];

const antecedentTypeOptions = [
  ('PERSONAL', 'Personal'),
  ('FAMILIAR', 'Familiar'),
  ('QUIRURGICO', 'Quirúrgico'),
];

String stateLabel(String? state) => switch (state) {
  null => '',
  'ACTIVA' || 'ACTIVO' => 'Activa',
  'SUSPENDIDA' || 'SUSPENDIDO' => 'Suspendida',
  'INACTIVA' || 'INACTIVO' => 'Inactiva',
  'RESUELTA' || 'RESUELTO' => 'Resuelta',
  _ => 'Estado registrado',
};

/// What a field's problem key says in Spanish. The keys are the ones `validateDeclaration` and `validateRange` return.
String problemText(String key) => switch (key) {
  'substanceCode' => 'Elige la sustancia.',
  'severity' => 'Elige la gravedad.',
  'reaction' => 'La reacción es demasiado larga (300 caracteres como máximo).',
  'type' => 'Elige el tipo.',
  'description' => 'Escribe una descripción (500 caracteres como máximo).',
  'relative' => 'Indica el familiar (50 caracteres como máximo).',
  'cie11' => 'Escribe un código CIE-11 válido, por ejemplo BA00.',
  'name' => 'Escribe el medicamento (150 caracteres como máximo).',
  'dose' => 'La dosis es demasiado larga (80 caracteres como máximo).',
  'frequency' => 'La frecuencia es demasiado larga (80 caracteres como máximo).',
  'vaccineCode' => 'Elige la vacuna.',
  'doseNumber' => 'La dosis va del 1 al 10.',
  'future' => 'La fecha no puede ser futura.',
  'lot' => 'El lote es demasiado largo (40 caracteres como máximo).',
  'date' => 'Usa el formato año-mes-día, por ejemplo 2026-03-10.',
  'order' => 'La fecha final es anterior a la inicial.',
  'span' => 'El rango no puede pasar de 366 días.',
  _ => 'Revisa este dato.',
};

/// Event log lines. The patient never sees who made the change.
String eventEntity(String entity) => switch (entity) {
  'alergia' => 'Alergia',
  'antecedente' => 'Antecedente',
  'medicacion' => 'Medicación',
  'problema' => 'Diagnóstico',
  'vacuna' => 'Vacuna',
  'signos_vitales' => 'Signos vitales',
  _ => 'Registro',
};

String eventAction(String action) => switch (action) {
  'CREAR' => 'registrado',
  'VERIFICAR' => 'confirmado por tu médico',
  'ESTADO' => 'cambió de estado',
  'CORREGIR' => 'corregido',
  _ => 'actualizado',
};

String vitalMetrics(VitalRecord record) => [
  if (record.weightKg != null) 'Peso ${_number(record.weightKg!)} kg',
  if (record.heightCm != null) 'Talla ${_number(record.heightCm!)} cm',
  if (record.systolic != null && record.diastolic != null) 'PA ${record.systolic}/${record.diastolic} mmHg',
  if (record.heartRate != null) 'FC ${record.heartRate} lpm',
  if (record.temperatureC != null) 'Temp. ${_number(record.temperatureC!)} °C',
  if (record.oxygen != null) 'SpO₂ ${record.oxygen} %',
].join(' · ');

String _number(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

/// Range presets offered above the list. The last one is the whole history.
enum RangePreset { lastMonth, lastSixMonths, lastYear, all }

extension RangePresetLabel on RangePreset {
  String get label => switch (this) {
    RangePreset.lastMonth => 'Último mes',
    RangePreset.lastSixMonths => 'Últimos 6 meses',
    RangePreset.lastYear => 'Último año',
    RangePreset.all => 'Todo',
  };
}
