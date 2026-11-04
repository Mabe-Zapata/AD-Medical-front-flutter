import 'package:flutter/foundation.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/presentation/controllers/session_controller.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/cancel_appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/get_my_appointments.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/usecases/get_my_lab_orders.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/usecases/lookup_lab_order.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';

/// State of the patient portal: own appointments and lab orders.
class PortalController extends ChangeNotifier {
  PortalController({
    required this._getMyAppointments,
    required this._getMyLabOrders,
    required this._cancelAppointment,
    required this._lookupLabOrder,
    required this._session,
  });

  /// The same wording for "not yours" and "does not exist", as the API does.
  static const _lookupOverrides = {
    ErrorKind.forbidden: 'No encontramos una orden con ese código en tu cuenta.',
    ErrorKind.notFound: 'No encontramos una orden con ese código en tu cuenta.',
    ErrorKind.validation: 'El código de orden no es válido. Revísalo e inténtalo de nuevo.',
  };

  static const _cancelOverrides = {
    ErrorKind.forbidden: 'No se pudo cancelar esta cita.',
    ErrorKind.conflict: 'Esta cita ya no se puede cancelar.',
  };

  final GetMyAppointments _getMyAppointments;
  final GetMyLabOrders _getMyLabOrders;
  final CancelAppointment _cancelAppointment;
  final LookupLabOrder _lookupLabOrder;
  final SessionController _session;

  List<Appointment> _appointments = const [];
  List<LabOrder> _orders = const [];
  bool _loading = false;
  bool _working = false;
  ErrorView? _error;
  String? _notice;
  bool _disposed = false;

  List<Appointment> get appointments => _appointments;
  List<LabOrder> get orders => _orders;
  bool get loading => _loading;

  /// A cancellation or a lookup is in flight.
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
      final results = await Future.wait([_getMyAppointments(patient.id), _getMyLabOrders(patient.id)]);
      _appointments = results[0] as List<Appointment>;
      _orders = results[1] as List<LabOrder>;
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

  Future<void> lookupOrder(String code) async {
    final patient = _session.patient;
    if (patient == null) return;
    await _run(() async {
      final order = await _lookupLabOrder(patientId: patient.id, code: code);
      _notice = 'Orden ${order.id} encontrada.';
    }, overrides: _lookupOverrides);
  }

  Future<void> _run(Future<void> Function() action, {Map<ErrorKind, String> overrides = const {}}) async {
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
