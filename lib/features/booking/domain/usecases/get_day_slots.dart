import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/booking/domain/repositories/appointment_repository.dart';

class GetDaySlots {
  const GetDaySlots(this._repository);

  final AppointmentRepository _repository;

  Future<List<TimeSlot>> call(DateTime day) async {
    final slots = await _repository.slotsForDay(day);
    return [...slots]..sort((a, b) => a.startUtc.compareTo(b.startUtc));
  }
}
