import 'package:web/web.dart' as web;

/// Replaces the address the payment provider returned to (`/pago/exito?...`) with the landing address, so a reload
/// does not show the payment result again. The result was already read when the app opened.
void clearReturnAddress() => web.window.history.replaceState(null, '', '/');
