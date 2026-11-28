import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/clinical_history/data/repositories/http_patient_history_repository.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/entities/patient_history.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late List<http.Request> requests;

  HttpPatientHistoryRepository repository(http.Response Function(http.Request) respond) {
    requests = [];
    final client = MockClient((request) async {
      requests.add(request);
      return respond(request);
    });
    return HttpPatientHistoryRepository(
      ApiClient(client: client, baseUrl: '/api/v1', token: () => 'token', onUnauthorized: () {}),
    );
  }

  final historyJson = {
    'paciente_id': 'pac-1',
    'alergias': [
      {
        'id': 'al-1',
        'sustancia': 'Penicilina',
        'severidad': 'GRAVE',
        'reaccion': 'Urticaria',
        'estado': 'ACTIVA',
        'origen': 'REGISTRADA_MEDICO',
        'verificada': true,
        'registrada_en': '2026-09-14',
      },
    ],
    'antecedentes': [
      {
        'id': 'an-1',
        'tipo': 'FAMILIAR',
        'descripcion': 'Hipertensión',
        'parentesco': 'Madre',
        'cie11': 'BA00',
        'estado': 'ACTIVO',
        'origen': 'DECLARADA_PACIENTE',
        'verificada': false,
        'registrada_en': '2026-10-02',
      },
    ],
    'medicacion': [],
    'problemas': [],
    'vacunas': [
      {
        'id': 'va-1',
        'vacuna': 'Influenza estacional',
        'dosis_numero': 1,
        'fecha': '2026-03-10',
        'lote': 'L-9',
        'estado': 'ACTIVA',
        'origen': 'REGISTRADA_MEDICO',
        'verificada': true,
        'registrada_en': '2026-03-10',
      },
    ],
    'signos_vitales': [
      {
        'id': 'sv-1',
        'registrada_en': '2026-06-01',
        'peso_kg': 70.5,
        'talla_cm': 170,
        'pa_sistolica': 120,
        'pa_diastolica': 80,
        'frecuencia_cardiaca': 72,
        'temperatura_c': 36.6,
        'saturacion': 98,
        'corrige_a': null,
      },
    ],
  };

  test('reads the own history, translates the Spanish fields and sends the range as desde and hasta', () async {
    final repo = repository((_) => _json(historyJson));

    final history = await repo.read(DateSpan(from: DateTime(2026, 1, 1), to: DateTime(2026, 6, 30)));

    expect(requests.single.url.path, '/api/v1/me/historia');
    expect(requests.single.url.queryParameters, {'desde': '2026-01-01', 'hasta': '2026-06-30'});
    expect(history.patientId, 'pac-1');

    final allergy = history.of(HistoryKind.allergy).single;
    expect(allergy.title, 'Penicilina');
    expect(allergy.detail, 'Gravedad: Grave · Reacción: Urticaria');
    expect(allergy.declared, isFalse);
    expect(allergy.verified, isTrue);

    final antecedent = history.of(HistoryKind.antecedent).single;
    expect(antecedent.detail, 'Familiar · Familiar: Madre · CIE-11 BA00');
    expect(antecedent.declared, isTrue, reason: 'DECLARADA_PACIENTE marks what the patient declared');
    expect(antecedent.verified, isFalse, reason: 'a declaration waits for the doctor');

    expect(history.of(HistoryKind.vaccine).single.detail, 'Dosis 1 · 2026-03-10 · lote L-9');

    final vitals = history.vitals.single;
    expect(vitals.weightKg, 70.5);
    expect(vitals.systolic, 120);
    expect(vitals.isCorrection, isFalse);
  });

  test('an open range sends no desde or hasta', () async {
    final repo = repository((_) => _json(historyJson));

    await repo.read(DateSpan.all);

    expect(requests.single.url.queryParameters, isEmpty);
  });

  test('a declaration posts the allergy to its own path with the backend field names', () async {
    final repo = repository((_) => _json({'ok': true}, 201));

    await repo.declare(
      'pac-1',
      const AllergyDeclaration(substanceCode: 'HUEVO', severity: 'LEVE', reaction: 'Picazón'),
    );

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/api/v1/patients/pac-1/historia/alergias');
    expect(jsonDecode(request.body), {
      'sustancia_codigo': 'HUEVO',
      'severidad': 'LEVE',
      'reaccion': 'Picazón',
    });
  });

  test('a vaccine declaration sends the date as a day, never a date-time', () async {
    final repo = repository((_) => _json({'ok': true}, 201));

    await repo.declare(
      'pac-1',
      VaccineDeclaration(vaccineCode: 'TDAP', doseNumber: 2, date: DateTime(2026, 3, 10)),
    );

    expect(requests.single.url.path, '/api/v1/patients/pac-1/historia/vacunas');
    expect(jsonDecode(requests.single.body), {
      'vacuna_codigo': 'TDAP',
      'dosis_numero': 2,
      'fecha': '2026-03-10',
      'lote': null,
    });
  });

  test('the event log is requested one page at a time and translated', () async {
    final repo = repository(
      (_) => _json({
        'total': 1,
        'items': [
          {
            'id': 7,
            'entidad': 'antecedente',
            'accion': 'CREAR',
            'motivo': null,
            'ocurrido_en': '2026-10-02T15:04:05Z',
          },
        ],
      }),
    );

    final page = await repo.events(span: DateSpan.all, limit: 5, offset: 10);

    expect(requests.single.url.path, '/api/v1/me/historia/eventos');
    expect(requests.single.url.queryParameters, {'limit': '5', 'offset': '10'});
    expect(page.total, 1);
    expect(page.items.single.entity, 'antecedente');
    expect(page.items.single.action, 'CREAR');
  });

  test('a catalog search asks the backend for the path name with its query', () async {
    final repo = repository(
      (_) => _json({
        'items': [
          {'codigo': 'PENICILINA', 'nombre': 'Penicilina', 'categoria': 'MEDICAMENTO'},
        ],
      }),
    );

    final items = await repo.catalog('sustancias-alergia', query: 'peni');

    expect(requests.single.url.path, '/api/v1/catalogos/sustancias-alergia');
    expect(requests.single.url.queryParameters, {'limit': '20', 'q': 'peni'});
    expect(items.single.code, 'PENICILINA');
    expect(items.single.category, 'MEDICAMENTO');
  });
}
