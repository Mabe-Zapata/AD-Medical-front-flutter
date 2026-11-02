import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';

/// Day chips plus the grid of half-hour slots for the chosen day.
class SlotPicker extends StatelessWidget {
  const SlotPicker({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.slots,
    required this.selectedSlot,
    required this.loading,
    required this.onDay,
    required this.onSlot,
  });

  final List<DateTime> days;
  final DateTime selectedDay;
  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final bool loading;
  final ValueChanged<DateTime> onDay;
  final ValueChanged<TimeSlot> onSlot;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final day in days)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(dayLabel(day)),
                  selected: day == selectedDay,
                  showCheckmark: false,
                  selectedColor: Tokens.orange,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: day == selectedDay ? Colors.white : Tokens.slate700,
                  ),
                  onSelected: (_) => onDay(day),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (loading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator(color: Tokens.orange)),
        )
      else
        Wrap(spacing: 10, runSpacing: 10, children: [for (final slot in slots) _SlotButton(slot, selectedSlot?.id == slot.id, onSlot)]),
      const SizedBox(height: 14),
      const Text(
        'Las horas tachadas no están disponibles. Demo: las 10:30 parecen libres, pero otro paciente '
        'siempre las toma al confirmar, para mostrar que la disponibilidad se valida de nuevo.',
        style: TextStyle(fontSize: 12, color: Tokens.muted, height: 1.5),
      ),
    ],
  );
}

class _SlotButton extends StatelessWidget {
  const _SlotButton(this.slot, this.selected, this.onSlot);

  final TimeSlot slot;
  final bool selected;
  final ValueChanged<TimeSlot> onSlot;

  @override
  Widget build(BuildContext context) {
    final unavailable = !slot.isAvailable;
    return SizedBox(
      width: 92,
      child: OutlinedButton(
        onPressed: unavailable ? null : () => onSlot(slot),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? Tokens.orange : Colors.white,
          foregroundColor: selected ? Colors.white : Tokens.slate900,
          side: BorderSide(color: selected ? Tokens.orange : Tokens.slate200),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusSm)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          timeLabel(branchTime(slot.startUtc)),
          style: TextStyle(fontWeight: FontWeight.w700, decoration: unavailable ? TextDecoration.lineThrough : null),
        ),
      ),
    );
  }
}
