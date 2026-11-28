import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/lab_results/presentation/report_failure_message.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';

void main() {
  test('a report held for the laboratory review says it is still being reviewed', () {
    final message = resultsReportFailureMessage(
      const AppError(ErrorKind.conflict, 'Read the interpretation', status: 409, code: 'LAB_REVIEW_PENDING'),
    );

    expect(message, contains('revisi'));
    expect(message, isNot(contains('Read the interpretation')));
  });

  test('a report held for the physician review says it is still being reviewed', () {
    final message = resultsReportFailureMessage(
      const AppError(ErrorKind.conflict, 'The physician must review', status: 409, code: 'MEDICAL_REVIEW_PENDING'),
    );

    expect(message, contains('revisi'));
    expect(message, isNot(contains('physician')));
  });

  test('any other failure keeps the generic wording', () {
    const error = AppError(ErrorKind.network, 'socket closed');

    expect(resultsReportFailureMessage(error), describeError(error).message);
  });
}
