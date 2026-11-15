import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/card_setup.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/info_banner.dart';
import 'package:web/web.dart' as web;

/// Stripe.js is always loaded from Stripe's own origin, as Stripe requires; it is never bundled.
const _stripeScript = 'https://js.stripe.com/v3/';

@JS('Stripe')
external _Stripe _stripe(String publishableKey);

extension type _Stripe._(JSObject _) implements JSObject {
  external _Elements elements(JSObject options);
  external JSPromise<JSObject?> confirmSetup(JSObject options);
}

extension type _Elements._(JSObject _) implements JSObject {
  external _Element create(JSString type);
}

extension type _Element._(JSObject _) implements JSObject {
  external void mount(web.Element target);
}

Future<void> _loadStripeJs() async {
  if (globalContext.has('Stripe')) return;
  final script = web.document.createElement('script') as web.HTMLScriptElement
    ..src = _stripeScript
    ..async = true;
  final loaded = web.EventStreamProviders.loadEvent.forElement(script).first;
  final failed = web.EventStreamProviders.errorEvent
      .forElement(script)
      .first
      .then<void>((_) => throw StateError('Stripe.js did not load'));
  web.document.head!.append(script);
  await Future.any<Object?>([loaded, failed]);
}

/// Stripe's card form in the browser, to save a card without paying. The card is saved as reusable
/// (`allow_redisplay: always`) only when [consented] is true: the patient ticked the box that says so.
Widget stripeCardSetup(
  BuildContext context, {
  required CardSetup setup,
  required bool consented,
  required VoidCallback onSaved,
}) => _StripeCardSetup(
  key: ValueKey(setup.clientSecret),
  setup: setup,
  consented: consented,
  onSaved: onSaved,
);

class _StripeCardSetup extends StatefulWidget {
  const _StripeCardSetup({super.key, required this.setup, required this.consented, required this.onSaved});

  final CardSetup setup;
  final bool consented;
  final VoidCallback onSaved;

  @override
  State<_StripeCardSetup> createState() => _StripeCardSetupState();
}

class _StripeCardSetupState extends State<_StripeCardSetup> {
  static var _next = 0;

  late final String _viewType = 'stripe-card-setup-${_next++}';
  late final web.HTMLDivElement _host = (web.document.createElement('div') as web.HTMLDivElement)
    ..style.width = '100%';
  _Stripe? _client;
  JSObject? _elements;
  bool _ready = false;
  bool _failed = false;
  bool _busy = false;
  String? _error;
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
      final client = _stripe(widget.setup.publishableKey);
      final options = JSObject()
        ..setProperty('clientSecret'.toJS, widget.setup.clientSecret.toJS)
        ..setProperty('locale'.toJS, 'es'.toJS);
      final elements = client.elements(options);
      // The platform view attaches the host a frame after the widget builds; Stripe needs it in the document.
      for (var i = 0; i < 50 && !_host.isConnected && !_disposed; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (_disposed) return;
      elements.create('payment'.toJS).mount(_host);
      _client = client;
      _elements = elements;
      if (mounted) setState(() => _ready = true);
    } on Object catch (error) {
      web.console.error('Stripe card setup failed: $error'.toJS);
      if (!_disposed && mounted) setState(() => _failed = true);
    }
  }

  Future<void> _save() async {
    final client = _client;
    final elements = _elements;
    if (client == null || elements == null || !widget.consented) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final paymentMethodData = JSObject()..setProperty('allow_redisplay'.toJS, 'always'.toJS);
      final confirmParams = JSObject()
        ..setProperty('return_url'.toJS, web.window.location.href.toJS)
        ..setProperty('payment_method_data'.toJS, paymentMethodData);
      final options = JSObject()
        ..setProperty('elements'.toJS, elements)
        ..setProperty('confirmParams'.toJS, confirmParams)
        ..setProperty('redirect'.toJS, 'if_required'.toJS);
      final result = await client.confirmSetup(options).toDart;
      final failure = result?.getProperty<JSObject?>('error'.toJS);
      if (failure != null) {
        if (mounted) setState(() => _error = 'No pudimos guardar la tarjeta. Revísala e intenta de nuevo.');
        return;
      }
      if (!_disposed) widget.onSaved();
    } on Object catch (error) {
      web.console.error('Stripe card setup confirm failed: $error'.toJS);
      if (mounted) setState(() => _error = 'No pudimos guardar la tarjeta. Intenta de nuevo en unos minutos.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const InfoBanner(
        message: 'No pudimos cargar el formulario de Stripe, así que no se guardó nada. Revisa tu conexión e inténtalo de nuevo.',
        color: Tokens.warning,
        icon: Icons.cloud_off_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 260, child: HtmlElementView(viewType: _viewType)),
        if (_error != null) ...[
          const SizedBox(height: 12),
          InfoBanner(message: _error!, color: Tokens.danger, icon: Icons.error_outline),
        ],
        const SizedBox(height: 16),
        GradientButton(
          label: _busy ? 'Guardando…' : 'Guardar tarjeta',
          onPressed: !_ready || !widget.consented || _busy ? null : _save,
        ),
      ],
    );
  }
}
