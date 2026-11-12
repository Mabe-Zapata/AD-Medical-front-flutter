import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/profile/domain/entities/clinical_profile.dart';
import 'package:medicalbooking_portal/features/profile/domain/repositories/clinical_profile_repository.dart';

class HttpClinicalProfileRepository implements ClinicalProfileRepository {
  const HttpClinicalProfileRepository(this._api);

  final ApiClient _api;

  /// `GET /me/perfil-clinico`: altitude and smoking are null until declared, which means "not complete".
  @override
  Future<ClinicalProfile?> read() async {
    final json = await _api.get('/me/perfil-clinico') as Map<String, dynamic>;
    final altitude = json['altitud_residencia_m'] as int?;
    final smoker = json['fumador'] as bool?;
    if (altitude == null || smoker == null) return null;
    return ClinicalProfile(altitudeM: altitude, smoker: smoker, cigarettesPerDay: json['cigarrillos_dia'] as int?);
  }

  /// `PUT /me/perfil-clinico`: the backend rejects unknown fields, wants `fumador` always, and refuses a
  /// cigarette count for someone who is not a smoker, so that field is null unless they smoke.
  @override
  Future<void> save(ClinicalProfile profile) async {
    await _api.put(
      '/me/perfil-clinico',
      body: {
        'altitud_residencia_m': profile.altitudeM,
        'fumador': profile.smoker,
        'cigarrillos_dia': profile.smoker ? profile.cigarettesPerDay : null,
      },
    );
  }
}
