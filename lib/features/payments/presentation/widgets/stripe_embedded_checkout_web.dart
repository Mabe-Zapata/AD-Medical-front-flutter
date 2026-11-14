import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_start.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/payment_source.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/info_banner.dart';
import 'package:web/web.dart' as web;

/// Stripe.js is always loaded from Stripe's own origin, as Stripe requires; it is never bundled.
const _stripeScript = 'https://js.stripe.com/v3/';

@JS('Stripe')
external _Stripe _stripe(String publishableKey);

extension type _Stripe._(JSObject _) implements JSObject {
  external JSPromise<_CheckoutPage> createEmbeddedCheckoutPage(_Options options);
}

extension type _Options._(JSObject _) implements JSObject {
  external factory _Options({JSFunction fetchClientSecret});
}

extension type _CheckoutPage._(JSObject _) implements JSObject {
  external void mount(web.Element target);
  external void destroy();
}

Future<void> _loadStripeJs() async {
  if (globalContext.has('Stripe')) return;
  final script = web.document.createElement('script') as web.HTMLScriptElement
    ..src = _stripeScript
    ..async = true;
  final loaded = web.EventStreamProviders.loadEvent.forElement(script).first;
  final failed = web.EventStreamProviders.errorEvent.forElement(script).first.then<void>((_) => throw StateError('Stripe.js did not load'));
  web.document.head!.append(script);
  await Future.any<Object?>([loaded, failed]);
}

/// Stripe's own payment page, drawn inside the portal. The card is typed into Stripe's frame, so Medilo never
/// sees it, and Stripe sends the browser to the backend's `return_url` (`/pago/retorno`) when it is done. That
/// return never proves the payment: only the signed webhook does. Because Stripe collects everything itself,
/// [onSubmit] and the saved card are not used here.
Widget stripeEmbeddedCheckout(
  BuildContext context, {
  required Embedded checkout,
  required String? amountLabel,
  required SavedCard? savedCard,
  required bool busy,
  required String? error,
  required bool errorIsTheCard,
  required void Function(PaymentSource source) onSubmit,
}) => _StripeCheckout(key: ValueKey(checkout.clientSecret), checkout: checkout);

class _StripeCheckout extends StatefulWidget {
  const _StripeCheckout({super.key, required this.checkout});

  final Embedded checkout;

  @override
  State<_StripeCheckout> createState() => _StripeCheckoutState();
}

class _StripeCheckoutState extends State<_StripeCheckout> {
  static var _next = 0;

  late final String _viewType = 'stripe-embedded-checkout-${_next++}';
  late final web.HTMLDivElement _host = (web.document.createElement('div') as web.HTMLDivElement)
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.overflow = 'auto';
  _CheckoutPage? _page;
  bool _failed = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) => _host);
    unawaited(_mount());
  }

  Future<void> _mount() async {
    try {
      await _loadStripeJs();
      final secret = widget.checkout.clientSecret;
      final page = await _stripe(widget.checkout.publishableKey)
          .createEmbeddedCheckoutPage(_Options(fetchClientSecret: (() => Future.value(secret.toJS).toJS).toJS))
          .toDart;
      if (_disposed) {
        page.destroy();
        return;
      }
      // The platform view attaches the host a frame after the widget builds; Stripe needs it in the document.
      for (var i = 0; i < 50 && !_host.isConnected && !_disposed; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (_disposed) {
        page.destroy();
        return;
      }
      _page = page..mount(_host);
    } on Object catch (error) {
      web.console.error('Stripe embedded checkout failed: $error'.toJS);
      if (!_disposed && mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _page?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const InfoBanner(
        message:
            'No pudimos cargar el formulario de pago de Stripe, así que no se cobró nada. Revisa tu conexión e inténtalo de nuevo. Tu cita sigue reservada.',
        color: Tokens.warning,
        icon: Icons.cloud_off_outlined,
      );
    }
    return SizedBox(height: 640, child: HtmlElementView(viewType: _viewType));
  }
}
