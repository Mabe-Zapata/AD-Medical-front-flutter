import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';

/// What the patient reads when the results report cannot be opened.
///
/// The backend holds the report until the laboratory and the physician have reviewed it (409 with
/// LAB_REVIEW_PENDING or MEDICAL_REVIEW_PENDING). Those reasons are internal: the patient only learns
/// that the report is still under review. Every other failure keeps the shared wording.
String resultsReportFailureMessage(Object error) {
  if (error is AppError && (error.code == 'LAB_REVIEW_PENDING' || error.code == 'MEDICAL_REVIEW_PENDING')) {
    return 'Tu informe está en revisión. Vuelve a intentarlo más tarde.';
  }
  return describeError(error).message;
}
