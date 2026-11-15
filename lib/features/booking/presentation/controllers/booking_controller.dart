import 'package:flutter/foundation.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/auth/presentation/controllers/session_controller.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/doctor.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/reservation_result.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/get_day_slots.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/list_doctors.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/reserve_appointment.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/usecases/get_my_lab_orders.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';

/// State of the booking screen. A consultation takes a specialty, then a doctor; a result review takes the doctor of
/// the patient's medical order; a lab sample takes no doctor. The day and the time come last: the free times are the
/// doctor's own, so they never mix two doctors.
class BookingController extends ChangeNotifier {
  BookingController({
    required this._getDaySlots,
    required this._reserveAppointment,
    required this._listSpecialties,
    required this._listDoctors,
    required this._getMyLabOrders,
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
  final ListSpecialties _listSpecialties;
  final ListDoctors _listDoctors;
  final GetMyLabOrders _getMyLabOrders;
  final SessionController _session;
  final List<MedicalService> services;

  MedicalService _service;
  DateTime _day;
  List<Specialty> _specialties = const [];
  Specialty? _specialty;
  List<Doctor> _doctors = const [];
  Doctor? _doctor;
  List<TimeSlot> _slots = const [];
  TimeSlot? _selectedSlot;
  TimeSlot? _conflictedSlot;
  LabOrder? _order;
  bool _orderMissing = false;
  bool _loadingOrder = false;
  ErrorView? _orderError;
  ErrorView? _specialtiesError;
  ErrorView? _doctorsError;
  ErrorView? _slotsError;
  ErrorView? _reserveError;
  bool _loadingSpecialties = false;
  bool _loadingDoctors = false;
  bool _loadingSlots = false;
  bool _submitting = false;
  bool _disposed = false;

  MedicalService get service => _service;
  DateTime get day => _day;
  List<DateTime> get days => [for (var i = 0; i < daysAhead; i++) branchToday().add(Duration(days: i))];
  List<Specialty> get specialties => _specialties;
  Specialty? get specialty => _specialty;
  List<Doctor> get doctors => _doctors;
  Doctor? get doctor => _doctor;
  List<TimeSlot> get slots => _slots;
  TimeSlot? get selectedSlot => _selectedSlot;

  /// Set when the last confirmation lost the slot to someone else.
  TimeSlot? get conflictedSlot => _conflictedSlot;

  /// Set when the specialties, the doctors or the availability could not be loaded.
  ErrorView? get specialtiesError => _specialtiesError;
  ErrorView? get doctorsError => _doctorsError;
  ErrorView? get slotsError => _slotsError;

  /// Set when the last confirmation failed for a reason other than a lost slot.
  ErrorView? get reserveError => _reserveError;
  bool get loadingSpecialties => _loadingSpecialties;
  bool get loadingDoctors => _loadingDoctors;
  bool get loadingSlots => _loadingSlots;
  bool get submitting => _submitting;
  bool get canConfirm => _selectedSlot != null && (!doctorFirst || _doctor != null) && !_submitting;

  /// A consultation or a result review needs its doctor before the times; a lab sample does not.
  bool get doctorFirst => _service.needsDoctor || _service.requiresOrder;

  /// The medical order a result review is booked for, with its doctor already chosen.
  LabOrder? get medicalOrder => _order;
  bool get loadingOrder => _loadingOrder;
  bool get orderMissing => _orderMissing;
  ErrorView? get orderError => _orderError;

  /// The specialties the patient sees. A consultation has one fixed specialty (its service's own), so only that
  /// one is offered and it cannot be changed.
  List<Specialty> get specialtyChoices => _service.needsDoctor
      ? [for (final specialty in _specialties) if (specialty.id == _service.specialtyId) specialty]
      : _specialties;

  Future<void> loadSpecialties() async {
    _loadingSpecialties = true;
    _specialtiesError = null;
    _notify();
    try {
      _specialties = await _listSpecialties();
    } catch (error) {
      _specialties = const [];
      _specialtiesError = describeError(error);
    }
    _loadingSpecialties = false;
    _notify();
    if (_service.needsDoctor && _specialty == null) await _chooseServiceSpecialty();
  }

  /// Selects the consultation's own specialty, so its doctors load without asking the patient.
  Future<void> _chooseServiceSpecialty() async {
    final match = [for (final specialty in _specialties) if (specialty.id == _service.specialtyId) specialty];
    if (match.isEmpty) return;
    await selectSpecialty(match.first);
  }

  Future<void> selectSpecialty(Specialty specialty) async {
    _specialty = specialty;
    _doctor = null;
    _doctors = const [];
    _slots = const [];
    _selectedSlot = null;
    _conflictedSlot = null;
    _doctorsError = null;
    _slotsError = null;
    _loadingDoctors = true;
    _notify();
    try {
      _doctors = await _listDoctors(specialty);
    } catch (error) {
      _doctorsError = describeError(error);
    }
    _loadingDoctors = false;
    _notify();
  }

  /// Picks the doctor: the times of the day are then that doctor's own.
  Future<void> selectDoctor(Doctor doctor) {
    _doctor = doctor;
    _selectedSlot = null;
    _conflictedSlot = null;
    _reserveError = null;
    return loadSlots();
  }

  /// Loads the medical order of a result review and its doctor. A review without an order cannot be booked.
  Future<void> loadOrder() async {
    final patient = _session.patient;
    _loadingOrder = true;
    _orderMissing = false;
    _orderError = null;
    _order = null;
    _doctor = null;
    _slots = const [];
    _notify();
    try {
      final orders = patient == null ? const <LabOrder>[] : await _getMyLabOrders(patient.id);
      // The orders come newest first: the latest one that names its doctor is the review's order.
      LabOrder? latest;
      for (final order in orders) {
        if (order.doctorId != null) {
          latest = order;
          break;
        }
      }
      if (latest == null) {
        _orderMissing = true;
      } else {
        final doctors = await _listDoctors();
        Doctor? doctor;
        for (final candidate in doctors) {
          if (candidate.id == latest.doctorId) doctor = candidate;
        }
        _order = latest;
        _doctor = doctor;
        _orderMissing = doctor == null;
      }
    } catch (error) {
      _orderError = describeError(error);
    }
    _loadingOrder = false;
    _notify();
    if (_doctor != null) await loadSlots();
  }

  Future<void> loadSlots() async {
    // A consultation or a review needs its doctor first: the free times are that doctor's own.
    if (doctorFirst && _doctor == null) {
      _slots = const [];
      _notify();
      return;
    }
    _loadingSlots = true;
    _slotsError = null;
    _notify();
    try {
      _slots = await _getDaySlots(_day, doctorId: doctorFirst ? _doctor?.id : null);
    } catch (error) {
      _slots = const [];
      _slotsError = describeError(error);
    }
    _loadingSlots = false;
    _notify();
  }

  /// Lab samples skip the specialty and the doctor: their times are shown straight away. A result review takes
  /// the doctor of the patient's order.
  Future<void> selectService(MedicalService service) {
    _service = service;
    _reserveError = null;
    _selectedSlot = null;
    _conflictedSlot = null;
    _doctor = null;
    _order = null;
    _orderMissing = false;
    _orderError = null;
    if (!service.needsDoctor) {
      _specialty = null;
      _doctors = const [];
    }
    if (service.needsDoctor) {
      _specialty = null;
      _doctors = const [];
      return _chooseServiceSpecialty();
    }
    if (service.requiresOrder) return loadOrder();
    return loadSlots();
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
