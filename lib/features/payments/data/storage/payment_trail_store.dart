/// What the portal remembers about the payment of one appointment: the invoice made for it, the idempotency key
/// of its checkout and, once known, the payment. These are plain ids (no card data, no token); they only let a
/// reload pick up the payment where it was left.
typedef PaymentTrail = ({String invoiceId, String key, String? paymentId});

/// Port: where the trails are kept between page loads, by appointment id.
abstract interface class PaymentTrailStore {
  Map<String, PaymentTrail> load();

  void save(Map<String, PaymentTrail> trails);
}
