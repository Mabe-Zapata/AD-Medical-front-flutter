import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';

/// In-memory stand-in for the REST API, shaped like the backend schema.
/// Repositories in each feature's data layer read and write through it.
class DemoDatabase {
  DemoDatabase({this.latency = const Duration(milliseconds: 600)}) {
    _seed();
  }

  static const demoEmail = 'paciente@demo.test';
  static const demoPassword = 'demo1234';

  /// Workday at the branch: 08:00–16:30, one slot every 30 minutes.
  static const slotsPerDay = 18;

  /// This slot looks free but is "taken by another patient" when confirming,
  /// to show that availability is validated again on the server.
  static const contestedHour = 10;
  static const contestedMinute = 30;

  /// Simulated network round trip.
  final Duration latency;

  final branches = const [
    Branch(id: 'branch-central', name: 'Laboratorio Central', address: 'Av. Principal 123 y Calle 5, Quito'),
    Branch(id: 'branch-north', name: 'Sede Norte', address: 'Av. del Parque 480, Quito'),
  ];

  final services = const [
    MedicalService(id: 'svc-blood', name: 'Toma de muestra de sangre', durationMin: 20, basePrice: 8),
    MedicalService(id: 'svc-urine', name: 'Toma de muestra de orina y heces', durationMin: 15, basePrice: 6),
    MedicalService(id: 'svc-consult', name: 'Consulta médica', durationMin: 30, basePrice: 25),
    MedicalService(id: 'svc-review', name: 'Revisión de resultados con el médico', durationMin: 20, basePrice: 15),
  ];

  final testTypes = const [
    LabTestType(id: 'test-cbc', code: 'HEM-CBC', name: 'Biometría hemática completa', description: 'Resumen de glóbulos rojos, glóbulos blancos y plaquetas.'),
    LabTestType(id: 'test-lip', code: 'QUI-LIP', name: 'Perfil lipídico', description: 'Colesterol y triglicéridos para la salud del corazón.', defaultUnit: 'mg/dL'),
    LabTestType(id: 'test-glu', code: 'QUI-GLU', name: 'Glucosa en ayunas', description: 'Nivel de azúcar en sangre tras 8 horas de ayuno.', defaultUnit: 'mg/dL'),
    LabTestType(id: 'test-tsh', code: 'END-TSH', name: 'Panel tiroideo', description: 'TSH y T4 libre para evaluar la función tiroidea.', defaultUnit: 'mIU/L'),
    LabTestType(id: 'test-uri', code: 'URO-EGO', name: 'Examen de orina', description: 'Examen físico y químico de la orina.'),
    LabTestType(id: 'test-lft', code: 'HEP-LFT', name: 'Función hepática', description: 'Enzimas ALT, AST y bilirrubina.', defaultUnit: 'U/L'),
    LabTestType(id: 'test-cre', code: 'QUI-CRE', name: 'Creatinina', description: 'Marcador de la función renal.', defaultUnit: 'mg/dL'),
    LabTestType(id: 'test-crp', code: 'INM-CRP', name: 'Proteína C reactiva', description: 'Marcador de inflamación.', defaultUnit: 'mg/L'),
  ];

  final patient = Patient(
    id: 'patient-demo',
    firstName: 'María',
    lastName: 'López',
    email: demoEmail,
    phone: '+593 99 123 4567',
    documentType: 'CEDULA',
    documentNumber: '1712345678',
    birthDate: DateTime(1990, 4, 12),
    roles: const ['PACIENTE'],
    permissions: const ['citas.reservar', 'citas.leer_propias', 'resultados.leer_propios'],
  );

  final appointments = <Appointment>[];
  final orders = <LabOrder>[];
  final lostSlotIds = <String>{};
  bool signedIn = false;
  int _sequence = 1000;

  String nextAppointmentId() => 'APT-${_sequence++}';

  Future<void> simulateLatency() => Future<void>.delayed(latency);

  /// Slot at a branch wall-clock time, with its current availability.
  TimeSlot slotAt(DateTime day, int hour, int minute) {
    final start = utcFromBranch(day.year, day.month, day.day, hour, minute);
    final id = slotId(start);
    final past = start.isBefore(DateTime.now().toUtc());
    // Deterministic "already booked by someone else" pattern.
    final busy = (day.day + hour * 2 + minute ~/ 30) % 5 == 0;
    final held = appointments.any((a) => a.slot.id == id && a.holdsSlot);
    final status = past
        ? SlotStatus.blocked
        : (busy || held || lostSlotIds.contains(id))
        ? SlotStatus.reserved
        : SlotStatus.available;
    return buildSlot(start, status);
  }

