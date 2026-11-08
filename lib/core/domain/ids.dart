final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);

/// The backend identifies everything with UUIDs; anything else cannot be a real id.
bool isUuid(String value) => _uuid.hasMatch(value.trim());
