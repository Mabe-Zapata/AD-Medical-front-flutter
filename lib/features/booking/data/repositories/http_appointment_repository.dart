import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/domain/ids.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/core/http/idempotency_key.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/reservation_result.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/booking/domain/repositories/appointment_repository.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

/// Talks to /api/v1/availability and /api/v1/appointments.
///
/// The API cannot list a patient's appointments, so the ones created in this app run are
/// remembered here (keyed by patient, so two people on one browser never mix).
class HttpAppointmentRepository implements AppointmentRepository {
  HttpAppointmentRepository(this._api, {this._now = DateTime.now});

  final ApiClient _api;
  final DateTime Function() _now;
  final List<Appointment> _mine = [];

  @override
  Future<List<TimeSlot>> slotsForDay(DateTime day) async {
    final from = utcFromBranch(day.year, day.month, day.day, 0, 0);
    final json =
        await _api.get(
              '/availability',
              query: {'desde': _offsetIso(from), 'hasta': _offsetIso(from.add(const Duration(days: 1)))},
            )
            as Map<String, dynamic>;
    return [for (final item in json['items'] as List) _slot(item as Map<String, dynamic>)];
  }

  @override
  Future<ReservationResult> reserve({
    required String patientId,
    required MedicalService service,
    required TimeSlot slot,
    String? reason,
  }) async {
    if (!isUuid(service.id)) {
      throw const AppError(ErrorKind.validation, 'service id is not a UUID (see SERVICES_JSON)');
    }
    try {
      final json =
          await _api.post(
                '/appointments',
                // One key per attempt: a new reservation must never replay an old one.
                headers: {'Idempotency-Key': newIdempotencyKey()},
                body: {'horario_id': slot.id, 'servicio_id': service.id, 'motivo': ?reason},
              )
              as Map<String, dynamic>;
      final appointment = _appointment(json, patientId: patientId, service: service, slot: slot);
      _mine.insert(0, appointment);
      return Reserved(appointment);
    } on AppError catch (error) {
      // 409: another patient got the slot first.
      if (error.kind == ErrorKind.conflict) return SlotTaken(slot);
      rethrow;
    }
  }

  @override
  Future<List<Appointment>> appointmentsOf(String patientId) async =>
      _mine.where((a) => a.patientId == patientId).toList();

  @override
  Future<Appointment> cancel({required String patientId, required String appointmentId}) async {
    final json = await _api.post('/appointments/$appointmentId/cancel') as Map<String, dynamic>?;
    final index = _mine.indexWhere((a) => a.id == appointmentId && a.patientId == patientId);
    if (index < 0) throw const AppError(ErrorKind.notFound, 'appointment is not known by this session');
    final status = json?['estado'] is String ? _status(json!['estado'] as String) : AppointmentStatus.cancelled;
    return _mine[index] = _mine[index].copyWith(status: status);
  }

  TimeSlot _slot(Map<String, dynamic> json) => TimeSlot(
    id: json['horario_id'] as String,
    startUtc: DateTime.parse(json['inicio_utc'] as String).toUtc(),
    endUtc: DateTime.parse(json['fin_utc'] as String).toUtc(),
    // The API only lists free slots.
    status: SlotStatus.available,
    doctorId: json['medico_id'] as String,
  );

  Appointment _appointment(
    Map<String, dynamic> json, {
    required String patientId,
    required MedicalService service,
    required TimeSlot slot,
  }) {
    final expires = json['expiracion_reserva'];
    return Appointment(
      id: json['id'] as String,
      patientId: patientId,
      service: service,
      slot: TimeSlot(
        id: slot.id,
        startUtc: slot.startUtc,
        endUtc: slot.endUtc,
        status: SlotStatus.reserved,
        doctorId: slot.doctorId,
      ),
      status: _status(json['estado'] as String),
      reason: json['motivo'] as String?,
      bookedAt: _now().toUtc(),
      reservationExpiresAt: expires is String ? DateTime.parse(expires).toUtc() : null,
    );
  }

  AppointmentStatus _status(String code) => switch (code) {
    'PENDIENTE_PAGO' => AppointmentStatus.pendingPayment,
    'CONFIRMADA' => AppointmentStatus.confirmed,
    'COMPLETADA' => AppointmentStatus.completed,
    'CANCELADA' => AppointmentStatus.cancelled,
    'EXPIRADA' => AppointmentStatus.expired,
    'NO_ASISTIO' => AppointmentStatus.noShow,
    _ => throw AppError(ErrorKind.unknown, 'unknown appointment status $code'),
  };

  /// ISO-8601 with an explicit offset, as the API requires.
  String _offsetIso(DateTime utc) => '${utc.toUtc().toIso8601String().replaceFirst('Z', '')}+00:00';
}
