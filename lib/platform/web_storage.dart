// Reports how durable this platform's storage is. Native app storage is
// private and permanent; browser storage can be evicted, so the web build
// needs to warn the user and ask the browser to hold on to it.
export 'web_storage_io.dart' if (dart.library.js_interop) 'web_storage_web.dart';
