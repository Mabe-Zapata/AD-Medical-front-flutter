import 'dart:math';

final _random = Random.secure();

/// A fresh `Idempotency-Key` (the backend accepts 8 to 100 characters). One per reservation attempt:
/// a retry of the same attempt must reuse it, a new attempt must not.
String newIdempotencyKey() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  return 'web-${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
}
