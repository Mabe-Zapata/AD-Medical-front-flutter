import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/date_block.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/presentation/widgets/result_format.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/status_chip.dart';

(String, Color) _orderStatus(OrderStatus s) => switch (s) {
  OrderStatus.requested => ('Solicitada', Tokens.info),
  OrderStatus.inProgress => ('En proceso', Tokens.warning),
  OrderStatus.completed => ('Completada', Tokens.success),
  OrderStatus.cancelled => ('Cancelada', Tokens.danger),
};

(String, Color) _detailStatus(DetailStatus s) => switch (s) {
  DetailStatus.pending => ('Pendiente', Tokens.muted),
  DetailStatus.inProgress => ('En proceso', Tokens.warning),
  DetailStatus.completed => ('Completado', Tokens.success),
  DetailStatus.cancelled => ('Cancelado', Tokens.danger),
};

/// Presentational: one lab order. The header has its date tile, title, state and the button to see the results;
/// below, each test with its own state.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onViewResults});

  final LabOrder order;
  final VoidCallback onViewResults;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _orderStatus(order.status);
    final orderedAt = order.orderedAt;
    final button = FilledButton(
      onPressed: order.hasValidatedResults ? onViewResults : null,
      child: Text(order.hasValidatedResults ? 'Ver resultados' : 'Resultados aún no disponibles'),
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Tokens.slate200),
        boxShadow: [BoxShadow(color: Tokens.blueDeep.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Wrap(
              spacing: 18,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (orderedAt != null) DateBlock(branchTime(orderedAt)),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 200, maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(orderTitle(order), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Tokens.slate900)),
                      if (order.notes != null || order.doctorName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          [?order.notes, if (order.doctorName != null) 'Solicitada por ${order.doctorName}'].join(' · '),
                          style: const TextStyle(color: Tokens.muted, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                StatusChip(label, color),
                if (order.priority == OrderPriority.urgent) const StatusChip('Urgente', Tokens.danger),
                button,
              ],
            ),
          ),
          const Divider(height: 1, color: Tokens.slate100),
          for (var i = 0; i < order.details.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: Tokens.blueSoft, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.science_outlined, size: 18, color: Tokens.blueDeep),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(order.details[i].testName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Tokens.slate700)),
                  ),
                  StatusChip(_detailStatus(order.details[i].status).$1, _detailStatus(order.details[i].status).$2),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
