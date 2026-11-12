import 'package:flutter/foundation.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/presentation/controllers/session_controller.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/cancel_appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/get_my_appointments.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/usecases/get_my_lab_orders.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_start.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';
import 'package:medicalbooking_portal/features/payments/domain/usecases/get_saved_card.dart';
import 'package:medicalbooking_portal/features/payments/domain/usecases/remove_saved_card.dart';
import 'package:medicalbooking_portal/features/payments/domain/usecases/start_checkout.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';

/// State of the patient portal: own appointments and lab orders.
class PortalController extends ChangeNotifier {
  PortalController({
    required this._getMyAppointments,
    required this._getMyLabOrders,
    required this._cancelAppointment,
    required this._startCheckout,
    required this._getSavedCard,
    required this._removeSavedCard,
    required this._session,
  });

  static const _payOverrides = {
    ErrorKind.forbidden: 'No se pudo iniciar el pago de esta cita.',
    ErrorKind.conflict: 'No se pudo iniciar el pago: la cita ya no está pendiente, o ya tiene un pago en curso. Si recargaste la página, no podemos retomarlo desde aquí.',
    ErrorKind.unavailable: 'El pago en línea no está disponible por ahora. Inténtalo más tarde o contacta al laboratorio.',
  };

  static const _cancelOverrides = {
    ErrorKind.forbidden: 'No se pudo cancelar esta cita.',
    ErrorKind.conflict: 'Esta cita ya no se puede cancelar.',
  };

  final GetMyAppointments _getMyAppointments;
  final GetMyLabOrders _getMyLabOrders;
  final CancelAppointment _cancelAppointment;
  final StartCheckout _startCheckout;
  final GetSavedCard _getSavedCard;
  final RemoveSavedCard _removeSavedCard;
  final SessionController _session;

  List<Appointment> _appointments = const [];
  List<LabOrder> _orders = const [];
  SavedCard? _card;
  bool _loading = false;
  bool _working = false;
  ErrorView? _error;
  String? _notice;
  bool _disposed = false;

  List<Appointment> get appointments => _appointments;
  List<LabOrder> get orders => _orders;

  /// The patient's default card, or null when there is none.
  SavedCard? get card => _card;
  bool get loading => _loading;

  /// A cancellation, a payment or a card removal is in flight.
  bool get working => _working;
  ErrorView? get error => _error;
  String? get notice => _notice;

  Future<void> load() async {
    final patient = _session.patient;
    if (patient == null) return;
    _loading = true;
    _error = null;
    _notify();
    try {
      final results = await Future.wait([
        _getMyAppointments(patient.id),
        _getMyLabOrders(patient.id),
        _getSavedCard(patient.id),
      ]);
      _appointments = results[0] as List<Appointment>;
      _orders = results[1] as List<LabOrder>;
      _card = results[2] as SavedCard?;
    } catch (error) {
      _error = describeError(error);
    }
    _loading = false;
    _notify();
  }

  Future<void> cancel(Appointment appointment) async {
    final patient = _session.patient;
    if (patient == null) return;
    await _run(() async {
      await _cancelAppointment(patientId: patient.id, appointment: appointment);
      _notice = 'Cita ${appointment.id} cancelada. El horario quedó libre.';
    }, overrides: _cancelOverrides);
  }

  /// Opens a checkout. Returns where the patient pays, or null when the request failed (the error is shown).
  Future<CheckoutStart?> pay(Appointment appointment) async {
    final patient = _session.patient;
    if (patient == null) return null;
    CheckoutStart? start;
    await _run(() async {
      start = await _startCheckout(
        patientId: patient.id,
        appointment: appointment,
      );
    }, overrides: _payOverrides);
    return start;
  }

  /// The patient submitted the payment form. The reload brings back the card if it was saved.
  Future<void> paymentSent(Appointment appointment) => _run(() async {
    _processing.add(appointment.id);
    _notice = 'Pago enviado. Tu cita se confirmará en cuanto el banco avise.';
  });

  /// Appointments whose payment was sent and still waits for the bank's confirmation (kept while the page is open).
  final Set<String> _processing = {};

  bool isProcessing(Appointment appointment) =>
      _processing.contains(appointment.id);

  Future<void> removeCard() async {
    final patient = _session.patient;
    if (patient == null) return;
    await _run(() async {
      await _removeSavedCard(patient.id);
      _notice = 'Quitamos tu tarjeta guardada.';
    });
  }

  Future<void> _run(
    Future<void> Function() action, {
    Map<ErrorKind, String> overrides = const {},
  }) async {
    _working = true;
    _error = null;
    _notice = null;
    _notify();
    try {
      await action();
      await load();
    } catch (error) {
      _error = describeError(error, overrides: overrides);
    }
    _working = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
