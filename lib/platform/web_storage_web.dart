import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// iOS Safari predates the standard display-mode query and reports installed
/// web apps through this non-standard flag instead. Undefined everywhere else.
@JS('navigator.standalone')
external JSBoolean? get _iosStandalone;

/// True when the page is running as an installed home-screen app rather than
/// inside a normal browser tab. This matters a lot on iOS: Safari wipes a
/// site's storage after 7 days without interaction, but home-screen web apps
/// are exempt — so being installed is the difference between keeping the
/// user's ledger and losing it.
Future<bool> isInstalledAsApp() async {
  if (web.window.matchMedia('(display-mode: standalone)').matches) return true;
  return _iosStandalone?.toDart ?? false;
}

/// Asks the browser to exempt this site's storage from routine eviction.
/// Usually granted without a prompt once the app is installed.
Future<bool> requestPersistentStorage() async {
  try {
    final persisted = await web.window.navigator.storage.persist().toDart;
    return persisted.toDart;
  } catch (_) {
    return false;
  }
}
