import 'dart:convert';

import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

/// Parses the `SERVICES_JSON` build setting. Returns null when it is empty, so the caller can fall
/// back. Throws a [FormatException] for malformed input: a bad build setting must fail loudly.
List<MedicalService>? parseServices(String json) {
  if (json.trim().isEmpty) return null;
  final decoded = jsonDecode(json);
  if (decoded is! List) throw const FormatException('SERVICES_JSON must be a JSON array');
  return [
    for (final item in decoded)
      MedicalService(
        id: _field<String>(item, 'id'),
        name: _field<String>(item, 'name'),
        durationMin: _field<num>(item, 'durationMin').toInt(),
        basePrice: _field<num>(item, 'basePrice').toDouble(),
        currency: item is Map && item['currency'] is String ? item['currency'] as String : 'USD',
      ),
  ];
}

T _field<T>(Object? item, String key) {
  final value = item is Map ? item[key] : null;
  if (value is! T) throw FormatException('SERVICES_JSON: "$key" is missing or has the wrong type');
  return value;
}
