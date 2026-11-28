import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';

/// Presentational: a calendar tile (weekday, day, month). [filled] is the big orange one for the next appointment.
class DateBlock extends StatelessWidget {
  const DateBlock(this.date, {super.key, this.filled = false});

  final DateTime date;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final small = filled ? Colors.white : Tokens.blueText;
    final big = filled ? Colors.white : Tokens.slate900;
    return Container(
      width: filled ? 84 : 56,
      padding: EdgeInsets.symmetric(vertical: filled ? 12 : 6),
      decoration: BoxDecoration(
        gradient: filled ? Tokens.brandGradient : null,
        color: filled ? null : Tokens.blueTint,
        borderRadius: BorderRadius.circular(filled ? 16 : 12),
        border: filled ? null : Border.all(color: Tokens.blueSoft),
        boxShadow: filled
            ? [BoxShadow(color: Tokens.orange.withValues(alpha: 0.28), blurRadius: 20, offset: const Offset(0, 10))]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            weekdayLabel(date).toUpperCase(),
            style: TextStyle(fontSize: filled ? 12 : 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: small),
          ),
          Text('${date.day}', style: TextStyle(fontSize: filled ? 36 : 22, fontWeight: FontWeight.w800, height: 1.05, color: big)),
          Text(
            monthLabel(date).toUpperCase(),
            style: TextStyle(fontSize: filled ? 12 : 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: small),
          ),
        ],
      ),
    );
  }
}
