import 'package:web/web.dart' as web;

/// Same tab, so the browser's back button returns to the portal.
void openExternalPage(Uri uri) => web.window.location.assign(uri.toString());
