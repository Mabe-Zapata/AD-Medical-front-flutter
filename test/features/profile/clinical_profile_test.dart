import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/domain/personal_data.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/profile/data/repositories/http_clinical_profile_repository.dart';
import 'package:medicalbooking_portal/features/profile/domain/entities/clinical_profile.dart';
import 'package:medicalbooking_portal/features/profile/domain/policies/clinical_profile_policy.dart';
import 'package:medicalbooking_portal/features/profile/domain/repositories/clinical_profile_repository.dart';
import 'package:medicalbooking_portal/features/profile/domain/usecases/load_clinical_profile.dart';
import 'package:medicalbooking_portal/features/profile/domain/usecases/save_clinical_profile.dart';
import 'package:medicalbooking_portal/features/profile/presentation/controllers/clinical_profile_controller.dart';

class _Recording implements ClinicalProfileRepository {
  final saved = <ClinicalProfile>[];

  @override
  Future<void> save(ClinicalProfile profile) async => saved.add(profile);

  @override
  Future<ClinicalProfile?> read() async => saved.isEmpty ? null : saved.last;
}

final _today = DateTime(2026, 11, 14);
final _born = DateTime(1992, 5, 14);

ClinicalProfile _profile({int altitude = 2850, bool smoker = false, int? cigarettes}) => ClinicalProfile(
  altitudeM: altitude,
  smoker: smoker,
  sex: BiologicalSex.female,
  birthDate: _born,
  cigarettesPerDay: cigarettes,
);

ApiClient _apiReplying(String body, {int status = 200}) => ApiClient(
  client: MockClient((_) async => http.Response(body, status, headers: {'content-type': 'application/json'})),
  baseUrl: 'http://api.test/api/v1',
  token: () => 'jwt',
);

