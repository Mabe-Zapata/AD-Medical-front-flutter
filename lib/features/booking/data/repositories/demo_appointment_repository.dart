import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment_doctor.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/doctor.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/reservation_result.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/booking/domain/repositories/appointment_repository.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

class DemoAppointmentRepository implements AppointmentRepository {
  const DemoAppointmentRepository(this._db);

  final DemoDatabase _db;

  /// Two made-up doctors, each with one specialty, so the demo shows the same choices as the real API.
  static const _medicinaGeneral = Specialty(id: 1, name: 'Medicina general');
  static const _hematologia = Specialty(id: 2, name: 'Hematología');
  static const _specialties = [_medicinaGeneral, _hematologia];
  static const _doctors = [
    Doctor(id: 'demo-doctor-1', name: 'Dr. Andrés Mora', specialties: [_medicinaGeneral], durationMin: 30),
    Doctor(id: 'demo-doctor-2', name: 'Dra. Lucía Vera', specialties: [_hematologia], durationMin: 30),
  ];

  static AppointmentDoctor? _contactOf(String? doctorId) {
    final doctor = _doctors.where((doctor) => doctor.id == doctorId).firstOrNull;
    return doctor == null ? null : AppointmentDoctor(id: doctor.id, name: doctor.name);
  }

  @override
  Future<List<TimeSlot>> slotsForDay(DateTime day, {String? doctorId, String? serviceId}) async {
    await _db.simulateLatency();
    final doctor = doctorId ?? _doctors.first.id;
    final window = _windowOf(serviceId);
    return [
      for (var i = 0; i < DemoDatabase.slotsPerDay; i++)
        if (window == null || _inWindow(8 + i ~/ 2, window))
          _db.slotForDoctor(day, 8 + i ~/ 2, i.isEven ? 0 : 30, doctorId: doctor),
    ];
  }

  /// Same windows as the backend: sample collection 08:00 to 10:00, consultations from 12:00.
  String? _windowOf(String? serviceId) {
    if (serviceId == null) return null;
    final service = _db.services.where((item) => item.id == serviceId).firstOrNull;
    if (service == null) return null;
    return service.name.startsWith('Toma de muestra') ? 'MANANA' : 'TARDE';
  }

  static bool _inWindow(int hour, String window) => window == 'MANANA' ? hour >= 8 && hour < 10 : hour >= 12 && hour < 17;

  @override
  Future<List<Specialty>> specialties() async {
    await _db.simulateLatency();
    return _specialties;
  }

  @override
  Future<List<Doctor>> doctors({int? specialtyId}) async {
    await _db.simulateLatency();
    return [
      for (final doctor in _doctors)
        if (specialtyId == null || doctor.specialties.any((s) => s.id == specialtyId)) doctor,
    ];
  }

  @override
  Future<ReservationResult> reserve({
    required String patientId,
    required MedicalService service,
    required TimeSlot slot,
    String? reason,
  }) async {
    await _db.simulateLatency();
    final local = branchTime(slot.startUtc);
    final fresh = _db.slotAt(DateTime(local.year, local.month, local.day), local.hour, local.minute);
    final contested =
        local.hour == DemoDatabase.contestedHour && local.minute == DemoDatabase.contestedMinute;
    if (!fresh.isAvailable || contested) {
      // Lost slots are tracked by time, the same key slotAt uses (doctor-prefixed ids would never match).
      _db.lostSlotIds.add(DemoDatabase.slotId(fresh.startUtc));
      return SlotTaken(slot);
    }
    final now = DateTime.now().toUtc();
    final appointment = Appointment(
      id: _db.nextAppointmentId(),
      patientId: patientId,
      service: service,
      slot: DemoDatabase.buildSlot(fresh.startUtc, SlotStatus.reserved),
      status: AppointmentStatus.pendingPayment,
      reason: reason,
      bookedAt: now,
      reservationExpiresAt: now.add(Appointment.reservationHold),
      // The demo has no real contact data, so the phone stays unknown on purpose.
      doctor: _contactOf(fresh.doctorId),
    );
    _db.appointments.add(appointment);
    return Reserved(appointment);
  }

  @override
  Future<List<Appointment>> appointmentsOf(String patientId) async {
    await _db.simulateLatency();
    return _db.appointments.where((a) => a.patientId == patientId).toList();
  }

  @override
  Future<Appointment> cancel({required String patientId, required String appointmentId, String? reason}) async {
    await _db.simulateLatency();
    final index = _db.appointments.indexWhere((a) => a.id == appointmentId && a.patientId == patientId);
    // Like the real API: a missing appointment and someone else's look the same.
    if (index < 0) throw const AppError(ErrorKind.forbidden, 'not found or not yours');
    final current = _db.appointments[index];
    if (!current.holdsSlot) throw const AppError(ErrorKind.conflict, 'not cancellable');
    final cancelled = current.copyWith(status: AppointmentStatus.cancelled);
    _db.appointments[index] = cancelled;
    return cancelled;
  }
}
