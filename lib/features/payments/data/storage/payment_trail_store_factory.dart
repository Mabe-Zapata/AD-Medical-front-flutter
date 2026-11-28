// The browser build keeps the payment trails in sessionStorage; every other target keeps them in memory.
export 'payment_trail_store_memory.dart' if (dart.library.js_interop) 'payment_trail_store_web.dart';
