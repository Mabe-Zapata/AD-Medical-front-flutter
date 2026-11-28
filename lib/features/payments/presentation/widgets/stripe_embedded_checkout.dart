// The browser build mounts Stripe's own payment page; other targets (tests, the VM) say it is unavailable.
export 'stripe_embedded_checkout_stub.dart' if (dart.library.js_interop) 'stripe_embedded_checkout_web.dart';
