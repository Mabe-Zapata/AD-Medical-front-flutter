import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

/// Presentational: three counts at a glance (to pay, confirmed, results ready). Each one is a shortcut to the list it counts.
class SummaryTiles extends StatelessWidget {
  const SummaryTiles({
    super.key,
    required this.toPay,
    required this.confirmed,
    required this.resultsReady,
    required this.onToPay,
    required this.onConfirmed,
    required this.onResults,
  });

  final int toPay;
  final int confirmed;
  final int resultsReady;
  final VoidCallback onToPay;
  final VoidCallback onConfirmed;
  final VoidCallback onResults;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 480;
      final tiles = [
        _Tile(count: toPay, label: 'Por pagar', icon: Icons.schedule, tint: const Color(0xFFFEF3C7), ink: const Color(0xFF92400E), compact: compact, onTap: onToPay),
        _Tile(count: confirmed, label: 'Confirmadas', icon: Icons.check_circle_outline, tint: const Color(0xFFDCFCE7), ink: const Color(0xFF166534), compact: compact, onTap: onConfirmed),
        _Tile(count: resultsReady, label: 'Resultados listos', icon: Icons.science_outlined, tint: Tokens.blueSoft, ink: Tokens.blueDeep, compact: compact, onTap: onResults),
      ];
      return Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            Expanded(child: tiles[i]),
          ],
        ],
      );
    },
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.count, required this.label, required this.icon, required this.tint, required this.ink, required this.compact, required this.onTap});

  final int count;
  final String label;
  final IconData icon;
  final Color tint;
  final Color ink;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Tokens.slate200),
        boxShadow: [BoxShadow(color: Tokens.blueDeep.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          if (!compact) ...[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: ink, size: 22),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1, color: Tokens.slate900)),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 13, color: Tokens.slate600)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
