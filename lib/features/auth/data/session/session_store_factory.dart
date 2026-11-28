// The browser build keeps the session in sessionStorage; every other target keeps it in memory.
export 'memory_session_store.dart' if (dart.library.js_interop) 'web_session_store.dart';
