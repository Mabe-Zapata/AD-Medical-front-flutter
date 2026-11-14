import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/payments/domain/policies/refund_failure.dart';

AppError _conflict(String code) => AppError(ErrorKind.conflict, code, status: 409);

void main() {
  test('every rule the backend names has its own plain Spanish text, and none shows the code', () {
    const codes = [
      'PAGO_NO_CONFIRMADO',
      'CITA_NO_CANCELADA',
      'CONSULTA_ATENDIDA',
      'CANCELACION_TARDIA',
      'REEMBOLSO_EXISTENTE',
      'FUERA_DE_VENTANA',
      'DEMASIADAS_SOLICITUDES',
      'MOTIVO_INVALIDO',
      'SIN_PAYMENT_INTENT',
    ];
    final texts = {for (final code in codes) code: refundFailureMessage(_conflict(code))};
    expect(texts.values.toSet().length, codes.length);
    for (final entry in texts.entries) {
      expect(entry.value, isNot(contains(entry.key)));
    }
  });

  test('a provider error says the refund was not registered', () {
    expect(refundFailureMessage(const AppError(ErrorKind.unavailable, 'x', status: 502)), contains('no se registró'));
  });

  test('a network failure asks to check the connection', () {
    expect(refundFailureMessage(const AppError(ErrorKind.network, 'x')), contains('conexión'));
  });
}
