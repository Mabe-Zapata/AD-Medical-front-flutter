import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_start.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/payment_source.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/payment_repository.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

/// Demo: opens a made-up in-portal card form and plays the backend's part when it is submitted: it declines
/// the way Stripe's test cards do, saves the card when asked, and confirms the appointment like the webhook.
class DemoPaymentRepository implements PaymentRepository {
  const DemoPaymentRepository(this._db);

  final DemoDatabase _db;

  @override
  Future<CheckoutStart> startCheckout({required String patientId, required String appointmentId}) async {
    await _db.simulateLatency();
    _find(patientId, appointmentId);
    return const Embedded(clientSecret: 'cs_test_mock_secret', publishableKey: 'pk_test_mock');
  }

  /// Pays with the chosen [source]. Throws an [AppError] shaped like the backend's 400s.
  Future<void> payWithCard({
    required String patientId,
    required String appointmentId,
    required PaymentSource source,
  }) async {
    await _db.simulateLatency();
    final index = _find(patientId, appointmentId);
    switch (source) {
      case SavedCardSource():
        if (_db.savedCardOf(patientId) == null) {
          throw const AppError(ErrorKind.validation, 'No tienes una tarjeta guardada', status: 400);
        }
      case NewCardSource(:final paymentMethodId, :final save):
        _declineLikeStripe(paymentMethodId);
        if (save) {
          _db.setSavedCard(
            patientId,
            SavedCard(id: 'pm_demo_new', brand: 'VISA', last4: '4242', expMonth: 12, expYear: DateTime.now().year + 2),
          );
        }
    }
    // What the signed webhook does in the real system.
    _db.appointments[index] = _db.appointments[index].copyWith(status: AppointmentStatus.confirmed);
  }

  /// Stripe's test payment methods and how they fail.
  void _declineLikeStripe(String paymentMethodId) {
    final reason = switch (paymentMethodId) {
      final id when id.contains('InsufficientFunds') => 'Payment declined: Your card has insufficient funds.',
      final id when id.contains('ExpiredCard') => 'Payment declined: Your card has expired.',
      final id when id.contains('threeDSecure') => 'Payment declined: Your card requires 3D Secure authentication.',
      final id when id.contains('chargeDeclined') => 'Payment declined: Your card was declined.',
      _ => null,
    };
    if (reason != null) throw AppError(ErrorKind.validation, reason, status: 400);
  }

  int _find(String patientId, String appointmentId) {
    final index = _db.appointments.indexWhere((a) => a.id == appointmentId && a.patientId == patientId);
    // Like the real API: a missing appointment and someone else's look the same.
    if (index < 0) throw const AppError(ErrorKind.forbidden, 'not found or not yours');
    if (_db.appointments[index].status != AppointmentStatus.pendingPayment) {
      throw const AppError(ErrorKind.conflict, 'not payable', status: 409);
    }
    return index;
  }
}
