import 'package:medicalbooking_portal/core/domain/app_error.dart';

/// The late-cancellation rule as the patient reads it. The backend enforces the same numbers.
const lateCancelNoticeHours = 48;
const lateCancelLimit = 3;
const lateCancelWindowDays = 30;

/// The rule, stated once for both the cancel dialog and the booking screen.
const lateCancelRuleText =
    'Cancela con 48 horas o más de anticipación para recibir el reembolso. '
    'Si cancelas con menos de 48 horas, no hay reembolso. '
    'Tres cancelaciones de ese tipo en 30 días impiden agendar nuevas citas '
    'hasta que la más antigua salga de ese periodo.';

const lateCancellationBlockMessage =
    'No puedes agendar nuevas citas por ahora: tienes $lateCancelLimit cancelaciones con menos de '
    '$lateCancelNoticeHours horas de anticipación en los últimos $lateCancelWindowDays días. '
    'Podrás agendar cuando la más antigua salga de ese periodo.';

/// Whether a refused booking was refused for late cancellations (the backend's detail names them).
bool isLateCancellationBlock(AppError error) =>
    error.kind == ErrorKind.forbidden && error.message.contains('late cancellations');
