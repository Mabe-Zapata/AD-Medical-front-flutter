import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/domain/personal_data.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/entities/patient_history.dart';
import 'package:medicalbooking_portal/features/clinical_history/presentation/labels.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/status_chip.dart';

/// Presentational: one line of the history, with its state and whether a doctor has confirmed it.
class HistoryEntryTile extends StatelessWidget {
  const HistoryEntryTile({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final state = stateLabel(entry.state);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Tokens.slate200),
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.title,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Tokens.slate900),
          ),
          if (entry.detail.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(entry.detail, style: const TextStyle(color: Tokens.slate600, fontSize: 13)),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (state.isNotEmpty) StatusChip(state, Tokens.blueText),
              entry.verified
                  ? const StatusChip('Confirmada por tu médico', Tokens.success)
                  : const StatusChip('Pendiente de confirmar', Tokens.warning),
              if (entry.declared) const StatusChip('Declarada por ti', Tokens.blueText),
            ],
          ),
        ],
      ),
    );
  }
}

/// The entries of one kind, or a line saying what to do when there are none.
class HistoryEntryList extends StatelessWidget {
  const HistoryEntryList({super.key, required this.entries, required this.emptyText});

  final List<HistoryEntry> entries;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(emptyText, style: const TextStyle(color: Tokens.muted));
    }
    return Column(
      children: [
        for (final entry in entries) ...[
          HistoryEntryTile(entry: entry),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Vital signs taken at appointments. A correction is marked as one.
class VitalsList extends StatelessWidget {
  const VitalsList({super.key, required this.records});

  final List<VitalRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Text('Aún no hay signos vitales en este rango.', style: TextStyle(color: Tokens.muted));
    }
    return Column(
      children: [
        for (final record in records) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Tokens.slate200),
              borderRadius: BorderRadius.circular(Tokens.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    if (record.recordedAt != null) isoDate(record.recordedAt!),
                    if (record.isCorrection) 'Corrección',
                  ].join(' · '),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Tokens.slate900),
                ),
                const SizedBox(height: 2),
                Text(vitalMetrics(record), style: const TextStyle(color: Tokens.slate600, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Event log lines: what changed and when. No actor is shown.
class EventList extends StatelessWidget {
  const EventList({super.key, required this.events});

  final List<HistoryEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Text('Todavía no hay movimientos en este rango.', style: TextStyle(color: Tokens.muted));
    }
    return Column(
      children: [
        for (final event in events) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Tokens.slate200),
              borderRadius: BorderRadius.circular(Tokens.radiusSm),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${eventEntity(event.entity)} ${eventAction(event.action)}',
                    style: const TextStyle(color: Tokens.slate900),
                  ),
                ),
                Text(isoDate(event.at), style: const TextStyle(color: Tokens.muted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}
