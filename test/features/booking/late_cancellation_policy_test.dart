import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/booking/domain/policies/late_cancellation_policy.dart';

void main() {
  test('a refusal for late cancellations is recognised', () {
    const error = AppError(
      ErrorKind.forbidden,
      'Too many late cancellations in the last 30 days; booking is blocked until older ones expire',
    );
    expect(isLateCancellationBlock(error), isTrue);
  });

  test('other forbidden booking errors are not mistaken for it', () {
    const error = AppError(ErrorKind.forbidden, 'A patient profile is required to book appointments');
    expect(isLateCancellationBlock(error), isFalse);
  });

  test('the same detail under another kind is not the block', () {
    const error = AppError(ErrorKind.conflict, 'late cancellations');
    expect(isLateCancellationBlock(error), isFalse);
  });
}
