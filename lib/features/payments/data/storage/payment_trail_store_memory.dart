import 'package:medicalbooking_portal/features/payments/data/storage/payment_trail_store.dart';

/// Keeps the trails for this app run only (tests, the demo, any target that is not the browser).
class MemoryPaymentTrailStore implements PaymentTrailStore {
  Map<String, PaymentTrail> _trails = {};

  @override
  Map<String, PaymentTrail> load() => Map.of(_trails);

  @override
  void save(Map<String, PaymentTrail> trails) => _trails = Map.of(trails);
}

PaymentTrailStore createPaymentTrailStore() => MemoryPaymentTrailStore();
