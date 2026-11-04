/// ordenes_laboratorio.estado
enum OrderStatus { requested, inProgress, completed, cancelled }

/// ordenes_laboratorio_detalle.estado
enum DetailStatus { pending, inProgress, completed, cancelled }

/// ordenes_laboratorio.prioridad
enum OrderPriority { normal, urgent }

/// resultados_laboratorio.interpretacion: classification of the value, never a diagnosis.
enum Interpretation { low, withinReference, high, notEvaluable }

/// resultados_laboratorio. Only validated rows are shown to the patient.
class AnalyteResult {
  const AnalyteResult({
    required this.name,
    this.valueText,
    this.valueNumeric,
    this.unit,
    this.referenceMin,
    this.referenceMax,
    this.interpretation,
    this.method,
    this.sampleType,
    this.validatedAt,
    this.validated,
  });

  final String name;
  final String? valueText;
  final double? valueNumeric;
  final String? unit;
  final double? referenceMin;
  final double? referenceMax;
  final Interpretation? interpretation;
  final String? method;
  final String? sampleType;
  final DateTime? validatedAt;

  /// Explicit flag for sources that do not send a validation date. The real API only returns
  /// results the patient may read, so its mapper sets this to true.
  final bool? validated;

  bool get isValidated => validated ?? validatedAt != null;
}

/// ordenes_laboratorio_detalle (+ tipos_prueba_laboratorio.nombre)
class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.testName,
    required this.status,
    this.sampleTakenAt,
    this.resultAt,
    this.results = const [],
  });

  final String id;
  final String testName;
  final DetailStatus status;
  final DateTime? sampleTakenAt;
  final DateTime? resultAt;
  final List<AnalyteResult> results;

  List<AnalyteResult> get validatedResults => results.where((r) => r.isValidated).toList();
}

/// ordenes_laboratorio. The real API does not send the doctor, the date or the test names.
class LabOrder {
  const LabOrder({
    required this.id,
    required this.patientId,
    required this.priority,
    required this.status,
    required this.details,
    this.doctorName,
    this.orderedAt,
    this.notes,
  });

  final String id;
  final String patientId;
  final String? doctorName;
  final DateTime? orderedAt;
  final OrderPriority priority;
  final OrderStatus status;
  final String? notes;
  final List<OrderDetail> details;

  bool get hasValidatedResults => details.any((d) => d.validatedResults.isNotEmpty);
}
