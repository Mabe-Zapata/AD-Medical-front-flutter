import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/info_banner.dart';

/// A strip of days with arrows, then the free half-hour slots of the chosen day grouped into morning and afternoon.
/// Only free slots are shown: crossed-out hours add noise and nothing to choose.
class SlotPicker extends StatelessWidget {
  const SlotPicker({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.slots,
    required this.selectedSlot,
    required this.loading,
    required this.error,
    required this.footnote,
    required this.onDay,
    required this.onSlot,
  });

  final List<DateTime> days;
  final DateTime selectedDay;
  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final bool loading;
  final ErrorView? error;
  final String footnote;
  final ValueChanged<DateTime> onDay;
  final ValueChanged<TimeSlot> onSlot;

  @override
  Widget build(BuildContext context) {
    final free = [for (final slot in slots) if (slot.isAvailable) slot];
    final morning = [for (final slot in free) if (branchTime(slot.startUtc).hour < 12) slot];
    final afternoon = [for (final slot in free) if (branchTime(slot.startUtc).hour >= 12) slot];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('2 · Fecha', trailing: _monthLabel(selectedDay)),
        const SizedBox(height: 8),
        _DayStrip(days: days, selected: selectedDay, onDay: onDay),
        const SizedBox(height: 18),
        _Label('3 · Hora', trailing: loading || error != null ? null : '${free.length} horarios libres'),
        const SizedBox(height: 8),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: Tokens.orange)),
          )
        else if (error != null)
          InfoBanner(message: error!.message, color: Tokens.danger, icon: Icons.error_outline)
        else if (free.isEmpty)
          const Text('No hay horarios libres este día. Prueba con otra fecha.', style: TextStyle(color: Tokens.muted))
        else ...[
          if (morning.isNotEmpty) _Group('Mañana', morning, selectedSlot, onSlot),
          if (morning.isNotEmpty && afternoon.isNotEmpty) const SizedBox(height: 10),
          if (afternoon.isNotEmpty) _Group('Tarde', afternoon, selectedSlot, onSlot),
        ],
        const SizedBox(height: 10),
        Text(footnote, style: const TextStyle(fontSize: 12, color: Tokens.muted, height: 1.5)),
      ],
    );
  }

  static String _monthLabel(DateTime day) => '${monthLabel(day)} ${day.year}';
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(text.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Tokens.blueText)),
      if (trailing != null) Text(trailing!, style: const TextStyle(fontSize: 12, color: Tokens.muted)),
    ],
  );
}

class _DayStrip extends StatefulWidget {
  const _DayStrip({required this.days, required this.selected, required this.onDay});

  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onDay;

  @override
  State<_DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<_DayStrip> {
  int _start = 0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 8.0;
      const arrow = 36.0;
      const minDay = 52.0;
      final room = constraints.maxWidth - 2 * (arrow + gap);
      final visible = (room / (minDay + gap)).floor().clamp(3, 7);
      final total = widget.days.length;
      final start = _start.clamp(0, (total - visible).clamp(0, total));
      final shown = widget.days.skip(start).take(visible).toList();
      return Row(
        children: [
          _Arrow(Icons.chevron_left, 'Días anteriores', start > 0 ? () => setState(() => _start = (start - visible).clamp(0, total)) : null),
          const SizedBox(width: gap),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  Expanded(child: _Day(shown[i], shown[i] == widget.selected, () => widget.onDay(shown[i]))),
                ],
              ],
            ),
          ),
          const SizedBox(width: gap),
          _Arrow(
            Icons.chevron_right,
            'Días siguientes',
            start + visible < total ? () => setState(() => _start = (start + visible).clamp(0, total - visible)) : null,
          ),
        ],
      );
    },
  );
}

class _Arrow extends StatelessWidget {
  const _Arrow(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 36,
    height: 60,
    child: IconButton.outlined(
      onPressed: onTap,
      tooltip: label,
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        side: const BorderSide(color: Tokens.slate200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 20, color: onTap == null ? Tokens.slate200 : Tokens.slate600),
    ),
  );
}

class _Day extends StatelessWidget {
  const _Day(this.day, this.selected, this.onTap);

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    showCheckmark: false,
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: Tokens.orange,
    backgroundColor: Colors.white,
    padding: EdgeInsets.zero,
    labelPadding: EdgeInsets.zero,
    side: BorderSide(color: selected ? Tokens.orange : Tokens.slate200),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    label: SizedBox(
      height: 58,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekdayLabel(day).toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? Colors.white : Tokens.muted),
          ),
          Text(
            '${day.day}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.15, color: selected ? Colors.white : Tokens.slate900),
          ),
        ],
      ),
    ),
  );
}

class _Group extends StatelessWidget {
  const _Group(this.title, this.slots, this.selected, this.onSlot);

  final String title;
  final List<TimeSlot> slots;
  final TimeSlot? selected;
  final ValueChanged<TimeSlot> onSlot;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Tokens.slate600)),
      const SizedBox(height: 6),
      LayoutBuilder(
        builder: (context, constraints) {
          const gap = 8.0;
          final columns = constraints.maxWidth >= 420 ? 6 : 4;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [for (final slot in slots) SizedBox(width: width, child: _SlotButton(slot, selected?.id == slot.id, onSlot))],
          );
        },
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
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: OutlinedButton(
      onPressed: () => onSlot(slot),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? Tokens.orange : Colors.white,
        foregroundColor: selected ? Colors.white : Tokens.slate900,
        side: BorderSide(color: selected ? Tokens.orange : Tokens.slate200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.zero,
      ),
      child: Text(timeLabel(branchTime(slot.startUtc)), style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
    ),
  );
}
