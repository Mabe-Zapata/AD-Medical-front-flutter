// The browser build mounts Stripe's card form to save a card; other targets (tests, the VM) say it is unavailable.
export 'stripe_card_setup_stub.dart' if (dart.library.js_interop) 'stripe_card_setup_web.dart';
