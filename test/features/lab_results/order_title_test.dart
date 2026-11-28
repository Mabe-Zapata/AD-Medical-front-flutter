import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/presentation/widgets/result_format.dart';

LabOrder _order({DateTime? orderedAt}) => LabOrder(
  id: '9e7b57de-2161-4b5a-be23-5a027e978bb2',
  patientId: 'p',
  priority: OrderPriority.normal,
  status: OrderStatus.completed,
  details: const [],
  orderedAt: orderedAt,
);

void main() {
  test('an order is titled by its date and never by its technical id', () {
    final title = orderTitle(_order(orderedAt: DateTime.utc(2026, 11, 12, 18)));

    expect(title, startsWith('Orden del '));
    expect(title, contains('nov'));
    expect(title, isNot(contains('9e7b57de')));
  });

  test('without a date the title is generic, still without the id', () {
    expect(orderTitle(_order()), 'Orden de laboratorio');
  });
}