void main() {
  group('profileProblems', () {
    List<ProfileProblem> problems({int? altitudeM, bool? smoker, int? cigarettes, BiologicalSex? sex = BiologicalSex.female, DateTime? birthDate}) =>
        profileProblems(
          altitudeM: altitudeM,
          smoker: smoker,
          cigarettes: cigarettes,
          sex: sex,
          birthDate: birthDate ?? _born,
          now: _today,
        );

    test('accepts a non-smoker and a smoker with their count', () {
      expect(problems(altitudeM: 2850, smoker: false), isEmpty);
      expect(problems(altitudeM: 0, smoker: true, cigarettes: 10), isEmpty);
    });

    test('asks for sex and birth date too', () {
      expect(problems(altitudeM: 2850, smoker: false, sex: null), [ProfileProblem.sex]);
      expect(
        profileProblems(altitudeM: 2850, smoker: false, sex: BiologicalSex.male, now: _today),
        [ProfileProblem.birthDate],
      );
    });

    test('refuses a birth date in the future or more than 120 years ago', () {
      expect(problems(altitudeM: 2850, smoker: false, birthDate: DateTime(2026, 11, 15)), [ProfileProblem.birthDate]);
      expect(problems(altitudeM: 2850, smoker: false, birthDate: DateTime(1906, 11, 13)), [ProfileProblem.birthDate]);
      expect(problems(altitudeM: 2850, smoker: false, birthDate: DateTime(2026, 11, 14)), isEmpty);
      expect(problems(altitudeM: 2850, smoker: false, birthDate: DateTime(1906, 11, 14)), isEmpty);
    });

    test('asks for everything the backend requires', () {
      expect(problems(), [ProfileProblem.altitude, ProfileProblem.smoking]);
      expect(problems(altitudeM: 100, smoker: true), [ProfileProblem.cigarettes]);
    });

    test('keeps the backend limits', () {
      expect(problems(altitudeM: maxAltitudeM + 1, smoker: false), [ProfileProblem.altitude]);
      expect(problems(altitudeM: maxAltitudeM, smoker: false), isEmpty);
      expect(problems(altitudeM: 100, smoker: true, cigarettes: maxCigarettesPerDay + 1), [
        ProfileProblem.cigarettes,
      ]);
    });
  });

  group('SaveClinicalProfile', () {
    test('refuses an incomplete profile without calling the repository', () async {
      final repository = _Recording();

      await expectLater(
        SaveClinicalProfile(repository)(_profile(altitude: 100, smoker: true)),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.validation)),
      );
      expect(repository.saved, isEmpty);
    });

    test('saves a valid profile', () async {
      final repository = _Recording();

      await SaveClinicalProfile(repository)(_profile());

      expect(repository.saved.single.altitudeM, 2850);
    });
  });

  group('reading the profile back', () {
    test('the repository returns what the backend stored', () async {
      final api = _apiReplying(
        '{"altitud_residencia_m":2850,"fumador":true,"cigarrillos_dia":5,"sexo":"F","fecha_nacimiento":"1992-05-14"}',
      );

      final profile = await HttpClinicalProfileRepository(api).read();

      expect([profile!.altitudeM, profile.smoker, profile.cigarettesPerDay], [2850, true, 5]);
      expect(profile.sex, BiologicalSex.female);
      expect(profile.birthDate, DateTime(1992, 5, 14));
    });

    test('a profile with altitude and smoking but no sex or birth date reads as not complete', () async {
      // What an older backend (or an account that never declared them) answers.
      final api = _apiReplying('{"altitud_residencia_m":2850,"fumador":false,"cigarrillos_dia":null,"sexo":null,"fecha_nacimiento":null}');

      expect(await HttpClinicalProfileRepository(api).read(), isNull);
    });

    test('an undeclared profile (nulls) reads as not complete', () async {
      final api = _apiReplying('{"altitud_residencia_m":null,"fumador":null,"cigarrillos_dia":null}');

      expect(await HttpClinicalProfileRepository(api).read(), isNull);
    });

    test('the controller remembers the stored profile so the portal stops asking', () async {
      final repository = _Recording()..saved.add(_profile());
      final controller = ClinicalProfileController(
        save: SaveClinicalProfile(repository),
        load: LoadClinicalProfile(repository),
      );

      await controller.load('p1');

      expect(controller.of('p1')!.altitudeM, 2850);
    });

    test('a failed read keeps the prompt instead of raising', () async {
      final controller = ClinicalProfileController(
        save: SaveClinicalProfile(_Recording()),
        load: LoadClinicalProfile(HttpClinicalProfileRepository(_apiReplying('{}', status: 503))),
      );

      await controller.load('p1');

      expect(controller.of('p1'), isNull);
    });
  });

  group('HttpClinicalProfileRepository', () {
    Future<Map<String, dynamic>> sent(ClinicalProfile profile) async {
      http.Request? captured;
      final api = ApiClient(
        client: MockClient((request) async {
          captured = request;
          return http.Response('{}', 200, headers: {'content-type': 'application/json'});
        }),
        baseUrl: 'http://api.test/api/v1',
        token: () => 'jwt',
      );

      await HttpClinicalProfileRepository(api).save(profile);

      expect(captured!.method, 'PUT');
      expect(captured!.url.path, '/api/v1/me/perfil-clinico');
      expect(captured!.headers['Authorization'], 'Bearer jwt');
      return jsonDecode(captured!.body) as Map<String, dynamic>;
    }

    test('a non-smoker sends fumador false and no cigarette count', () async {
      expect(await sent(_profile(cigarettes: 5)), {
        'altitud_residencia_m': 2850,
        'fumador': false,
        'cigarrillos_dia': null,
        'sexo': 'F',
        'fecha_nacimiento': '1992-05-14',
      });
    });

    test('a smoker sends the count', () async {
      expect(await sent(_profile(altitude: 0, smoker: true, cigarettes: 12)), {
        'altitud_residencia_m': 0,
        'fumador': true,
        'cigarrillos_dia': 12,
        'sexo': 'F',
        'fecha_nacimiento': '1992-05-14',
      });
    });
  });
}