  static String slotId(DateTime startUtc) => 'slot-${startUtc.millisecondsSinceEpoch}';

  static TimeSlot buildSlot(DateTime startUtc, SlotStatus status) => TimeSlot(
    id: slotId(startUtc),
    startUtc: startUtc,
    endUtc: startUtc.add(const Duration(minutes: 30)),
    status: status,
  );

  void _seed() {
    final today = branchToday();
    final past = today.subtract(const Duration(days: 8));
    final ahead = today.add(const Duration(days: 3));
    final now = DateTime.now().toUtc();

    appointments
      ..add(
        Appointment(
          id: 'APT-0998',
          patientId: patient.id,
          service: services[0],
          slot: buildSlot(utcFromBranch(ahead.year, ahead.month, ahead.day, 14, 0), SlotStatus.reserved),
          status: AppointmentStatus.confirmed,
          reason: 'Control de glucosa en ayunas',
          bookedAt: now.subtract(const Duration(days: 1)),
        ),
      )
      ..add(
        Appointment(
          id: 'APT-0997',
          patientId: patient.id,
          service: services[0],
          slot: buildSlot(utcFromBranch(past.year, past.month, past.day, 9, 0), SlotStatus.blocked),
          status: AppointmentStatus.completed,
          reason: 'Chequeo anual',
          bookedAt: now.subtract(const Duration(days: 12)),
        ),
      );

    final sampled = utcFromBranch(past.year, past.month, past.day, 9, 10);
    final validated = sampled.add(const Duration(days: 1, hours: 4));
    orders
      ..add(
        LabOrder(
          id: 'ORD-0501',
          patientId: patient.id,
          doctorName: 'Dr. Andrés Mora',
          orderedAt: sampled.subtract(const Duration(hours: 1)),
          priority: OrderPriority.normal,
          status: OrderStatus.completed,
          notes: 'Chequeo anual',
          details: [
            OrderDetail(
              id: 'det-1',
              testName: testTypes[1].name,
              status: DetailStatus.completed,
              sampleTakenAt: sampled,
              resultAt: validated,
              results: [
                AnalyteResult(name: 'Colesterol total', valueNumeric: 212, unit: 'mg/dL', referenceMin: 0, referenceMax: 200, interpretation: Interpretation.high, method: 'Colorimétrico enzimático', sampleType: 'Suero', validatedAt: validated),
                AnalyteResult(name: 'Colesterol HDL', valueNumeric: 52, unit: 'mg/dL', referenceMin: 40, interpretation: Interpretation.withinReference, method: 'Colorimétrico enzimático', sampleType: 'Suero', validatedAt: validated),
                AnalyteResult(name: 'Triglicéridos', valueNumeric: 140, unit: 'mg/dL', referenceMin: 0, referenceMax: 150, interpretation: Interpretation.withinReference, method: 'Colorimétrico enzimático', sampleType: 'Suero', validatedAt: validated),
              ],
            ),
            OrderDetail(
              id: 'det-2',
              testName: testTypes[2].name,
              status: DetailStatus.completed,
              sampleTakenAt: sampled,
              resultAt: validated,
              results: [
                AnalyteResult(name: 'Glucosa en ayunas', valueNumeric: 92, unit: 'mg/dL', referenceMin: 70, referenceMax: 99, interpretation: Interpretation.withinReference, method: 'Hexoquinasa', sampleType: 'Suero', validatedAt: validated),
              ],
            ),
          ],
        ),
      )
      ..add(
        LabOrder(
          id: 'ORD-0502',
          patientId: patient.id,
          doctorName: 'Dr. Andrés Mora',
          orderedAt: now.subtract(const Duration(days: 1)),
          priority: OrderPriority.normal,
          status: OrderStatus.inProgress,
          details: [
            OrderDetail(
              id: 'det-3',
              testName: testTypes[0].name,
              status: DetailStatus.inProgress,
              sampleTakenAt: now.subtract(const Duration(hours: 20)),
            ),
            OrderDetail(id: 'det-4', testName: testTypes[3].name, status: DetailStatus.pending),
          ],
        ),
      );
  }
}
