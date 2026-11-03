/// The signed-in person. The API's `/me` only returns the user id, roles and permissions, so the
/// personal fields are optional: the demo fills them, the real API does not.
class Patient {
  const Patient({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.documentType,
    this.documentNumber,
    this.birthDate,
    this.roles = const [],
    this.permissions = const [],
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? documentType;
  final String? documentNumber;
  final DateTime? birthDate;
  final List<String> roles;
  final List<String> permissions;

  String? get fullName {
    final parts = [firstName, lastName].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  String get displayName => fullName ?? email;

  /// UI hint only: the backend authorizes every request on its own.
  bool can(String permission) => permissions.contains(permission);
}
