import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

/// Presentational: the left panel of the booking modal. It is the reservation itself, live: what the patient picks
/// shows up here as they pick it, with the total and how long the slot is held.
class BookingAside extends StatelessWidget {
  const BookingAside({super.key, required this.service, required this.slot, required this.day, required this.holdMinutes});

  final MedicalService service;
  final TimeSlot? slot;
  final DateTime day;
  final int holdMinutes;

  @override
  Widget build(BuildContext context) {
    final start = slot == null ? null : branchTime(slot!.startUtc);
    return Container(
      decoration: const BoxDecoration(gradient: Tokens.brandGradient),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Tag('Reserva de cita'),
          const SizedBox(height: 22),
          const Text('Tu reserva', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.15)),
          const SizedBox(height: 8),
          const Text(
            'Se actualiza mientras eliges. Nada se cobra en este paso.',
            style: TextStyle(color: Colors.white, fontSize: 13.5, height: 1.45),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _Block(
                  child: _Field('Servicio', service.name, note: 'Duración: ${service.durationMin} min'),
                ),
                const _Line(),
                _Block(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _Field('Fecha', dayLabel(day))),
                      Expanded(child: _Field('Hora', start == null ? 'Sin elegir' : timeLabel(start))),
                    ],
                  ),
                ),
                const _Line(),
                _Block(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Expanded(child: Text('Total a pagar', style: TextStyle(color: Colors.white, fontSize: 13))),
                      Text(
                        money(service.basePrice, service.currency),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 1), child: Icon(Icons.schedule, color: Colors.white, size: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tu horario se retiene $holdMinutes minutos mientras confirmas. Puedes cancelar desde tu portal.',
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.45),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HORA DE LA SEDE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              Text('UTC-5', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.add_circle_outline, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Text(text.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
      ],
    ),
  );
}

class _Block extends StatelessWidget {
  const _Block({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: child);
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) => Container(height: 1, color: Colors.white.withValues(alpha: 0.22));
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      if (note != null) ...[
        const SizedBox(height: 2),
        Text(note!, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
      ],
    ],
  );
}
