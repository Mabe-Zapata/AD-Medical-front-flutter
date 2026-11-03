import 'package:flutter/foundation.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/auth/presentation/controllers/session_controller.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/reservation_result.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/get_day_slots.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/reserve_appointment.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';

/// State of the booking screen: chosen service, day and slot.
class BookingController extends ChangeNotifier {
  BookingController({
    required this._getDaySlots,
    required this._reserveAppointment,
    required this._session,
    required this.services,
    String? initialServiceId,
  }) : _service = services.firstWhere((s) => s.id == initialServiceId, orElse: () => services.first),
       _day = branchToday();

  static const daysAhead = 10;

  /// What the patient reads when the service id is not one the backend knows.
  static const _reserveOverrides = {
    ErrorKind.validation: 'No se pudo reservar: este servicio no está disponible en este entorno.',
    ErrorKind.forbidden: 'Tu cuenta no puede reservar citas.',
  };

  final GetDaySlots _getDaySlots;
  final ReserveAppointment _reserveAppointment;
  final SessionController _session;
  final List<MedicalService> services;

  MedicalService _service;
  DateTime _day;
  List<TimeSlot> _slots = const [];
  TimeSlot? _selectedSlot;
  TimeSlot? _conflictedSlot;
  ErrorView? _slotsError;
  ErrorView? _reserveError;
  bool _loadingSlots = false;
  bool _submitting = false;
  bool _disposed = false;

  MedicalService get service => _service;
  DateTime get day => _day;
  List<DateTime> get days => [for (var i = 0; i < daysAhead; i++) branchToday().add(Duration(days: i))];
  List<TimeSlot> get slots => _slots;
  TimeSlot? get selectedSlot => _selectedSlot;

  /// Set when the last confirmation lost the slot to someone else.
  TimeSlot? get conflictedSlot => _conflictedSlot;

  /// Set when the availability could not be loaded.
  ErrorView? get slotsError => _slotsError;

  /// Set when the last confirmation failed for a reason other than a lost slot.
  ErrorView? get reserveError => _reserveError;
  bool get loadingSlots => _loadingSlots;
  bool get submitting => _submitting;
  bool get canConfirm => _selectedSlot != null && !_submitting;

  Future<void> loadSlots() async {
    _loadingSlots = true;
    _slotsError = null;
    _notify();
    try {
      _slots = await _getDaySlots(_day);
    } catch (error) {
      _slots = const [];
      _slotsError = describeError(error);
    }
    _loadingSlots = false;
    _notify();
  }

  void selectService(MedicalService service) {
    _service = service;
    _reserveError = null;
    _notify();
  }

  Future<void> selectDay(DateTime day) {
    _day = day;
    _selectedSlot = null;
    _conflictedSlot = null;
    _reserveError = null;
    return loadSlots();
  }

  void selectSlot(TimeSlot slot) {
    _selectedSlot = slot;
    _conflictedSlot = null;
    _reserveError = null;
    _notify();
  }

  /// Returns the new appointment, or null when the slot was lost or the request failed.
  Future<Appointment?> confirm({String? reason}) async {
    final slot = _selectedSlot;
    final patient = _session.patient;
    if (slot == null || patient == null) return null;

    _submitting = true;
    _conflictedSlot = null;
    _reserveError = null;
    _notify();
    try {
      final result = await _reserveAppointment(patient: patient, service: _service, slot: slot, reason: reason);
      _submitting = false;
      if (result is Reserved) {
        _notify();
        return result.appointment;
      }
      _conflictedSlot = slot;
      _selectedSlot = null;
      await loadSlots();
    } catch (error) {
      _submitting = false;
      _reserveError = describeError(error, overrides: _reserveOverrides);
      _notify();
    }
    return null;
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
