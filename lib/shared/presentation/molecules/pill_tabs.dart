import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

class PillTab {
  const PillTab(this.label, {this.count, required this.icon});

  final String label;

  /// Shown as a small badge; null for tabs without a count.
  final int? count;
  final IconData icon;
}

/// Presentational: the portal's sections as pills on a calm blue track. The selected one is white.
class PillTabs extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<PillTab> tabs;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Tokens.blueTint,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < tabs.length; i++)
          Semantics(
            button: true,
            selected: i == selected,
            label: tabs[i].label,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelected(i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: i == selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: i == selected
                      ? [
                          BoxShadow(
                            color: Tokens.blueDeep.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tabs[i].icon,
                      size: 18,
                      color: i == selected ? Tokens.orange : Tokens.blueText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tabs[i].label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: i == selected ? Tokens.orange : Tokens.blueText,
                      ),
                    ),
                    if (tabs[i].count != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Tokens.blueSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${tabs[i].count}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Tokens.blueDeep,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
