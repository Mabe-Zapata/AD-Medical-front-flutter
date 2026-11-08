import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

/// Four-segment password strength indicator. [level] goes from 0 (empty) to 4.
class StrengthBar extends StatelessWidget {
  const StrengthBar({super.key, required this.level});

  final int level;

  static const _labels = ['', 'Débil', 'Regular', 'Buena', 'Robusta'];

  @override
  Widget build(BuildContext context) {
    final color = level <= 1 ? Tokens.danger : (level == 2 ? Tokens.warning : Tokens.success);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < level ? color : Tokens.slate200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _labels[level],
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: level == 0 ? Colors.transparent : color),
        ),
      ],
    );
  }
}
