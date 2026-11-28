// The browser build leaves for another page in the same tab; other targets do nothing.
export 'open_page_stub.dart' if (dart.library.js_interop) 'open_page_web.dart';
