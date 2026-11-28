import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';

/// A signed-in patient: the bearer token, when it stops being valid and who owns it.
class Session {
  const Session({required this.token, required this.expiresAt, required this.patient});

  final String token;
  final DateTime expiresAt;
  final Patient patient;

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);
}
