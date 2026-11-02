import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/status_chip.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/panel.dart';

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

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onViewResults});

  final LabOrder order;
  final VoidCallback onViewResults;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _orderStatus(order.status);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Orden ${order.id}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Tokens.slate900)),
                  const SizedBox(height: 2),
                  Text(
                    '${dayLabel(branchTime(order.orderedAt))} · ${order.doctorName}',
                    style: const TextStyle(color: Tokens.muted, fontSize: 12),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  StatusChip(label, color),
                  if (order.priority == OrderPriority.urgent) const StatusChip('Urgente', Tokens.danger),
                ],
              ),
            ],
          ),
          if (order.notes != null) ...[
            const SizedBox(height: 8),
            Text(order.notes!, style: const TextStyle(color: Tokens.slate600, fontSize: 13)),
          ],
          const Divider(height: 28),
          for (final detail in order.details)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(detail.testName, style: const TextStyle(fontWeight: FontWeight.w600, color: Tokens.slate700)),
                  ),
                  StatusChip(_detailStatus(detail.status).$1, _detailStatus(detail.status).$2),
                ],
              ),
            ),
          const SizedBox(height: 6),
          FilledButton(
            onPressed: order.hasValidatedResults ? onViewResults : null,
            child: Text(order.hasValidatedResults ? 'Ver resultados' : 'Resultados aún no disponibles'),
          ),
        ],
      ),
    );
  }
}
