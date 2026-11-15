abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const register = '/registro';
  static const verify = '/verificar';
  static const book = '/book';
  static const portal = '/portal';
  static const pay = '/pagar';
  static const sessionExpired = '/sesion-expirada';
  static const paymentDone = '/pago/exito';
  static const paymentCancelled = '/pago/cancelado';

  /// Where the backend's embedded Stripe page sends the browser when it finishes (`return_url`).
  static const paymentReturn = '/pago/retorno';
  static const profile = '/perfil';
  static const changePassword = '/cuenta/contrasena';
}
