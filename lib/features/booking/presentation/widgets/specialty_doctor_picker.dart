import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/doctor.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/error_banner.dart';

/// Presentational: the medical specialties as chips. Reports the choice; the page loads the doctors.
class SpecialtyPicker extends StatelessWidget {
  const SpecialtyPicker({
    super.key,
    required this.specialties,
    required this.selected,
    required this.loading,
    required this.error,
    required this.onSelect,
    required this.onRetry,
  });

  final List<Specialty> specialties;
  final Specialty? selected;
  final bool loading;
  final ErrorView? error;
  final ValueChanged<Specialty> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error != null) return _Failure(error: error!, onRetry: onRetry);
    if (loading && specialties.isEmpty) return const _Loading();
    if (specialties.isEmpty) {
      return const Text('No hay especialidades disponibles por ahora.', style: TextStyle(color: Tokens.muted));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final specialty in specialties)
          ChoiceChip(
            label: Text(specialty.name),
            selected: selected?.id == specialty.id,
            showCheckmark: false,
            selectedColor: Tokens.orangeSoft,
            onSelected: (_) => onSelect(specialty),
          ),
      ],
    );
  }
}

/// Presentational: the doctors of the chosen specialty, as selectable cards: name, specialties and appointment length.
class DoctorPicker extends StatelessWidget {
  const DoctorPicker({
    super.key,
    required this.doctors,
    required this.selected,
    required this.loading,
    required this.error,
    required this.onSelect,
    required this.onRetry,
  });

  final List<Doctor> doctors;
  final Doctor? selected;
  final bool loading;
  final ErrorView? error;
  final ValueChanged<Doctor> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error != null) return _Failure(error: error!, onRetry: onRetry);
    if (loading && doctors.isEmpty) return const _Loading();
    if (doctors.isEmpty) {
      return const Text(
        'Esta especialidad no tiene médicos disponibles. Elige otra.',
        style: TextStyle(color: Tokens.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final doctor in doctors) ...[
          _DoctorCard(doctor: doctor, selected: selected?.id == doctor.id, onTap: () => onSelect(doctor)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor, required this.selected, required this.onTap});

  final Doctor doctor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Tokens.orangeTint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Tokens.orange : Tokens.slate200, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Tokens.slate900)),
                  const SizedBox(height: 2),
                  Text(doctor.specialtyLabel, style: const TextStyle(fontSize: 12, color: Tokens.muted)),
                ],
              ),
            ),
            Text('${doctor.durationMin} min', style: const TextStyle(fontSize: 12, color: Tokens.muted)),
          ],
        ),
      ),
    ),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Center(child: CircularProgressIndicator(color: Tokens.orange)),
  );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.error, required this.onRetry});

  final ErrorView error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ErrorBanner(error: error),
      TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh, size: 18), label: const Text('Reintentar')),
    ],
  );
}
