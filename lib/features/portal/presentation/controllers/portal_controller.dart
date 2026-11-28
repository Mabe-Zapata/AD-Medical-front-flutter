import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/presentation/controllers/session_controller.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/cancel_appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/get_my_appointments.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/usecases/get_my_lab_orders.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_start.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_status.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/refund.dart';
import 'package:medicalbooking_portal/features/payments/domain/usecases/get_refund_status.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/card_setup.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';
import 'package:medicalbooking_portal/features/payments/domain/usecases/start_card_setup.dart';
import 'package:medicalbooking_portal/features/payments/domain/policies/refund_failure.dart';
import 'package:medicalbooking_portal/features/payments/domain/usecases/get_checkout_status.dart';
import 'package:medicalbooking_portal/features/payments/domain/usecases/reconcile_checkout.dart';
import 'package:medicalbooking_portal/features/payments/domain/usecases/request_refund.dart';
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
    required this._getCheckoutStatus,
    required this._reconcileCheckout,
    required this._requestRefund,
    required this._getRefundStatus,
    required this._getSavedCard,
    required this._removeSavedCard,
    required this._startCardSetup,
    required this._session,
  });

  static const _payOverrides = {
    ErrorKind.forbidden: 'No se pudo iniciar el pago de esta cita.',
    ErrorKind.conflict: 'Ocurrió un error y el pago no se ha completado. Si ya pagaste, espera unos minutos o contacta al laboratorio.',
    ErrorKind.unavailable: 'El pago en línea no está disponible por ahora. Inténtalo más tarde o contacta al laboratorio.',
    ErrorKind.readOnly: 'No podemos registrar pagos por ahora. Inténtalo más tarde o contacta al laboratorio.',
  };

  static const _cancelOverrides = {
    ErrorKind.forbidden: 'No se pudo cancelar esta cita.',
    ErrorKind.conflict: 'Esta cita ya no se puede cancelar.',
  };

  final GetMyAppointments _getMyAppointments;
  final GetMyLabOrders _getMyLabOrders;
  final CancelAppointment _cancelAppointment;
  final StartCheckout _startCheckout;
  final GetCheckoutStatus _getCheckoutStatus;
  final ReconcileCheckout _reconcileCheckout;
  final RequestRefund _requestRefund;
  final GetRefundStatus _getRefundStatus;
  final GetSavedCard _getSavedCard;
  final RemoveSavedCard _removeSavedCard;
  final StartCardSetup _startCardSetup;
  final SessionController _session;

  List<Appointment> _appointments = const [];
  List<LabOrder> _orders = const [];
  SavedCard? _card;
  bool _loading = false;
  bool _working = false;
  ErrorView? _error;
  String? _notice;
  Timer? _noticeTimer;
  Timer? _errorTimer;

  /// How long an error banner stays before it leaves on its own.
  static const _errorLifetime = Duration(seconds: 8);

  /// Shows [error] and schedules it to leave; a new error replaces the old one and its timer.
  void _setError(ErrorView? error) {
    _errorTimer?.cancel();
    _error = error;
    if (error != null) _errorTimer = Timer(_errorLifetime, dismissError);
  }

  /// The patient closed the error banner, or its time ran out.
  void dismissError() {
    _errorTimer?.cancel();
    if (_disposed || _error == null) return;
    _error = null;
    _notify();
  }

  /// How long a notice stays before it leaves on its own.
  static const _noticeLifetime = Duration(seconds: 6);

  /// Shows [text] and schedules it to leave; a new notice replaces the old one and its timer.
  void _setNotice(String? text, {bool sticky = false}) {
    _noticeTimer?.cancel();
    _notice = text;
    if (text != null && !sticky) _noticeTimer = Timer(_noticeLifetime, dismissNotice);
  }

  /// The patient closed the notice, or its time ran out.
  void dismissNotice() {
    _noticeTimer?.cancel();
    if (_disposed || _notice == null) return;
    _notice = null;
    _notify();
  }

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
    _setError(null);
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
      _setError(describeError(error));
    }
    _loading = false;
    _notify();
  }

  Future<void> cancel(Appointment appointment, {String? reason}) async {
    final patient = _session.patient;
    if (patient == null) return;
    await _run(() async {
      await _cancelAppointment(patientId: patient.id, appointment: appointment, reason: reason);
    }, overrides: _cancelOverrides);
    if (_error == null) _announceCancellation(appointment.id);
  }

  /// Says what happened to the money, from the refreshed listing. The backend asks for the refund by itself when
  /// the payment qualifies; when it fails, the patient can ask again from the appointment.
  void _announceCancellation(String appointmentId) {
    final updated = _appointments.where((a) => a.id == appointmentId).firstOrNull;
    if (updated == null) return;
    switch (updated.refundState) {
      case 'PENDIENTE':
        _refundPending = updated;
        _setNotice('Cita cancelada. Pedimos tu reembolso; Stripe lo está procesando.', sticky: true);
      case 'PROCESADO':
        _setNotice('Cita cancelada. Tu reembolso ya se completó.');
      case 'FALLIDO':
        _setNotice('Cita cancelada. El reembolso automático no se pudo completar; puedes pedirlo de nuevo desde tu cita.', sticky: true);
      default:
        _setNotice(updated.paymentId != null
            ? 'Cita cancelada. No se pidió reembolso automático; si corresponde, puedes pedirlo desde tu cita.'
            : 'Cita cancelada. El horario quedó libre.');
    }
    _notify();
  }

  /// Opens a checkout, or picks up a payment that was already started. Returns where the patient pays, or null
  /// when there is nothing to open (the request failed, or the backend says the payment is already settled or
  /// still being processed; the notice or the error says which).
  Future<CheckoutStart?> pay(Appointment appointment) async {
    final patient = _session.patient;
    if (patient == null) return null;
    CheckoutStart? start;
    await _run(() async {
      try {
        start = await _startCheckout(patientId: patient.id, appointment: appointment);
      } on AppError catch (error) {
        if (error.kind != ErrorKind.conflict) rethrow;
        // The backend checked with Stripe: it is either paid (and now confirmed) or still on its way.
        if (error.message.contains('already paid') || error.message.contains('not pending payment')) {
          // The backend confirms the payment and the invoice, but it does not move the appointment itself to
          // "Confirmada" (a backend gap), so the card shows the payment as confirmed on its own.
          _processing.remove(appointment.id);
          _paid.add(appointment.id);
          _setNotice('Tu pago está confirmado. El laboratorio confirmará tu cita.');
        } else if (error.message.contains('still being processed')) {
          _processing.add(appointment.id);
          _setNotice(await _pendingNotice(patient.id, appointment));
        } else {
          rethrow;
        }
      }
    }, overrides: _payOverrides);
    return start;
  }

  /// Says where a payment that Stripe has not settled stands. The status is a nicety: if it cannot be read, the
  /// plain "we are confirming" text is enough.
  Future<String> _pendingNotice(String patientId, Appointment appointment) async {
    try {
      return _paymentNotice(await _getCheckoutStatus(patientId: patientId, appointment: appointment));
    } on AppError {
      return _confirmingNotice;
    }
  }

  /// Asks the backend to settle the payment of [appointment] against the provider, and says where it stands. The
  /// backend asks Stripe, so a payment already taken is confirmed even when its webhook has not arrived.
  Future<void> checkPayment(Appointment appointment) => _run(() async {
    final patient = _session.patient;
    if (patient == null) return;
    final status = await _reconcileCheckout(patientId: patient.id, appointment: appointment);
    if (status.state == CheckoutState.confirmed) _paid.add(appointment.id);
    _setNotice(_paymentNotice(status));
  });

  /// The patient submitted the payment form. The reload brings back the card if it was saved.
  Future<void> paymentSent(Appointment appointment) => _run(() async {
    _processing.add(appointment.id);
    _setNotice('Pago enviado. Tu cita se confirmará en cuanto el banco avise.');
  });

  /// Appointments whose payment was sent and still waits for the bank's confirmation (kept while the page is open).
  final Set<String> _processing = {};

  /// The payment was sent, or was started in this tab and the appointment still waits for it: no "pay" button, so
  /// it is never paid twice; the patient verifies it instead.
  bool isProcessing(Appointment appointment) =>
      !isPaid(appointment) &&
      (_processing.contains(appointment.id) ||
      (appointment.status == AppointmentStatus.pendingPayment && canCheckPayment(appointment)));

  /// Appointments whose payment the backend confirmed while the appointment itself still waits for payment.
  final Set<String> _paid = {};

  bool isPaid(Appointment appointment) =>
      appointment.status == AppointmentStatus.pendingPayment && _paid.contains(appointment.id);

  /// The payment of [appointment] was started in this tab, so it can be verified (and not paid twice).
  bool canCheckPayment(Appointment appointment) => _getCheckoutStatus.canCheck(appointment);

  /// The appointment is cancelled and its payment is known, so a refund can be requested.
  bool canRefund(Appointment appointment) => _requestRefund.canRequest(appointment);

  static const _confirmingNotice = 'Estamos confirmando tu pago. Tu cita pasará a "Confirmada" cuando el banco avise.';

  static String _paymentNotice(CheckoutStatus status) => switch (status.state) {
    CheckoutState.confirmed => 'Tu pago está confirmado.',
    CheckoutState.pending => status.retriesExhausted
        ? 'Tu pago sigue pendiente y no pudimos reintentarlo más. Contacta al laboratorio.'
        : _confirmingNotice,
    CheckoutState.rejected => 'Tu banco rechazó el pago. Puedes intentar pagar con otra tarjeta.',
    CheckoutState.cancelled => 'El pago fue cancelado.',
  };

  /// The refund waiting for Stripe's final answer, if any. Its notice stays until the patient checks it.
  Appointment? _refundPending;

  bool get refundPending => _refundPending != null;

  /// Asks the backend, which asks Stripe, whether the refund finished, and says so.
  Future<void> checkRefund() {
    final appointment = _refundPending;
    final patient = _session.patient;
    if (appointment == null || patient == null) return Future.value();
    return _run(() async {
      final state = await _getRefundStatus(patientId: patient.id, appointment: appointment);
      if (state == 'PROCESADO') {
        _refundPending = null;
        _setNotice('Tu reembolso se completó. Stripe confirmó la devolución.');
      } else if (state == 'FALLIDO') {
        _refundPending = null;
        _setNotice('El banco no pudo completar el reembolso. Contacta al laboratorio.');
      } else if (state == null) {
        _refundPending = null;
        _setNotice('No encontramos un reembolso para esta cita.');
      } else {
        _setNotice('Stripe todavía procesa tu reembolso. Verifícalo de nuevo en un momento.', sticky: true);
      }
    });
  }

  /// Asks for the refund. It is only "requested": the bank confirms it later.
  Future<void> refund(Appointment appointment, RefundReason reason, {String? text}) async {
    final patient = _session.patient;
    if (patient == null) return;
    await _run(() async {
      final refund = await _requestRefund(patientId: patient.id, appointment: appointment, reason: reason, text: text);
      if (refund.state == RefundState.failed) {
        _refundPending = null;
        _setNotice('El banco no pudo registrar el reembolso. Contacta al laboratorio.');
      } else {
        _refundPending = appointment;
        _setNotice('Pedimos tu reembolso. Stripe lo procesa; verifícalo para confirmar que se completó.', sticky: true);
      }
    }, describe: (error) => error is AppError ? ErrorView(refundFailureMessage(error)) : describeError(error));
  }

  /// Asks the backend for a card form to save a card without paying. Throws `AppError` when it cannot.
  Future<CardSetup> startCardSetup() {
    final patient = _session.patient;
    if (patient == null) throw const AppError(ErrorKind.unauthenticated, 'no signed-in patient');
    return _startCardSetup(patient.id);
  }

  /// The card was stored by Stripe: reload the cards so the new one shows up.
  Future<void> cardSaved() => _run(() async {
    _setNotice('Tarjeta guardada. La puedes usar al pagar tus citas.');
  });

  Future<void> removeCard() async {
    final patient = _session.patient;
    if (patient == null) return;
    await _run(() async {
      await _removeSavedCard(patient.id);
      _setNotice('Quitamos tu tarjeta guardada.');
    });
  }

  Future<void> _run(
    Future<void> Function() action, {
    Map<ErrorKind, String> overrides = const {},
    ErrorView Function(Object)? describe,
  }) async {
    _working = true;
    _setError(null);
    _setNotice(null);
    _notify();
    try {
      await action();
      await load();
    } catch (error) {
      _setError(describe?.call(error) ?? describeError(error, overrides: overrides));
    }
    _working = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _errorTimer?.cancel();
    _disposed = true;
    super.dispose();
  }
}
