import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/domain/personal_data.dart';

/// Presentational: a date picked from the calendar, never typed. The value is written into [controller] as
/// year-month-day, so the text-based rules that already read it keep working. [firstDate] and [lastDate] bound
/// what can be picked; the parent sets them (for example, nothing after today).
class CalendarDateField extends StatelessWidget {
  const CalendarDateField({
    super.key,
    required this.controller,
    required this.label,
    required this.firstDate,
    required this.lastDate,
    this.errorText,
    this.onChanged,
    this.optional = false,
  });

  final TextEditingController controller;
  final String label;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? errorText;
  final VoidCallback? onChanged;

  /// An optional date can be cleared; a required one cannot.
  final bool optional;

  DateTime? get _current => parseIsoDate(controller.text.trim());

  Future<void> _pick(BuildContext context) async {
    final current = _current;
    final initial = current == null
        ? lastDate
        : current.isBefore(firstDate)
        ? firstDate
        : current.isAfter(lastDate)
        ? lastDate
        : current;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: label,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null) return;
    controller.text = isoDate(picked);
    onChanged?.call();
  }

  void _clear() {
    controller.clear();
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return InkWell(
      borderRadius: BorderRadius.circular(Tokens.radiusSm),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: optional && current != null
              ? IconButton(
                  tooltip: 'Quitar fecha',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _clear,
                )
              : const Icon(Icons.calendar_month_outlined, size: 20),
        ),
        child: Text(
          current == null ? 'Elígela en el calendario' : birthDateLabel(current),
          style: TextStyle(color: current == null ? Tokens.muted : Tokens.slate900),
        ),
      ),
    );
  }
}
