/// horarios_disponibles.estado
enum SlotStatus { available, reserved, blocked }

/// horarios_disponibles (times are UTC, as stored)
class TimeSlot {
  const TimeSlot({
    required this.id,
    required this.startUtc,
    required this.endUtc,
    required this.status,
  });

  final String id;
  final DateTime startUtc;
  final DateTime endUtc;
  final SlotStatus status;

  bool get isAvailable => status == SlotStatus.available;
}
