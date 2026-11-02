import 'package:flutter/foundation.dart';
import 'package:medicalbooking_portal/features/auth/presentation/controllers/session_controller.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/get_my_appointments.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/usecases/get_my_lab_orders.dart';

/// State of the patient portal: own appointments and lab orders.
class PortalController extends ChangeNotifier {
  PortalController({
    required this._getMyAppointments,
    required this._getMyLabOrders,
    required this._session,
  });

  final GetMyAppointments _getMyAppointments;
  final GetMyLabOrders _getMyLabOrders;
  final SessionController _session;

  List<Appointment> _appointments = const [];
  List<LabOrder> _orders = const [];
  bool _loading = false;
  bool _disposed = false;

  List<Appointment> get appointments => _appointments;
  List<LabOrder> get orders => _orders;
  bool get loading => _loading;

  Future<void> load() async {
    final patient = _session.patient;
    if (patient == null) return;
    _loading = true;
    _notify();
    final results = await Future.wait([_getMyAppointments(patient.id), _getMyLabOrders(patient.id)]);
    _appointments = results[0] as List<Appointment>;
    _orders = results[1] as List<LabOrder>;
    _loading = false;
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
