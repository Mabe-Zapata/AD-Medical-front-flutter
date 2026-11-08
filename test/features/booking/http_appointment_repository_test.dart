import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/data/repositories/http_appointment_repository.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/reservation_result.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

const _serviceId = '11111111-2222-4333-8444-555555555555';
const _slotId = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';
const _service = MedicalService(id: _serviceId, name: 'Toma de sangre', durationMin: 20, basePrice: 8);
final _slot = TimeSlot(
  id: _slotId,
  startUtc: DateTime.utc(2026, 11, 4, 14),
  endUtc: DateTime.utc(2026, 11, 4, 14, 30),
  status: SlotStatus.available,
  doctorId: 'doc-1',
);

http.Response _json(Object body, int status) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

HttpAppointmentRepository _repo(MockClient client) => HttpAppointmentRepository(
  ApiClient(client: client, baseUrl: 'http://api.test/api/v1', token: () => 'jwt'),
  now: () => DateTime.utc(2026, 11, 3, 12),
);

void main() {
  test('asks for the whole branch day in UTC and maps only free slots', () async {
    late Uri seen;
    final repo = _repo(
      MockClient((request) async {
        seen = request.url;
        return _json({
          'items': [
            {
              'horario_id': _slotId,
              'medico_id': 'doc-1',
              'inicio_utc': '2026-11-04T14:00:00+00:00',
              'fin_utc': '2026-11-04T14:30:00+00:00',
            },
          ],
        }, 200);
      }),
    );

    final slots = await repo.slotsForDay(DateTime(2026, 11, 4));

    // Branch midnight (UTC-5) is 05:00 UTC.
    expect(seen.queryParameters['desde'], '2026-11-04T05:00:00.000+00:00');
    expect(seen.queryParameters['hasta'], '2026-11-05T05:00:00.000+00:00');
    expect(slots.single.id, _slotId);
    expect(slots.single.isAvailable, isTrue);
    expect(slots.single.doctorId, 'doc-1');
    expect(branchTime(slots.single.startUtc).hour, 9);
  });

  test('reserves with a fresh Idempotency-Key and remembers the appointment', () async {
    late http.Request seen;
    final repo = _repo(
      MockClient((request) async {
        seen = request;
        return _json({
          'id': 'apt-1',
          'estado': 'PENDIENTE_PAGO',
          'horario_id': _slotId,
          'servicio_id': _serviceId,
          'motivo': 'chequeo',
          'expiracion_reserva': '2026-11-03T12:15:00+00:00',
        }, 201);
      }),
    );

    final result = await repo.reserve(patientId: 'u1', service: _service, slot: _slot, reason: 'chequeo');

    final appointment = (result as Reserved).appointment;
    expect(appointment.status, AppointmentStatus.pendingPayment);
    expect(appointment.reservationExpiresAt, DateTime.utc(2026, 11, 3, 12, 15));
    expect(jsonDecode(seen.body), {'horario_id': _slotId, 'servicio_id': _serviceId, 'motivo': 'chequeo'});
    expect(seen.headers['Idempotency-Key'], isNotEmpty);
    expect((await repo.appointmentsOf('u1')).single.id, 'apt-1');
    expect(await repo.appointmentsOf('someone-else'), isEmpty);
  });

  test('omits the reason when there is none', () async {
    late http.Request seen;
    final repo = _repo(
      MockClient((request) async {
        seen = request;
        return _json({'id': 'a', 'estado': 'PENDIENTE_PAGO', 'horario_id': _slotId, 'servicio_id': _serviceId}, 201);
      }),
    );
    await repo.reserve(patientId: 'u1', service: _service, slot: _slot);
    expect(jsonDecode(seen.body), {'horario_id': _slotId, 'servicio_id': _serviceId});
  });

  test('a 409 means another patient took the slot', () async {
    final repo = _repo(MockClient((_) async => _json({'detail': 'slot unavailable'}, 409)));
    expect(await repo.reserve(patientId: 'u1', service: _service, slot: _slot), isA<SlotTaken>());
  });

  test('other failures are thrown, and a service that is not a UUID is refused before the request', () async {
    var requests = 0;
    final repo = _repo(
      MockClient((_) async {
        requests++;
        return _json({'detail': 'down'}, 503);
      }),
    );

    await expectLater(
      repo.reserve(patientId: 'u1', service: _service, slot: _slot),
      throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.unavailable)),
    );
    const demoService = MedicalService(id: 'svc-blood', name: 'x', durationMin: 1, basePrice: 1);
    await expectLater(
      repo.reserve(patientId: 'u1', service: demoService, slot: _slot),
      throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.validation)),
    );
    expect(requests, 1);
  });

  test('cancels a known appointment and reports it as cancelled', () async {
    final repo = _repo(
      MockClient((request) async {
        if (request.url.path.endsWith('/cancel')) return _json({'id': 'apt-1', 'estado': 'CANCELADA'}, 200);
        return _json({'id': 'apt-1', 'estado': 'PENDIENTE_PAGO', 'horario_id': _slotId, 'servicio_id': _serviceId}, 201);
      }),
    );
    await repo.reserve(patientId: 'u1', service: _service, slot: _slot);

    final cancelled = await repo.cancel(patientId: 'u1', appointmentId: 'apt-1');

    expect(cancelled.status, AppointmentStatus.cancelled);
    expect((await repo.appointmentsOf('u1')).single.holdsSlot, isFalse);
  });

  test('cancelling someone else\'s appointment surfaces the API refusal', () async {
    final repo = _repo(MockClient((_) async => _json({'detail': 'forbidden'}, 403)));
    await expectLater(
      repo.cancel(patientId: 'u1', appointmentId: 'apt-9'),
      throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.forbidden)),
    );
  });
}
