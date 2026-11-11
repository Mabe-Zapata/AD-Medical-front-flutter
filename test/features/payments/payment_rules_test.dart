import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';
import 'package:medicalbooking_portal/features/payments/domain/policies/payment_failure.dart';

AppError _bad(String message) => AppError(ErrorKind.validation, message, status: 400);

void main() {
  group('paymentFailureMessage', () {
    test('translates the reason of a decline', () {
      expect(paymentFailureMessage(_bad('Payment declined: Your card has insufficient funds.')), contains('no tiene fondos suficientes'));
      expect(paymentFailureMessage(_bad('Payment declined: Your card has expired.')), contains('está vencida'));
      expect(paymentFailureMessage(_bad('Payment declined: incorrect CVC')), contains('código de seguridad'));
      expect(paymentFailureMessage(_bad('Payment declined: Your card was declined.')), contains('el banco rechazó la tarjeta'));
    });

    test('3D Secure wins over the generic decline, because it arrives as a decline', () {
      final message = paymentFailureMessage(_bad('Payment declined: Your card requires 3D Secure authentication.'));

      expect(message, contains('3D Secure'));
      expect(message, isNot(contains('rechazado')));
    });

    test('a decline with no known reason is still a decline', () {
      expect(paymentFailureMessage(_bad('Payment declined: something new')), 'Tu pago fue rechazado. Prueba con otra tarjeta.');
    });

    test('no saved card, any other 400, and the other statuses', () {
      expect(paymentFailureMessage(_bad('No tienes una tarjeta guardada')), contains('Paga con una tarjeta nueva'));
      expect(paymentFailureMessage(_bad('Invalid fields')), contains('Revisa los datos'));
      expect(paymentFailureMessage(const AppError(ErrorKind.forbidden, 'x', status: 403)), contains('permiso'));
      expect(paymentFailureMessage(const AppError(ErrorKind.conflict, 'x', status: 409)), contains('ya no está disponible'));
      expect(paymentFailureMessage(const AppError(ErrorKind.unavailable, 'x', status: 503)), contains('problema del servidor'));
      expect(paymentFailureMessage(const AppError(ErrorKind.network, 'x')), contains('conectar con el servidor'));
    });

    test('never shows the backend text', () {
      expect(paymentFailureMessage(_bad('Payment declined: secret internal detail xyz')), isNot(contains('xyz')));
    });
  });

  group('paymentFailureIsTheCard', () {
    test('offers another card for declines, 3D Secure and a missing card, not for the rest', () {
      expect(paymentFailureIsTheCard(_bad('Payment declined: Your card was declined.')), isTrue);
      expect(paymentFailureIsTheCard(_bad('3D Secure')), isTrue);
      expect(paymentFailureIsTheCard(_bad('No tienes una tarjeta guardada')), isTrue);
      expect(paymentFailureIsTheCard(_bad('Invalid fields')), isFalse);
      expect(paymentFailureIsTheCard(const AppError(ErrorKind.unavailable, 'x', status: 503)), isFalse);
    });
  });

  group('SavedCard', () {
    const card = SavedCard(id: 'pm_1', brand: 'VISA', last4: '4242', expMonth: 9, expYear: 2028);

    test('is valid through the last day of its expiry month', () {
      expect(card.isExpired(DateTime(2028, 9, 30, 23, 59)), isFalse);
      expect(card.isExpired(DateTime(2028, 10, 1)), isTrue);
    });

    test('formats the expiry as MM/YY', () => expect(card.expiry, '09/28'));

    test('an unknown expiry is never treated as expired', () {
      const unknown = SavedCard(id: 'pm_2', brand: 'VISA', last4: '4242');

      expect(unknown.isExpired(DateTime(2099)), isFalse);
      expect(unknown.expiry, '--/--');
    });
  });
}
