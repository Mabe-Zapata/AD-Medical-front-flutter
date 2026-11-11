import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/payment_repository.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

/// Demo: there is no payment page, so paying confirms the appointment right away.
class DemoPaymentRepository implements PaymentRepository {
  const DemoPaymentRepository(this._db);

  final DemoDatabase _db;

  @override
  Future<Uri?> startCheckout({required String patientId, required String appointmentId}) async {
    await _db.simulateLatency();
    final index = _db.appointments.indexWhere((a) => a.id == appointmentId && a.patientId == patientId);
    if (index < 0) throw const AppError(ErrorKind.forbidden, 'not found or not yours');
    final current = _db.appointments[index];
    if (current.status != AppointmentStatus.pendingPayment) {
      throw const AppError(ErrorKind.conflict, 'not payable');
    }
    _db.appointments[index] = current.copyWith(status: AppointmentStatus.confirmed);
    return null;
  }
}
