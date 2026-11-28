import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/domain/personal_data.dart';

/// Presentational: sex registered at birth, as two chips. Reports the choice; the parent owns it.
class SexChoice extends StatelessWidget {
  const SexChoice({super.key, required this.value, required this.onChanged, this.errorText});

  final BiologicalSex? value;
  final ValueChanged<BiologicalSex> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Sexo', style: TextStyle(fontWeight: FontWeight.w700, color: Tokens.slate900)),
      const SizedBox(height: 2),
      const Text(
        'Los rangos de referencia de tus análisis dependen de él.',
        style: TextStyle(fontSize: 12, color: Tokens.muted, height: 1.4),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        children: [
          for (final sex in BiologicalSex.values)
            ChoiceChip(
              label: Text(sex.label),
              selected: value == sex,
              showCheckmark: false,
              selectedColor: Tokens.orangeSoft,
              onSelected: (_) => onChanged(sex),
            ),
        ],
      ),
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(errorText!, style: const TextStyle(color: Tokens.danger, fontSize: 12)),
        ),
    ],
  );
}

/// Presentational: a birth date picked from the calendar (no typing, so no wrong format). The platform picker is
/// already in Spanish because the app sets the locale.
class BirthDateField extends StatelessWidget {
  const BirthDateField({super.key, required this.value, required this.onChanged, this.errorText, this.today});

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;

  /// Today; a test can fix it.
  final DateTime? today;

  Future<void> _pick(BuildContext context) async {
    final now = today ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(now.year - 30, 1, 1),
      firstDate: DateTime(now.year - maxAgeYears, now.month, now.day),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Fecha de nacimiento',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('birth-date'),
    borderRadius: BorderRadius.circular(Tokens.radiusSm),
    onTap: () => _pick(context),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'Fecha de nacimiento',
        prefixIcon: const Icon(Icons.cake_outlined, size: 20),
        suffixIcon: const Icon(Icons.calendar_month_outlined, size: 20),
        errorText: errorText,
      ),
      child: Text(
        value == null ? 'Elígela en el calendario' : birthDateLabel(value!),
        style: TextStyle(color: value == null ? Tokens.muted : Tokens.slate900),
      ),
    ),
  );
}
